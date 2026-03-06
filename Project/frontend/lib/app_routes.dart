/// Zentrale Navigation Route-Konstanten für die gesamte Applikation.
///
/// Diese Klasse definiert alle verfügbaren Named Routes und wird vom
/// Navigation-System verwendet, um zwischen Screens zu navigieren.
class AppRoutes {
  /// Login-Screen für Benutzer-Authentifizierung.
  static const login = '/login';

  /// Register-Screen für neue Benutzer-Registrierung.
  static const register = '/register';

  /// Home-Screen als Haupt-Interface nach Login.
  static const home = '/home';

  /// Scanner-Screen für Kamera-basierte Objekterkennung.
  static const scanner = '/scanner';

  /// Reward-Screen zeigt Quest-Ergebnisse und XP-Verdiener.
  /// Übergabeparameter: `VisionResult` (Erkennungsergebnis).
  static const reward = '/reward';

  /// Quest-Log-Screen zeigt alle bisherigen gefundenen Objekte.
  static const questLog = '/quest-log';

  /// Settings-Screen für Theme-Einstellungen und Benutzerkonfiguration.
  static const settings = '/settings';

  /// Achievements-Screen zeigt alle verfügbaren Achievements.
  static const achievements = '/achievements';

  /// Admin-Screen für Benutzerverwaltung (nur für Admins).
  static const admin = '/admin';
}
