/// Verfügbare Theme-Optionen für die VisionQuest-App.
///
/// Die App unterstützt 5 unterschiedliche visuelle Designs:
/// - [light]: Helles Material You Design
/// - [dark]: Dunkles Material You Design
/// - [system]: Folgt den Systemeinstellungen des Geräts
/// - [retroArcade]: Neon-Cyan Retro-Arcade Design
/// - [adventureMap]: Warmer Brown Adventure-Map Design
enum AppThemeOption { light, dark, system, retroArcade, adventureMap }

/// Extension für [AppThemeOption] zur Anzeige von Theme-Namen.
extension AppThemeOptionX on AppThemeOption {
  /// Gibt die deutsche Beschreibung des Theme für die UI zurück.
  String get label {
    switch (this) {
      case AppThemeOption.light:
        return 'Hell';
      case AppThemeOption.dark:
        return 'Dunkel';
      case AppThemeOption.system:
        return 'System';
      case AppThemeOption.retroArcade:
        return 'Retro-Arcade';
      case AppThemeOption.adventureMap:
        return 'Adventure-Map';
    }
  }
}
