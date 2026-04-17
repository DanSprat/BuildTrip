import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/maps_preferences.dart';
import '../l10n/app_localizations.dart';

/// Открывает карты: на Android — системный выбор среди приложений с [geo:],
/// на iOS — список установленных картографических приложений (через [MapLauncher]).
Future<void> showOpenInMapsSheet(
  BuildContext context, {
  required String query,
}) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return;
  }

  final encoded = Uri.encodeComponent(trimmed);

  if (kIsWeb) {
    await _launchGoogleMapsSearch(context, encoded);
    return;
  }

  final maps = await _getInstalledMaps();
  final preferredMap = await _getPreferredMap(maps);
  if (!context.mounted) {
    return;
  }

  if (preferredMap != null) {
    final loc = await _resolveLocationWithLoading(context, trimmed);
    if (!context.mounted) {
      return;
    }
    if (loc == null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _openAndroidMapChooser(context, encoded);
      } else {
        await _showCoordinatesUnavailableSheet(context, encoded);
      }
      return;
    }
    await _openMapWithMarker(context, preferredMap, loc, trimmed);
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    await _openAndroidMapChooser(context, encoded);
    return;
  }

  await _openInstalledMapsSheet(context, trimmed, encoded, maps: maps);
}

Future<void> _launchGoogleMapsSearch(
    BuildContext context, String encoded) async {
  final ok = await launchUrl(
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('mapsOpenFailed'))),
    );
  }
}

Future<void> _openAndroidMapChooser(
  BuildContext context,
  String encoded,
) async {
  final openInMapsLabel = context.l10n.t('openInMaps');
  final noAppsText = context.l10n.t('mapsNoApps');
  final chooserFailedText = context.l10n.t('mapsChooserFailed');
  final intent = AndroidIntent(
    action: 'android.intent.action.VIEW',
    data: 'geo:0,0?q=$encoded',
  );
  try {
    final can = await intent.canResolveActivity();
    if (can == false) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(noAppsText)),
        );
      }
      return;
    }
    await intent.launchChooser(openInMapsLabel);
  } on PlatformException catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(chooserFailedText)),
      );
    }
  }
}

Future<void> _openInstalledMapsSheet(
    BuildContext context, String trimmed, String encoded,
    {List<AvailableMap>? maps}) async {
  final installedMaps = maps ?? await _getInstalledMaps();
  if (!context.mounted) {
    return;
  }

  if (installedMaps.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('mapsNoAppsFallback'))),
      );
      await _launchGoogleMapsSearch(context, encoded);
    }
    return;
  }

  final loc = await _resolveLocationWithLoading(context, trimmed);

  if (!context.mounted) {
    return;
  }

  if (loc == null) {
    await _showCoordinatesUnavailableSheet(context, encoded);
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                context.l10n.t('openInMaps'),
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                context.l10n.t('mapsInstalledApps'),
                style: t.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.45,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final m in installedMaps)
                    ListTile(
                      leading: SvgPicture.asset(
                        m.icon,
                        width: 24,
                        height: 24,
                      ),
                      title: Text(m.mapName),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _openMapWithMarker(context, m, loc, trimmed);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<List<AvailableMap>> _getInstalledMaps() async {
  try {
    final maps = await MapLauncher.installedMaps;
    maps.sort((a, b) => a.mapName.compareTo(b.mapName));
    return maps;
  } catch (_) {
    return [];
  }
}

Future<AvailableMap?> _getPreferredMap(List<AvailableMap> maps) async {
  final preferredType = await MapsPreferences.loadPreferredMapType();
  if (preferredType == null) {
    return null;
  }
  for (final map in maps) {
    if (map.mapType.name == preferredType.name) {
      return map;
    }
  }
  return null;
}

/// Таймаут геокодинга: дольше ждать обычно бессмысленно, но UX страдает.
const Duration _kGeocodeTimeout = Duration(seconds: 5);

Future<Location?> _resolveLocation(String address) async {
  try {
    final locations = await locationFromAddress(address).timeout(
      _kGeocodeTimeout,
    );
    if (locations.isEmpty) {
      return null;
    }
    return locations.first;
  } on TimeoutException {
    return null;
  } catch (_) {
    return null;
  }
}

/// Показывает индикатор сразу, чтобы не казалось, что кнопка «зависла» на секунды.
Future<Location?> _resolveLocationWithLoading(
  BuildContext context,
  String address,
) async {
  if (!context.mounted) {
    return null;
  }
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  context.l10n.t('mapsLoadingCoords'),
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  try {
    return await _resolveLocation(address);
  } finally {
    if (navigator.mounted) {
      navigator.pop();
    }
  }
}

Future<void> _openMapWithMarker(
  BuildContext context,
  AvailableMap map,
  Location loc,
  String title,
) async {
  try {
    await map.showMarker(
      coords: Coords(loc.latitude, loc.longitude),
      title: title,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('mapsOpenFailed'))),
      );
    }
  }
}

Future<void> _showCoordinatesUnavailableSheet(
  BuildContext context,
  String encoded,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.t('mapsNoCoordsTitle'),
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('mapsNoCoordsText'),
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _launchGoogleMapsSearch(context, encoded);
              },
              icon: const Icon(Icons.public_rounded),
              label: Text(context.l10n.t('mapsGoogleSearch')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final ok = await launchUrl(
                  Uri.parse('http://maps.apple.com/?q=$encoded'),
                  mode: LaunchMode.externalApplication,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.t('mapsOpenFailed'))),
                  );
                }
              },
              icon: const Icon(Icons.map_outlined),
              label: Text(context.l10n.t('mapsAppleSearch')),
            ),
          ],
        ),
      );
    },
  );
}
