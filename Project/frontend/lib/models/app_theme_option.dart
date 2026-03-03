enum AppThemeOption {
  light,
  dark,
  system,
  retroArcade,
  adventureMap,
}

extension AppThemeOptionX on AppThemeOption {
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
