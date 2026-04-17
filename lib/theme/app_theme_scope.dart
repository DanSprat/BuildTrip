import 'package:flutter/material.dart';

enum AppLanguage {
  system,
  ru,
  en,
  fr,
  es,
  ja,
}

/// Доступ к [ThemeMode] и смене темы из любого экрана под [MaterialApp].
class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required this.language,
    required this.setLanguage,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> setThemeMode;
  final AppLanguage language;
  final ValueChanged<AppLanguage> setLanguage;

  static AppThemeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
  }

  static AppThemeScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AppThemeScope не найден выше по дереву');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) {
    return themeMode != oldWidget.themeMode || language != oldWidget.language;
  }
}
