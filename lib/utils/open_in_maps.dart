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
    final loc = await _resolveLocation(trimmed);
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
      const SnackBar(content: Text('Не удалось открыть карты')),
    );
  }
}

Future<void> _openAndroidMapChooser(
  BuildContext context,
  String encoded,
) async {
  final intent = AndroidIntent(
    action: 'android.intent.action.VIEW',
    data: 'geo:0,0?q=$encoded',
  );
  try {
    final can = await intent.canResolveActivity();
    if (can == false) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет приложений, которые открывают адрес на карте'),
          ),
        );
      }
      return;
    }
    await intent.launchChooser('Открыть в картах');
  } on PlatformException catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть выбор приложений')),
      );
    }
  }
}

Future<void> _openInstalledMapsSheet(
    BuildContext context, String trimmed, String encoded,
    {List<AvailableMap>? maps}) async {
  final installedMaps = maps ?? await _getInstalledMaps();

  if (installedMaps.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Нет приложений карт — открываем поиск в браузере',
          ),
        ),
      );
      await _launchGoogleMapsSearch(context, encoded);
    }
    return;
  }

  final loc = await _resolveLocation(trimmed);

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
                'Открыть в картах',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Установленные приложения',
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

Future<Location?> _resolveLocation(String address) async {
  try {
    final locations = await locationFromAddress(address).timeout(
      const Duration(seconds: 12),
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
        const SnackBar(content: Text('Не удалось открыть приложение')),
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
              'Открыть в картах',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Не удалось определить координаты по этому адресу '
              '(проверьте сеть и написание). Можно открыть поиск в браузере.',
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
              label: const Text('Поиск в Google Картах'),
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
                    const SnackBar(content: Text('Не удалось открыть карты')),
                  );
                }
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('Поиск в Apple Картах (веб)'),
            ),
          ],
        ),
      );
    },
  );
}
