import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService extends ChangeNotifier {
  AppSettingsService._();

  static final AppSettingsService instance =
      AppSettingsService._();

  static const _languageKey = 'app_language';
  static const _themeKey = 'app_theme';
  static const _chickProductIdKey = 'chick_product_id';

  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;
  String? _chickProductId;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  String? get chickProductId => _chickProductId;

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

    final savedChickProductId =
        preferences.getString(_chickProductIdKey);

    if (savedChickProductId == null ||
        savedChickProductId.trim().isEmpty) {
      _chickProductId = null;
    } else {
      _chickProductId = savedChickProductId.trim();
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

  Future<void> setChickProductId(
    String? productId,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final value = productId?.trim();

    if (value == null || value.isEmpty) {
      _chickProductId = null;

      await preferences.remove(
        _chickProductIdKey,
      );
    } else {
      _chickProductId = value;

      await preferences.setString(
        _chickProductIdKey,
        value,
      );
    }

    // No notifyListeners() here.
    // Choosing the chick product is an internal preference and does not
    // need to rebuild the whole app. Rebuilding here could interrupt the
    // first Queue -> Create Sale navigation.
  }
}
