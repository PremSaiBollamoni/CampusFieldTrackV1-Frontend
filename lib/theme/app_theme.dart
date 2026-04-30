import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryMuted = Color(0x403B82F6);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryMuted = Color(0x4006B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color successMuted = Color(0x4010B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningMuted = Color(0x40F59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorMuted = Color(0x40EF4444);

  // Light Surface System (replaces dark surface system)
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEFF3F8);
  static const Color surfaceElevated = Color(0xFFE2E8F0);
  static const Color glassSurface = Color(0x14000000);
  static const Color glassBorder = Color(0x1A000000);

  // Text (light mode)
  static const Color onDark = Color(0xFF111827);
  static const Color onDarkMuted = Color(0xFF6B7280);
  static const Color onDarkSubtle = Color(0xFF9CA3AF);

  // Map overlay gradient
  static const Color mapOverlayStart = Color(0x00F1F5F9);
  static const Color mapOverlayEnd = Color(0xCCF1F5F9);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDBEAFE),
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onDark,
        surfaceContainerHighest: surfaceVariant,
        outline: Color(0xFFE5E7EB),
        outlineVariant: Color(0xFFF3F4F6),
        error: error,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: onDark,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: onDark,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: onDark,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onDark,
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onDark,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: onDark,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onDark,
        ),
        titleSmall: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onDark,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: onDark,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: onDarkMuted,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onDarkSubtle,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onDark,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onDark,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: onDarkMuted,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onDark,
        ),
        iconTheme: const IconThemeData(color: onDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: onDark, size: 20),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 0,
      ),
    );
  }

  // Keep darkTheme as alias to lightTheme to prevent any reference errors
  static ThemeData get darkTheme => lightTheme;
}
