import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const VisionQuestApp());
}

class VisionQuestApp extends StatelessWidget {
  const VisionQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionQuest',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}

ThemeData _buildLightTheme() {
  const seedColor = Color(0xFF5D4E8C); // Deep Purple für Adventure
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

ThemeData _buildDarkTheme() {
  const seedColor = Color(0xFF5D4E8C);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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


