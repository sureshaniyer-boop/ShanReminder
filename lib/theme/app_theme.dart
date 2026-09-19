import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const gold = Color(0xFFE2C77E);
  static const paper = Color(0xFFFAF8F3);
  static const ink = Color(0xFF202B32);
  static const muted = Color(0xFF68716F);
  static const border = Color(0xFFECE8DF);

  static const Map<String, Color> themeColors = {
    'Maroon': Color(0xFF780C29),
    'Royal Blue': Color(0xFF123CA0),
    'Cream': Color(0xFFF4E7CF),
    'Emerald': Color(0xFF005840),
  };

  static ThemeData build(String name) {
    final isCream = name == 'Cream';
    final primary = isCream ? const Color(0xFF875915)
        : themeColors[name] ?? themeColors['Maroon']!;
    final scheme = ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF8B681F),
      surface: paper,
      onSurface: ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ink),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
        bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isCream ? themeColors['Cream'] : primary,
        foregroundColor: isCream ? primary : gold,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isCream ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: isCream ? primary : gold, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.08),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? primary : muted,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 24, color: states.contains(WidgetState.selected) ? primary : muted,
        )),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary, foregroundColor: Colors.white,
        shape: const CircleBorder(), elevation: 4,
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: primary, width: 1.5)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: const BorderSide(color: muted, width: 1.4),
      ),
      cardTheme: CardThemeData(
        elevation: 0, color: Colors.white, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border)),
      ),
    );
  }
}
