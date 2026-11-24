import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  static Future<LocaleController> load() async {
    final controller = LocaleController();
    final preferences = await SharedPreferences.getInstance();

    final savedLanguage = preferences.getString(_localeKey);

    if (savedLanguage == 'hi' || savedLanguage == 'en') {
      controller._locale = Locale(savedLanguage!);
    }

    return controller;
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'en' &&
        locale.languageCode != 'hi') {
      return;
    }

    if (_locale == locale) return;

    _locale = locale;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale.languageCode);

    notifyListeners();
  }
}