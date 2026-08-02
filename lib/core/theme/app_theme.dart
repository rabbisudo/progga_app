import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
      fontFamily: GoogleFonts.notoSansBengali().fontFamily,
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
      textTheme: _scaleTextTheme(
        GoogleFonts.notoSansBengaliTextTheme(baseTextTheme).copyWith(
          titleLarge: GoogleFonts.notoSansBengali(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212529),
          ),
          headlineMedium: GoogleFonts.notoSansBengali(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212529),
          ),
        ),
        1.08,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.notoSansBengali().fontFamily,
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
      ),
      textTheme: _scaleTextTheme(
        GoogleFonts.notoSansBengaliTextTheme(baseTextTheme).copyWith(
          titleLarge: GoogleFonts.notoSansBengali(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: GoogleFonts.notoSansBengali(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        1.08,
      ),
    );
  }

  static TextTheme _scaleTextTheme(TextTheme base, double factor) {
    TextStyle? scale(TextStyle? style, double defaultSize) {
      if (style == null) return null;
      final size = style.fontSize ?? defaultSize;
      return style.copyWith(fontSize: size * factor);
    }

    return base.copyWith(
      displayLarge: scale(base.displayLarge, 57),
      displayMedium: scale(base.displayMedium, 45),
      displaySmall: scale(base.displaySmall, 36),
      headlineLarge: scale(base.headlineLarge, 32),
      headlineMedium: scale(base.headlineMedium, 28),
      headlineSmall: scale(base.headlineSmall, 24),
      titleLarge: scale(base.titleLarge, 22),
      titleMedium: scale(base.titleMedium, 16),
      titleSmall: scale(base.titleSmall, 14),
      bodyLarge: scale(base.bodyLarge, 16),
      bodyMedium: scale(base.bodyMedium, 14),
      bodySmall: scale(base.bodySmall, 12),
      labelLarge: scale(base.labelLarge, 14),
      labelMedium: scale(base.labelMedium, 12),
      labelSmall: scale(base.labelSmall, 11),
    );
  }
}
