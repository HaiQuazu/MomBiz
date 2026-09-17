import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService extends ChangeNotifier {
  AppSettingsService._();

  static final AppSettingsService instance =
      AppSettingsService._();

  static const _languageKey = 'app_language';
  static const _themeKey = 'app_theme';

  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final preferences =
        await SharedPreferences.getInstance();

    final savedLanguage =
        preferences.getString(_languageKey);

    if (savedLanguage == 'km') {
      _locale = const Locale('km');
    } else {
      _locale = const Locale('en');
    }

    final savedTheme =
        preferences.getString(_themeKey);

    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;

      case 'dark':
        _themeMode = ThemeMode.dark;
        break;

      default:
        _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setLanguage(
    String languageCode,
  ) async {
    if (languageCode != 'en' &&
        languageCode != 'km') {
      return;
    }

    _locale = Locale(languageCode);

    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _languageKey,
      languageCode,
    );

    notifyListeners();
  }

  Future<void> setThemeMode(
    ThemeMode mode,
  ) async {
    _themeMode = mode;

    final preferences =
        await SharedPreferences.getInstance();

    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await preferences.setString(
      _themeKey,
      value,
    );

    notifyListeners();
  }
}
