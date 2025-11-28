import 'package:flutter/material.dart';
class DarkThemeColors {
  static const Color primaryBackground = Color(0xFF121212);
  static const Color secondaryBackground = Color(0xFF1E1E1E);
  static const Color surfaceLayer = Color(0xFF2B2B2B);
  static const Color secondaryText = Color(0xFFBBBBBB);
  static const Color disabledMuted = Color(0xFF666666);
  static const Color softDivider = Color(0xFF2E2E2E);
  static const Color electricIndigo = Color(0xFF6C5CE7);
  static const Color tealBlue = Color(0xFF00CEC9);
  static const Color brightWhite = Color(0xFFFFFFFF);
  static const Color mapBackground = Color(0xFF1A1A1A);
  static const Color mapRoadsMain = Color(0xFF2C2C2C);
  static const Color mapRoadsSecondary = Color(0xFF3A3A3A);
  static const Color mapWater = Color(0xFF163D3D);
  static const Color mapParks = Color(0xFF1D3A1D);
  static const Color mapBuildings = Color(0xFF222222);
  static const Color mapLabels = Color(0xFFCCCCCC);
}
ThemeData getDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: DarkThemeColors.electricIndigo,
    scaffoldBackgroundColor: DarkThemeColors.primaryBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: DarkThemeColors.primaryBackground,
      foregroundColor: DarkThemeColors.brightWhite,
      elevation: 0,
    ),
    colorScheme: ColorScheme.dark(
      primary: DarkThemeColors.electricIndigo,
      secondary: DarkThemeColors.tealBlue,
      surface: DarkThemeColors.surfaceLayer,
      background: DarkThemeColors.primaryBackground,
      onPrimary: DarkThemeColors.brightWhite,
      onSecondary: DarkThemeColors.brightWhite,
      onSurface: DarkThemeColors.brightWhite,
      onBackground: DarkThemeColors.brightWhite,
    ),
    cardTheme: CardThemeData(
      color: DarkThemeColors.surfaceLayer,
      elevation: 2,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: DarkThemeColors.secondaryBackground,
      selectedItemColor: DarkThemeColors.electricIndigo,
      unselectedItemColor: DarkThemeColors.secondaryText,
    ),
  );
} 
