import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final darkMode = prefs.getBool('dark_mode') ?? false;
      
      _isDarkMode = darkMode;
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
      
      debugPrint('🔵 Loaded theme preference: ${darkMode ? "Dark" : "Light"}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading theme preference: $e');
    }
  }

  Future<void> setDarkMode(bool isDark) async {
    try {
      _isDarkMode = isDark;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDark);
      
      debugPrint('🔵 Theme changed to: ${isDark ? "Dark" : "Light"}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}

