import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StitchTheme {
  // Brand Palette from Stitch Tailwind Config
  static const Color cyan = Color(0xFF38BDF8);
  static const Color cyanFixed = Color(0xFFC4E7FF);
  static const Color primaryContainer = Color(0xFF38BDF8);
  static const Color onPrimaryContainer = Color(0xFF00354A);
  
  static const Color emerald = Color(0xFF56E5A9);
  static const Color amber = Color(0xFFFFB95F);
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFF43F5E);
  
  static const Color bgDark = Color(0xFF0B1326);
  static const Color bgSurface = Color(0xFF070D1E);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHigh = Color(0xFF222A3D);
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFFBDC8D1);

  // Background Wallpaper URLs extracted from Stitch code.html
  static const String nightWallpaper =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCh1TORYcQp8FP20j7E96NKdUI4a8PwUBKmXh--V8DMm2VNyrHqr0RPt6G0uq-aov1ETG6Tnad2kKSr7Fbb_sHIsTOxG6gi3BSKO4LVS7jBWQ-pbKaYA5Rn-aNKokmkmmYbpkDiawiVh38mvjyUqje3nI5iWdGPZMhY3Rbm4oD6V0V3Ttln7BKfhn6oq4Xs6eCOxaHF6fPzhRkDBWqNLzQ7-dfpflQZyIVvYSUBdbDYOTL7wbYY8Ia0OavviaviVq2IyKU';

  static const String aerialMapWallpaper =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDaFvsPml28KIfe-vWRh38hf3Y1yMeRflrF_YdVxT_g428X0imSogP7iiPPoDdJxSd435mAjYb_HhXdUxOF3VjNtX9IX0myypfaFswsI-jDtuDZt1ujuhZe0Sz0_WhVtrkbC8TzIg0t8p4R8CgWx8d7Q4g4vqiR93q6yjMXJjmZw2ppLEs6p2CwG2B43kMmahN8slDlwPkzZ_zf2UMblzfT8abf_zne31TC_zb6_C2zNzWQRkk2ij3S2NL3zkniGBLDiw';

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: cyan,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        onPrimary: onPrimaryContainer,
        secondary: amber,
        tertiary: emerald,
        surface: surfaceContainer,
        onSurface: onSurface,
        error: red,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
          color: const Color(0xFF94A3B8),
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
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

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE8EEF5),
      primaryColor: const Color(0xFF0284C7),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0284C7),
        onPrimary: Colors.white,
        secondary: Color(0xFFD97706),
        tertiary: Color(0xFF059669),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
    );
  }
}
