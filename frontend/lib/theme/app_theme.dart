import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep brown & beige palette
  static const Color primaryDark = Color(0xFF1C120D);       // Very dark brown bg
  static const Color primaryDeep = Color(0xFF2A1A12);       // Deeper brown
  static const Color primaryBlue = Color(0xFF6D4C2E);       // Rich brown (primary action)
  static const Color primaryLight = Color(0xFF8D6E4C);      // Lighter warm brown
  static const Color accentBlue = Color(0xFFD4B896);        // Soft beige accent
  static const Color accentCyan = Color(0xFFC9A66B);        // Warm gold/caramel accent
  static const Color surfaceGlass = Color(0x33FFFFFF);      // Glass overlay
  static const Color surfaceGlassLight = Color(0x4DFFFFFF);
  static const Color surfaceGlassMedium = Color(0x66FFFFFF);
  static const Color textPrimary = Color(0xFFF5EDE4);       // Warm off-white text
  static const Color textSecondary = Color(0xB3F5EDE4);     // 70% off-white
  static const Color textHint = Color(0x66F5EDE4);          // 40% off-white
  static const Color success = Color(0xFF6B8E4E);           // Olive green
  static const Color warning = Color(0xFFD4A03C);           // Amber
  static const Color error = Color(0xFFC0392B);             // Muted red
  static const Color cardBg = Color(0xFF33211A);            // Dark brown card

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentCyan,
        surface: primaryDeep,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGlass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentBlue.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentBlue.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),
        hintStyle: const TextStyle(color: textHint),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: accentCyan,
        unselectedItemColor: textHint,
      ),
    );
  }
}

// Glassmorphic container decoration
class GlassDecoration {
  static BoxDecoration get card => BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get elevated => BoxDecoration(
        color: AppTheme.surfaceGlassLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration get subtle => BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      );

  static BoxDecoration get bottomNav => BoxDecoration(
        color: AppTheme.primaryDeep.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppTheme.accentBlue.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      );
}
