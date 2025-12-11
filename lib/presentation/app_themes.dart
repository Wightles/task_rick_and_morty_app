import 'package:flutter/material.dart';

class AppThemes {
  static const Color _primaryColor = Color(0xFF42A5F5);
  static const Color _primaryColorDark = Color(0xFF1976D2);
  static const Color _accentColor = Color(0xFF03DAC6);

  // Светлая тема
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    primaryColorDark: _primaryColorDark,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _accentColor,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 4,
      color: _primaryColor,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
    ),
  );

  // Темная тема
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    primaryColorDark: _primaryColorDark,
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: Color(0xFF121212),
      background: Color(0xFF121212),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 4,
      color: Color(0xFF1E1E1E),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF1E1E1E),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    dialogBackgroundColor: const Color(0xFF1E1E1E),
  );

  // Цвета для статусов (одинаковые для обеих тем)
  static const Color aliveColor = Color(0xFF4CAF50);
  static const Color deadColor = Color(0xFFF44336);
  static const Color unknownColor = Color(0xFF9E9E9E);
}