import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Locale Provider - Manages app language state
class LocaleProvider extends ChangeNotifier {
  static const Locale defaultLocale = Locale('ta'); // Tamil as default

  Locale _currentLocale = defaultLocale;

  Locale get currentLocale => _currentLocale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language') ?? 'ta';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    await setLocale('ta');
  }
}
