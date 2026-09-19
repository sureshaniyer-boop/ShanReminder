import 'package:flutter/material.dart';

class AppTheme {
  static const gold = Color(0xFFD4AF37);

  static const Map<String, Color> themeColors = {
    'Maroon': Color(0xFF800020),
    'Royal Blue': Color(0xFF123A9C),
    'Cream': Color(0xFFF4E7CF),
    'Emerald': Color(0xFF006B4F),
  };

  static ThemeData build(String name) {
    final primary = themeColors[name] ?? themeColors['Maroon']!;
    final isCream = name == 'Cream';
    final foreground = isCream ? const Color(0xFF5F3A10) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        secondary: gold,
        surface: const Color(0xFFFFFBF5),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBF5),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: foreground,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: foreground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4DDD3)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
