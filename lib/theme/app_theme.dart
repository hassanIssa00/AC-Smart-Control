import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Modern Human Light Palette (Apple / Nest / Dyson Style) ───────────────
  static const Color primary = Color(0xFF0284C7);        // Ocean Sky Blue (Primary Action)
  static const Color primaryLight = Color(0xFFE0F2FE);   // Soft Glacier Tint
  static const Color primaryDark = Color(0xFF0369A1);    // Deep Blue
  
  static const Color accent = Color(0xFF6366F1);         // Modern Indigo Accent
  static const Color accentLight = Color(0xFFEEF2FF);
  
  static const Color success = Color(0xFF10B981);        // Mint Emerald
  static const Color successLight = Color(0xFFECFDF5);
  
  static const Color warning = Color(0xFFF59E0B);        // Warm Amber
  static const Color warningLight = Color(0xFFFFFBEB);
  
  static const Color danger = Color(0xFFEF4444);         // Clean Coral Red
  static const Color dangerLight = Color(0xFFFEF2F2);

  // ─── Backgrounds & Surfaces (Crisp & Clean) ───────────────────────────────
  static const Color scaffoldBg = Color(0xFFF8FAFC);     // Slate 50 (Soft light background)
  static const Color cardBg = Color(0xFFFFFFFF);         // Pure White Cards
  static const Color surface = Color(0xFFF1F5F9);        // Slate 100 (Subtle dividers & chips)
  static const Color border = Color(0xFFE2E8F0);         // Slate 200 (Clean hairline borders)
  
  // ─── Typography Colors ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);    // Slate 900 (High contrast, readable)
  static const Color textSecondary = Color(0xFF64748B);  // Slate 500 (Clean subtitles)
  static const Color textMuted = Color(0xFF94A3B8);      // Slate 400 (Captions & hints)

  // ─── Elevated Card Shadows ───────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get activeGlow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.18),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  // ─── Theme Data ──────────────────────────────────────────────────────────
  static ThemeData get light {
    final baseText = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: cardBg,
        error: danger,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  // Backward compatibility alias
  static ThemeData get dark => light;
}
