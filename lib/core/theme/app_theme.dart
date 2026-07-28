import 'package:flutter/material.dart';
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
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryDarkColor,
        surface: lightSurface,
        error: Color(0xFFD32F2F),
      ),
      textTheme: GoogleFonts.notoSansBengaliTextTheme(ThemeData.light().textTheme).copyWith(
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
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: darkCard,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryDarkColor,
        surface: darkSurface,
        error: Color(0xFFCF6679),
      ),
      textTheme: GoogleFonts.notoSansBengaliTextTheme(ThemeData.dark().textTheme).copyWith(
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
    );
  }
}
