import 'package:flutter/material.dart';

import '../theme/app_theme_scope.dart';
import '../widgets/build_trip_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scope = AppThemeScope.of(context);

    return Scaffold(
      appBar: const BuildTripAppBar(
        titleText: 'Настройки',
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Оформление',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 20),
                label: Text('Светлая'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 20),
                label: Text('Тёмная'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined, size: 20),
                label: Text('Система'),
              ),
            ],
            selected: {scope.themeMode},
            onSelectionChanged: (s) => scope.setThemeMode(s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 14),
          Text(
            '«Система» следует настройкам устройства.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}
