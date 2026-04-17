import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
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
const String _kLanguagePrefKey = 'build_trip_language';

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
  AppLanguage _language = AppLanguage.system;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeRaw = prefs.getString(_kThemeModePrefKey);
    final languageRaw = prefs.getString(_kLanguagePrefKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = _themeModeFromStorage(themeRaw);
      _language = _languageFromStorage(languageRaw);
      _prefsLoaded = true;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModePrefKey, _themeModeToStorage(mode));
  }

  Future<void> _setLanguage(AppLanguage language) async {
    setState(() => _language = language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguagePrefKey, _languageToStorage(language));
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocale = _localeForLanguage(_language);
    return MaterialApp(
      title: 'BuildTrip',
      debugShowCheckedModeBanner: false,
      locale: selectedLocale,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (selectedLocale != null) {
          return selectedLocale;
        }
        if (deviceLocale != null) {
          for (final locale in supportedLocales) {
            if (locale.languageCode == deviceLocale.languageCode) {
              return locale;
            }
          }
        }
        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      scrollBehavior: const BuildTripScrollBehavior(),
      theme: BuildTripAppThemes.light(),
      darkTheme: BuildTripAppThemes.dark(),
      themeMode: _prefsLoaded ? _themeMode : ThemeMode.system,
      builder: (context, child) {
        return AppThemeScope(
          themeMode: _themeMode,
          setThemeMode: _setThemeMode,
          language: _language,
          setLanguage: _setLanguage,
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

AppLanguage _languageFromStorage(String? raw) {
  return switch (raw) {
    'ru' => AppLanguage.ru,
    'en' => AppLanguage.en,
    'fr' => AppLanguage.fr,
    'es' => AppLanguage.es,
    'ja' => AppLanguage.ja,
    _ => AppLanguage.system,
  };
}

String _languageToStorage(AppLanguage language) {
  return switch (language) {
    AppLanguage.ru => 'ru',
    AppLanguage.en => 'en',
    AppLanguage.fr => 'fr',
    AppLanguage.es => 'es',
    AppLanguage.ja => 'ja',
    AppLanguage.system => 'system',
  };
}

Locale? _localeForLanguage(AppLanguage language) {
  return switch (language) {
    AppLanguage.system => null,
    AppLanguage.ru => const Locale('ru'),
    AppLanguage.en => const Locale('en'),
    AppLanguage.fr => const Locale('fr'),
    AppLanguage.es => const Locale('es'),
    AppLanguage.ja => const Locale('ja'),
  };
}
