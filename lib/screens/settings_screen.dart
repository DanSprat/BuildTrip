import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:map_launcher/map_launcher.dart';

import '../data/maps_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme_scope.dart';
import '../widgets/build_trip_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _mapsLoading = true;
  List<AvailableMap> _maps = const [];
  MapType? _preferredMapType;

  @override
  void initState() {
    super.initState();
    _loadMapsSettings();
  }

  Future<void> _loadMapsSettings() async {
    final preferred = await MapsPreferences.loadPreferredMapType();
    List<AvailableMap> installedMaps = const [];

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        installedMaps = await MapLauncher.installedMaps;
        installedMaps.sort((a, b) => a.mapName.compareTo(b.mapName));
      } catch (_) {
        installedMaps = const [];
      }
    }

    if (!mounted) {
      return;
    }

    final hasPreferredInstalled = preferred != null &&
        installedMaps.any((m) => m.mapType.name == preferred.name);

    setState(() {
      _maps = installedMaps;
      _preferredMapType = hasPreferredInstalled ? preferred : null;
      _mapsLoading = false;
    });

    if (preferred != null && !hasPreferredInstalled) {
      await MapsPreferences.clearPreferredMapType();
    }
  }

  Future<void> _setPreferredMapType(MapType? value) async {
    setState(() => _preferredMapType = value);
    if (value == null) {
      await MapsPreferences.clearPreferredMapType();
      return;
    }
    await MapsPreferences.savePreferredMapType(value);
  }

  Future<void> _pickThemeMode() async {
    final scope = AppThemeScope.of(context);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        final current = scope.themeMode;
        final l10n = ctx.l10n;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: Text(l10n.t('settingsThemeLight')),
                trailing: current == ThemeMode.light
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(ctx).pop(ThemeMode.light),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text(l10n.t('settingsThemeDark')),
                trailing: current == ThemeMode.dark
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(ctx).pop(ThemeMode.dark),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_auto_outlined),
                title: Text(l10n.t('settingsThemeSystem')),
                trailing: current == ThemeMode.system
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(ctx).pop(ThemeMode.system),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      scope.setThemeMode(selected);
    }
  }

  Future<void> _pickLanguage() async {
    final scope = AppThemeScope.of(context);
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        final current = scope.language;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 4),
              for (final option in AppLanguage.values)
                ListTile(
                  leading: Text(
                    _languageFlag(option),
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(_languageLabel(ctx, option)),
                  trailing: current == option
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(option),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != scope.language) {
      scope.setLanguage(selected);
    }
  }

  Future<void> _pickPreferredMap() async {
    if (_mapsLoading || _maps.isEmpty) {
      return;
    }

    final selected = await showModalBottomSheet<MapType?>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.72,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const SizedBox(height: 4),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: Text(ctx.l10n.t('settingsAlwaysAsk')),
                  trailing: _preferredMapType == null
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
                for (final map in _maps)
                  ListTile(
                    leading: SvgPicture.asset(
                      map.icon,
                      width: 22,
                      height: 22,
                    ),
                    title: Text(map.mapName),
                    trailing: _preferredMapType == map.mapType
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(map.mapType),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }
    if (selected != _preferredMapType) {
      await _setPreferredMapType(selected);
    }
  }

  String _themeLabel(ThemeMode mode) {
    final l10n = context.l10n;
    return switch (mode) {
      ThemeMode.light => l10n.t('settingsThemeLight'),
      ThemeMode.dark => l10n.t('settingsThemeDark'),
      ThemeMode.system => l10n.t('settingsThemeSystem'),
    };
  }

  String _preferredMapLabel() {
    if (_preferredMapType == null) {
      return context.l10n.t('settingsAlwaysAsk');
    }
    for (final map in _maps) {
      if (map.mapType == _preferredMapType) {
        return map.mapName;
      }
    }
    return context.l10n.t('settingsAlwaysAsk');
  }

  String _languageLabel(BuildContext context, AppLanguage language) {
    final l10n = context.l10n;
    return switch (language) {
      AppLanguage.system => l10n.t('settingsLanguageSystem'),
      AppLanguage.ru => 'Русский',
      AppLanguage.en => 'English',
      AppLanguage.fr => 'Français',
      AppLanguage.es => 'Español',
      AppLanguage.ja => '日本語',
    };
  }

  String _languageFlag(AppLanguage language) {
    return switch (language) {
      AppLanguage.system => '🌐',
      AppLanguage.ru => '🇷🇺',
      AppLanguage.en => '🇬🇧',
      AppLanguage.fr => '🇫🇷',
      AppLanguage.es => '🇪🇸',
      AppLanguage.ja => '🇯🇵',
    };
  }

  AvailableMap? _preferredMap() {
    if (_preferredMapType == null) {
      return null;
    }
    for (final map in _maps) {
      if (map.mapType == _preferredMapType) {
        return map;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final scope = AppThemeScope.of(context);
    final selectedMap = _preferredMap();

    return Scaffold(
      appBar: BuildTripAppBar(
        titleText: l10n.t('tabSettings'),
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.t('settingsAppearance'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.t('settingsTheme')),
              subtitle: Text(_themeLabel(scope.themeMode)),
              trailing: const Icon(Icons.keyboard_arrow_down_rounded),
              onTap: _pickThemeMode,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.t('settingsLanguage'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ListTile(
              leading: Text(
                _languageFlag(scope.language),
                style: const TextStyle(fontSize: 20),
              ),
              title: Text(l10n.t('settingsLanguage')),
              subtitle: Text(_languageLabel(context, scope.language)),
              trailing: const Icon(Icons.keyboard_arrow_down_rounded),
              onTap: _pickLanguage,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.t('settingsMaps'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          if (_mapsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_maps.isEmpty)
            Text(
              l10n.t('settingsNoMapApps'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ListTile(
                leading: selectedMap == null
                    ? const Icon(Icons.help_outline_rounded)
                    : SvgPicture.asset(
                        selectedMap.icon,
                        width: 22,
                        height: 22,
                      ),
                title: Text(l10n.t('settingsMapDefault')),
                subtitle: Text(_preferredMapLabel()),
                trailing: const Icon(Icons.keyboard_arrow_down_rounded),
                onTap: _pickPreferredMap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
