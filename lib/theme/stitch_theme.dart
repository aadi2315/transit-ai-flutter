import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StitchTheme {
  // Brand Palette: Vibrant White & Transit Cyan
  static const Color cyan = Color(0xFF0891B2);
  static const Color cyanHover = Color(0xFF0E7490);
  static const Color cyanLight = Color(0xFFECFEFF);
  static const Color cyanBorder = Color(0xFFA5F3FC);

  // Backward-compatible alias tokens
  static const Color orange = cyan;
  static const Color orangeHover = cyanHover;
  static const Color orangeLight = cyanLight;
  static const Color orangeBorder = cyanBorder;

  static const Color primaryContainer = Color(0xFFCFFAFE);
  static const Color onPrimaryContainer = Color(0xFF164E63);
  
  static const Color cyanFixed = Color(0xFFCFFAFE);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  
  // Clean Light Surfaces
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgSurface = Colors.white;
  static const Color surfaceContainer = Colors.white;
  static const Color surfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Deprecated dark tokens maintained safely
  static const Color bgDark = Color(0xFFF8FAFC);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: cyan,
      colorScheme: const ColorScheme.light(
        primary: cyan,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: Color(0xFF06B6D4),
        tertiary: emerald,
        surface: surfaceContainer,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: borderLight,
        error: red,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF64748B),
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cyan,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // DarkTheme mapped safely to the light theme for uniform Light Mode
  static ThemeData get darkTheme => lightTheme;
}
