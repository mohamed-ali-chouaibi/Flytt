import 'package:flutter/material.dart';
class LightThemeColors {
  static const Color deepPurple = Color(0xFF2B1E4F);
  static const Color brightWhite = Color(0xFFFFFFFF);
  static const Color electricIndigo = Color(0xFF6C5CE7);
  static const Color tealBlue = Color(0xFF00CEC9);
  static const Color sunshineYellow = Color(0xFFFFE66D);
  static const Color lightGray = Color(0xFFF2F2F2);
  static const Color slateGray = Color(0xFF7A7A7A);
  static const Color darkCharcoal = Color(0xFF1D1D1D);
  static const Color mapBackground = Color(0xFFF5F5F7);
  static const Color mapRoadsMain = Color(0xFFD0D0D0);
  static const Color mapRoadsSecondary = Color(0xFFE5E5E5);
  static const Color mapWater = Color(0xFFD6F5F5);
  static const Color mapParks = Color(0xFFDFFFE2);
  static const Color mapBuildings = Color(0xFFFFFFFF);
  static const Color mapLabels = Color(0xFF4A4A4A);
}
ThemeData getLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: LightThemeColors.deepPurple,
    scaffoldBackgroundColor: LightThemeColors.brightWhite,
    appBarTheme: AppBarTheme(
      backgroundColor: LightThemeColors.brightWhite,
      foregroundColor: LightThemeColors.deepPurple,
      elevation: 0,
    ),
    colorScheme: ColorScheme.light(
      primary: LightThemeColors.deepPurple,
      secondary: LightThemeColors.electricIndigo,
      surface: LightThemeColors.brightWhite,
      background: LightThemeColors.lightGray,
      onPrimary: LightThemeColors.brightWhite,
      onSecondary: LightThemeColors.brightWhite,
      onSurface: LightThemeColors.deepPurple,
      onBackground: LightThemeColors.deepPurple,
    ),
    cardTheme: CardThemeData(
      color: LightThemeColors.brightWhite,
      elevation: 2,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: LightThemeColors.brightWhite,
      selectedItemColor: LightThemeColors.deepPurple,
      unselectedItemColor: LightThemeColors.slateGray,
    ),
  );
} 
