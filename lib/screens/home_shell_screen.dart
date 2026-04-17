import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'trips_screen.dart';

/// Корневой экран после заставки: вкладки и [NavigationBar] снизу.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TripsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.luggage_outlined),
            selectedIcon: const Icon(Icons.luggage_rounded),
            label: l10n.t('tabTrips'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.t('tabSettings'),
          ),
        ],
      ),
    );
  }
}
