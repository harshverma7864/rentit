import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// Toggle this to switch between dark and light mode.
  /// ThemeProvider manages this value.
  static bool isDark = true;

  // ── Dark mode colors (Airbnb-inspired dark) ──
  static const Color _dPrimaryDark = Color(0xFF121212);
  static const Color _dPrimaryDeep = Color(0xFF1E1E1E);
  static const Color _dPrimaryBlue = Color(0xFFFF385C);      // Airbnb Rausch red
  static const Color _dPrimaryLight = Color(0xFFFF6B81);
  static const Color _dAccentBlue = Color(0xFFFF9AAA);
  static const Color _dAccentCyan = Color(0xFFFFB8C6);
  static const Color _dSurfaceGlass = Color(0x33FFFFFF);
  static const Color _dSurfaceGlassLight = Color(0x4DFFFFFF);
  static const Color _dSurfaceGlassMedium = Color(0x66FFFFFF);
  static const Color _dTextPrimary = Color(0xFFFFFFFF);
  static const Color _dTextSecondary = Color(0xB3FFFFFF);
  static const Color _dTextHint = Color(0x66FFFFFF);
  static const Color _dSuccess = Color(0xFF00A699);          // Airbnb teal
  static const Color _dWarning = Color(0xFFFFB400);
  static const Color _dError = Color(0xFFFF385C);
  static const Color _dCardBg = Color(0xFF2A2A2A);

  // ── Light mode colors (Airbnb light) ──
  static const Color _lPrimaryDark = Color(0xFFFFFFFF);
  static const Color _lPrimaryDeep = Color(0xFFF7F7F7);
  static const Color _lPrimaryBlue = Color(0xFFFF385C);      // Same Rausch red
  static const Color _lPrimaryLight = Color(0xFFFF6B81);
  static const Color _lAccentBlue = Color(0xFFDDDDDD);
  static const Color _lAccentCyan = Color(0xFFFF385C);
  static const Color _lSurfaceGlass = Color(0x1A000000);     // Dark glass on light bg
  static const Color _lSurfaceGlassLight = Color(0x0D000000);
  static const Color _lSurfaceGlassMedium = Color(0x26000000);
  static const Color _lTextPrimary = Color(0xFF222222);
  static const Color _lTextSecondary = Color(0xFF717171);
  static const Color _lTextHint = Color(0xFFB0B0B0);
  static const Color _lSuccess = Color(0xFF00A699);
  static const Color _lWarning = Color(0xFFFFB400);
  static const Color _lError = Color(0xFFFF385C);
  static const Color _lCardBg = Color(0xFFFFFFFF);

  // ── Reactive getters ──
  static Color get primaryDark => isDark ? _dPrimaryDark : _lPrimaryDark;
  static Color get primaryDeep => isDark ? _dPrimaryDeep : _lPrimaryDeep;
  static Color get primaryBlue => isDark ? _dPrimaryBlue : _lPrimaryBlue;
  static Color get primaryLight => isDark ? _dPrimaryLight : _lPrimaryLight;
  static Color get accentBlue => isDark ? _dAccentBlue : _lAccentBlue;
  static Color get accentCyan => isDark ? _dAccentCyan : _lAccentCyan;
  static Color get surfaceGlass => isDark ? _dSurfaceGlass : _lSurfaceGlass;
  static Color get surfaceGlassLight => isDark ? _dSurfaceGlassLight : _lSurfaceGlassLight;
  static Color get surfaceGlassMedium => isDark ? _dSurfaceGlassMedium : _lSurfaceGlassMedium;
  static Color get textPrimary => isDark ? _dTextPrimary : _lTextPrimary;
  static Color get textSecondary => isDark ? _dTextSecondary : _lTextSecondary;
  static Color get textHint => isDark ? _dTextHint : _lTextHint;
  static Color get success => isDark ? _dSuccess : _lSuccess;
  static Color get warning => isDark ? _dWarning : _lWarning;
  static Color get error => isDark ? _dError : _lError;
  static Color get cardBg => isDark ? _dCardBg : _lCardBg;

  static ThemeData get currentTheme => isDark ? darkTheme : lightTheme;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _dPrimaryDark,
      colorScheme: const ColorScheme.dark(
        primary: _dPrimaryBlue,
        secondary: _dAccentCyan,
        surface: _dPrimaryDeep,
        error: _dError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _dTextPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _dTextPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _dTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _dSurfaceGlass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _dAccentBlue.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _dAccentBlue.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _dAccentCyan, width: 2),
        ),
        hintStyle: const TextStyle(color: _dTextHint),
        labelStyle: const TextStyle(color: _dTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _dPrimaryBlue,
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
        color: _dCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: _dAccentCyan,
        unselectedItemColor: _dTextHint,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lPrimaryDark,
      colorScheme: const ColorScheme.light(
        primary: _lPrimaryBlue,
        secondary: _lAccentCyan,
        surface: _lPrimaryDeep,
        error: _lError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _lTextPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _lTextPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lSurfaceGlass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _lAccentBlue.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _lAccentBlue.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lPrimaryBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: _lTextHint),
        labelStyle: const TextStyle(color: _lTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lPrimaryBlue,
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
        color: _lCardBg,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: _lPrimaryBlue,
        unselectedItemColor: _lTextHint,
      ),
    );
  }
}

// Glassmorphic container decoration
class GlassDecoration {
  static BoxDecoration get card => BoxDecoration(
        color: AppTheme.isDark ? AppTheme.surfaceGlass : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.isDark
              ? AppTheme.accentBlue.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark ? 0.2 : 0.06),
            blurRadius: AppTheme.isDark ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get elevated => BoxDecoration(
        color: AppTheme.isDark ? AppTheme.surfaceGlassLight : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.isDark
              ? AppTheme.accentBlue.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark ? 0.3 : 0.08),
            blurRadius: AppTheme.isDark ? 30 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration get subtle => BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      );

  static BoxDecoration get bottomNav => BoxDecoration(
        color: AppTheme.primaryDeep.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppTheme.isDark
                ? AppTheme.accentBlue.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark ? 0.4 : 0.08),
            blurRadius: AppTheme.isDark ? 20 : 10,
            offset: const Offset(0, -3),
          ),
        ],
      );
}
