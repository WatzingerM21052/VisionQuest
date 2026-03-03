import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../models/app_theme_option.dart';

/// Zentrale Theme-Verwaltung für alle 5 App-Designs.
///
/// Diese Klasse bietet statische Methoden zur Theme-Erstellung und
/// ThemeMode-Bestimmung basierend auf [AppThemeOption].
///
/// Verfügbare Designs:
/// - Light/Dark: Teal Modern (#008B8B)
/// - System: Folgt OS-Einstellung
/// - RetroArcade: Neon 80s (#FF10F0 - Magenta/Neon-Pink)
/// - AdventureMap: Warm Brown (#8B5E3C) - unverändert, passt perfekt
class AppThemes {
  /// Bestimmt den [ThemeMode] für eine [AppThemeOption].
  ///
  /// - System-Option gibt [ThemeMode.system] zurück
  /// - Dark-Option gibt [ThemeMode.dark] zurück
  /// - Alle anderen geben [ThemeMode.light] zurück
  static ThemeMode themeModeFor(AppThemeOption option) {
    switch (option) {
      case AppThemeOption.system:
        return ThemeMode.system;
      case AppThemeOption.dark:
        return ThemeMode.dark;
      case AppThemeOption.light:
      case AppThemeOption.retroArcade:
      case AppThemeOption.adventureMap:
        return ThemeMode.light;
    }
  }

  /// Gibt das Light-Mode ThemeData für die gegebene [AppThemeOption] zurück.
  ///
  /// Nutzt Material You ColorScheme mit unterschiedlichen Seed-Farben
  /// je nach Theme-Option.
  static ThemeData themeFor(AppThemeOption option) {
    switch (option) {
      case AppThemeOption.light:
      case AppThemeOption.system:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF006D63), // Teal-Grün
            brightness: Brightness.light,
          ),
        );
      case AppThemeOption.dark:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF006D63), // Teal-Grün
            brightness: Brightness.dark,
          ),
        );
      case AppThemeOption.retroArcade:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF10F0), // Neon-Magenta (80s Arcade)
            brightness: Brightness.light,
          ),
        );
      case AppThemeOption.adventureMap:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5E3C),
            brightness: Brightness.light,
          ),
        );
    }
  }

  /// Gibt das Dark-Mode ThemeData für die gegebene [AppThemeOption] zurück.
  ///
  /// Falls die Option kein spezielles Dark-Design hat (light, system),
  /// wird das Standard Dark-Design zurückgegeben.
  static ThemeData darkThemeFor(AppThemeOption option) {
    switch (option) {
      case AppThemeOption.retroArcade:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF10F0), // Neon-Magenta (80s)
            brightness: Brightness.dark,
          ),
        );
      case AppThemeOption.adventureMap:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5E3C),
            brightness: Brightness.dark,
          ),
        );
      case AppThemeOption.light:
      case AppThemeOption.system:
      case AppThemeOption.dark:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF006D63), // Teal-Grün
            brightness: Brightness.dark,
          ),
        );
    }
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        displaySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }
}
