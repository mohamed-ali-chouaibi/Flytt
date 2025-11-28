import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
class RydyColors {
  static const Color darkBg = Color(0xFF1A1A1A);
  static const Color cardBg = Color(0xFF2B2B2B);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color subText = Color(0xFFBBBBBB);
  static const Color dividerColor = Color(0xFF3A3A3A);
}
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;
  ThemeProvider() {
    _loadTheme();
  }
  bool get isDarkMode => _isDarkMode;
  ThemeData get theme => _isDarkMode ? getDarkTheme() : getLightTheme();
  dynamic get colors => _isDarkMode ? DarkThemeColors : LightThemeColors;
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }
} 
