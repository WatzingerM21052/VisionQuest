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
          isRetroArcade: true,
        );
      case AppThemeOption.adventureMap:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5E3C),
            brightness: Brightness.light,
          ),
          isAdventureMap: true,
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
          isRetroArcade: true,
        );
      case AppThemeOption.adventureMap:
        return _buildTheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5E3C),
            brightness: Brightness.dark,
          ),
          isAdventureMap: true,
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

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    bool isRetroArcade = false,
    bool isAdventureMap = false,
  }) {
    final BorderRadius buttonRadius = BorderRadius.circular(
      isRetroArcade
          ? 6
          : isAdventureMap
          ? 16
          : 12,
    );

    final ShapeBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isRetroArcade ? 10 : 16),
      side: isRetroArcade
          ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.45))
          : isAdventureMap
          ? BorderSide(color: colorScheme.outline.withValues(alpha: 0.35))
          : BorderSide.none,
    );

    final TextTheme textTheme = isRetroArcade
        ? _retroTextTheme(colorScheme)
        : isAdventureMap
        ? _adventureTextTheme(colorScheme)
        : _defaultTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isRetroArcade
            ? colorScheme.surfaceContainerHighest
            : colorScheme.primary,
        foregroundColor: isRetroArcade
            ? colorScheme.onSurface
            : colorScheme.onPrimary,
        elevation: isRetroArcade ? 0 : 2,
        shadowColor: Colors.transparent,
        centerTitle: true,
        shape: isRetroArcade
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.55),
                  width: 2,
                ),
              )
            : null,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: isRetroArcade ? 0 : null,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          side: isRetroArcade
              ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.55))
              : null,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: isRetroArcade ? 0 : null,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          side: isRetroArcade
              ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.55))
              : null,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          side: BorderSide(
            color: isRetroArcade
                ? colorScheme.primary.withValues(alpha: 0.65)
                : colorScheme.outline,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isRetroArcade ? 6 : 8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isRetroArcade ? 8 : 12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isRetroArcade ? 8 : 12),
          borderSide: BorderSide(
            color: isRetroArcade
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isRetroArcade ? 8 : 12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: isRetroArcade ? 2.4 : 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isRetroArcade ? 8 : 12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isRetroArcade ? 8 : 12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: isRetroArcade
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isAdventureMap ? 2 : 1,
        shape: cardShape,
        surfaceTintColor: isRetroArcade
            ? colorScheme.primary.withValues(alpha: 0.06)
            : null,
      ),
      scaffoldBackgroundColor: isRetroArcade
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
      textTheme: textTheme,
    );
  }

  static TextTheme _defaultTextTheme(ColorScheme colorScheme) {
    return TextTheme(
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
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10),
    );
  }

  static TextTheme _retroTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: GoogleFonts.pressStart2p(
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: GoogleFonts.pressStart2p(
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: GoogleFonts.pressStart2p(
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: GoogleFonts.pressStart2p(
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: GoogleFonts.pressStart2p(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      headlineSmall: GoogleFonts.pressStart2p(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: GoogleFonts.pressStart2p(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      titleMedium: GoogleFonts.pressStart2p(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      titleSmall: GoogleFonts.pressStart2p(
        fontSize: 10,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: GoogleFonts.vt323(fontSize: 24, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.vt323(fontSize: 22, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.vt323(fontSize: 20, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.vt323(fontSize: 22, fontWeight: FontWeight.w400),
      labelMedium: GoogleFonts.vt323(fontSize: 20, fontWeight: FontWeight.w400),
      labelSmall: GoogleFonts.vt323(fontSize: 18, fontWeight: FontWeight.w400),
    );
  }

  static TextTheme _adventureTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: GoogleFonts.cinzel(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.cinzel(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.cinzel(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.cinzel(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.cinzel(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
    );
  }
}
