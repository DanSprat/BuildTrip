import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme_scope.dart';
import 'theme/build_trip_app_theme.dart';

/// Без «резинового» растягивания контента при сильном overscroll (Material 3).
class BuildTripScrollBehavior extends MaterialScrollBehavior {
  const BuildTripScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

const String _kThemeModePrefKey = 'build_trip_theme_mode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuildTripApp());
}

class BuildTripApp extends StatefulWidget {
  const BuildTripApp({super.key});

  @override
  State<BuildTripApp> createState() => _BuildTripAppState();
}

class _BuildTripAppState extends State<BuildTripApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kThemeModePrefKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = _themeModeFromStorage(raw);
      _prefsLoaded = true;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModePrefKey, _themeModeToStorage(mode));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildTrip',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const BuildTripScrollBehavior(),
      theme: BuildTripAppThemes.light(),
      darkTheme: BuildTripAppThemes.dark(),
      themeMode: _prefsLoaded ? _themeMode : ThemeMode.system,
      builder: (context, child) {
        return AppThemeScope(
          themeMode: _themeMode,
          setThemeMode: _setThemeMode,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}

ThemeMode _themeModeFromStorage(String? raw) {
  return switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

String _themeModeToStorage(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
