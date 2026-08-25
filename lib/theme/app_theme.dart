import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 60-30-10 RULE:
/// Accent colors (growth, recover, danger, identity) are a shared ~10% area budget 
/// across any single screen and must NEVER be used as a card or screen background/fill.
class AppTheme {
  // --- Dominant (60%) ---
  static const Color bgBase = Color(0xFF121212);
  static const Color bgSurface = Color(0xFF1A1A1A);
  static const Color bgSurfaceRaised = Color(0xFF1F1F1F);
  static const Color borderDefault = Color(0xFF2A2A2A);
  static const Color borderStrong = Color(0xFF3A3A3A);

  // --- Secondary (30%) ---
  static const Color textPrimary = Color(0xFFF0EFE9);
  static const Color textSecondary = Color(0xFF8A8A85);
  static const Color textMuted = Color(0xFF5F5E5A);

  // --- Accent (10% shared) ---
  static const Color accentGrowthFill = Color(0xFF1D9E75);
  static const Color accentGrowthText = Color(0xFF5DCAA5);
  static const Color accentRecoverFill = Color(0xFFBA7517);
  static const Color accentRecoverText = Color(0xFFEF9F27);
  
  // Note: accent.danger is defined here for future extensibility (e.g. high-priority habit misses),
  // but it is intentionally NEVER used anywhere in v1 to keep the emotional palette calm by design.
  // Do not build a high-priority flag just to use this color.
  static const Color accentDanger = Color(0xFFA32D2D);
  static const Color accentIdentityFill = Color(0xFF534AB7);
  static const Color accentIdentityText = Color(0xFF7F77DD);

  // --- Spacing ---
  static const double spacingSm = 4.0;
  static const double spacingMd = 8.0;
  static const double spacingLg = 12.0;
  static const double spacingXl = 16.0;
  static const double spacing2xl = 24.0;
  static const double spacing3xl = 32.0;
  static const double spacing4xl = 40.0;

  // --- Radii ---
  static const BorderRadius radiusCard = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius radiusButton = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius radiusBadge = BorderRadius.all(Radius.circular(999.0));

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    
    // Type scale with weights 400 and 500 only, line heights 1.4 for UI, 1.6 for body.
    final customTextTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 30, fontWeight: FontWeight.w500, color: textPrimary, height: 1.4),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w500, color: textPrimary, height: 1.4),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w500, color: textPrimary, height: 1.4),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w500, color: textPrimary, height: 1.4),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary, height: 1.6),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted, height: 1.6),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgBase,
      colorScheme: const ColorScheme.dark(
        surface: bgBase,
        primary: accentGrowthFill,
        secondary: accentIdentityFill,
        error: accentDanger,
      ),
      textTheme: customTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgBase,
        selectedItemColor: textPrimary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: radiusCard,
          side: BorderSide(color: borderDefault, width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: borderDefault,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
