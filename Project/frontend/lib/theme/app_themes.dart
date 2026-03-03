import 'package:flutter/material.dart';

import '../models/app_theme_option.dart';

/// Zentrale Theme-Verwaltung für alle 5 App-Designs.
///
/// Diese Klasse bietet statische Methoden zur Theme-Erstellung und
/// ThemeMode-Bestimmung basierend auf [AppThemeOption].
///
/// Verfügbare Designs:
/// - Light/Dark: Purple Material You (#5D4E8C)
/// - System: Folgt OS-Einstellung
/// - RetroArcade: Neon-Cyan (#00C2FF)
/// - AdventureMap: Warm Brown (#8B5E3C)
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
            seedColor: const Color(0xFF5D4E8C),
            brightness: Brightness.light,
          ),
        );
      case AppThemeOption.dark:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D4E8C),
            brightness: Brightness.dark,
          ),
        );
      case AppThemeOption.retroArcade:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF00C2FF),
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
  /// wird das Standard Dark Purple Design zurückgegeben.
  static ThemeData darkThemeFor(AppThemeOption option) {
    switch (option) {
      case AppThemeOption.retroArcade:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF00C2FF),
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
            seedColor: const Color(0xFF5D4E8C),
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        displaySmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12),
        labelLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        labelMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
      ),
    );
  }
}
