import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Brand colors matching a premium coral design system
  static const Color primaryColor = Color(0xFFF18881);
  static const Color primaryDarkColor = Color(0xFFD9746E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F3F5);

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Li Ador Noirrit',
      fontFamilyFallback: const [],
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryDarkColor,
        surface: lightSurface,
        error: Color(0xFFD32F2F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: _applyFontSettings(
        baseTextTheme.copyWith(
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212529),
          ),
          headlineMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212529),
          ),
        ),
        1.20, // Increased scaling factor from 1.12 to 1.20 for larger text size
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Li Ador Noirrit',
      fontFamilyFallback: const [],
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: darkCard,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryDarkColor,
        surface: darkSurface,
        error: Color(0xFFCF6679),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: _applyFontSettings(
        baseTextTheme.copyWith(
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        1.20, // Increased scaling factor from 1.12 to 1.20 for larger text size
      ),
    );
  }

  static TextTheme _applyFontSettings(TextTheme base, double scaleFactor) {
    TextStyle? adjustStyle(TextStyle? style, double defaultSize) {
      if (style == null) return null;
      final size = style.fontSize ?? defaultSize;
      return style.copyWith(
        fontSize: size * scaleFactor,
        fontFamily: 'Li Ador Noirrit',
        fontFamilyFallback: const [],
      );
    }

    return base.copyWith(
      displayLarge: adjustStyle(base.displayLarge, 57),
      displayMedium: adjustStyle(base.displayMedium, 45),
      displaySmall: adjustStyle(base.displaySmall, 36),
      headlineLarge: adjustStyle(base.headlineLarge, 32),
      headlineMedium: adjustStyle(base.headlineMedium, 28),
      headlineSmall: adjustStyle(base.headlineSmall, 24),
      titleLarge: adjustStyle(base.titleLarge, 22),
      titleMedium: adjustStyle(base.titleMedium, 16),
      titleSmall: adjustStyle(base.titleSmall, 14),
      bodyLarge: adjustStyle(base.bodyLarge, 16),
      bodyMedium: adjustStyle(base.bodyMedium, 14),
      bodySmall: adjustStyle(base.bodySmall, 12),
      labelLarge: adjustStyle(base.labelLarge, 14),
      labelMedium: adjustStyle(base.labelMedium, 12),
      labelSmall: adjustStyle(base.labelSmall, 11),
    );
  }
}
