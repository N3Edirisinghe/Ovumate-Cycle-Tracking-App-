import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  final SharedPreferences _prefs;
  Locale _currentLocale;

  LanguageProvider(this._prefs) : _currentLocale = Locale(_prefs.getString(_languageKey) ?? 'en') {
    if (_prefs.getString(_languageKey) == null) {
      _prefs.setString(_languageKey, 'en');
    }
  }

  Locale get currentLocale => _currentLocale;

  Future<void> setLocale(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      await _prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }

  static List<Map<String, String>> get supportedLanguages => [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'si', 'name': 'Sinhala', 'nativeName': 'සිංහල'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
  ];
}
