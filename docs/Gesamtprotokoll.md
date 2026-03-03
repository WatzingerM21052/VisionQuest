# VisionQuest - Projektdokumentation

**Projekt:** VisionQuest - AR-basierte Objekterkennungs-Quest-App  
**Sprache:** Dart/Flutter  
**Version:** 1.0.0  
**Status:** ✅ Vollständig abgeschlossen (21 Steps über 3 Phasen)  
**Datum:** März 2026

---

## 📋 Inhaltsverzeichnis

1. [Projektübersicht](#projektübersicht)
2. [Architektur](#architektur)
3. [Implementierung - Phase 1-3](#implementierung)
4. [Features](#features)
5. [Technical Stack](#technical-stack)
6. [Setup & Installation](#setup--installation)
7. [Entwickler-Guide](#entwickler-guide)
8. [API-Dokumentation](#api-dokumentation)

---

## Projektübersicht

### Vision
VisionQuest ist eine Flutter-basierte Mobile-Anwendung, die Benutzern ermöglicht, reale Objekte mit ihrer Kamera zu scannen und dabei XP, Level-Aufstiegsfortschritt und Streak-Zähler zu verdienen. Das Spiel kombiniert AR-Technologie mit Gamification-Elementen.

### Kernfeatures
- 🎮 **Quest-System**: Objekte scannen → XP verdienen → Level aufsteigen
- 🎨 **5 Themes**: Light, Dark, System, RetroArcade, AdventureMap
- 📱 **Responsive Design**: Mobile + Tablet-unterstützt
- 🔥 **Streak-Tracking**: Konsekutive Tage mit Quests
- 📊 **Quest-Log**: Historie aller gefundenen Objekte
- ✨ **Animationen**: Lottie-Animationen + UI-Transitions

### Zielplattformen
- iOS 12.0+
- Android 9.0+
- Web (Flutter Web)

---

## Architektur

### Schichten-Modell

```
┌─────────────────────────────────────┐
│     UI Layer (Screens)              │ ← Material You, ConsumerWidgets
├─────────────────────────────────────┤
│  State Management (Riverpod)        │ ← appStateProvider, StateNotifier
├─────────────────────────────────────┤
│  Business Logic (Services)          │ ← Vision, Auth, DB, Session
├─────────────────────────────────────┤
│  Models & Data (Immutable)          │ ← AppState, QuestProgress, etc.
├─────────────────────────────────────┤
│  Navigation & Theme                 │ ← AppRoutes, AppThemes
└─────────────────────────────────────┘
```

### Komponenten-Übersicht

#### **Frontend Struktur** (lib/)
```
lib/
  ├── main.dart                    # App Entry + Root Navigation
  ├── app_routes.dart              # Named Route Konstanten
  │
  ├── models/                      # Data Classes (Immutable)
  │   ├── app_state.dart           # Root State Container
  │   ├── app_theme_option.dart    # Theme Enum (5 Varianten)
  │   ├── quest_progress.dart      # Level/XP/Streak Tracking
  │   └── quest_log_entry.dart     # Einzelner Quest-Erfolg
  │
  ├── providers/                   # Riverpod State Management
  │   └── app_state_provider.dart  # GlobalStateNotifier
  │
  ├── screens/                     # UI Screens (6 Total)
  │   ├── home_screen.dart         # Haupt-Dashboard mit Pulse-Animation
  │   ├── scanner_screen.dart      # Camera-Interface für Objektscanning
  │   ├── reward_screen.dart       # Quest-Ergebnis mit Lottie-Animation
  │   ├── quest_log_screen.dart    # Historie mit Timestamp-Formatting
  │   ├── settings_screen.dart     # Theme-Auswahl (5 Optionen)
  │   ├── login_screen.dart        # Auth-Einstieg
  │   └── register_screen.dart     # Neue Benutzer Registrierung
  │
  ├── services/                    # Business Logic
  │   ├── auth_service.dart        # Login/Register Logic
  │   ├── vision_service.dart      # ML Vision API Integration
  │   ├── db_service.dart          # Datenbank-Operationen
  │   └── session_service.dart     # Session Management
  │
  ├── theme/                       # Styling & Theming
  │   └── app_themes.dart          # 5 Theme Definitions (Material You)
  │
  └── widgets/                     # Reusable Components
      └── [Custom Widgets]

assets/
  ├── Icon.png                     # App Icon
  ├── Startlogo.png                # Splash Screen Logo
  └── [Additional Assets]
```

---

## Implementierung

### Phase 1: UI-Grundlagen ✅ (7 Steps)

#### **Step 1: Screen-Bestandsaufnahme**
- Analyse der 5 bestehenden Screens (Login, Register, Home, Scanner, Settings)
- Plannung neuer Screens: Reward, QuestLog
- Routing-Struktur definieren

#### **Step 2: AppRoutes zentral**
- `AppRoutes` Klasse mit 7 Named Routes:
  - `/login`, `/register`, `/home`, `/scanner`, `/questLog`, `/settings`, `/reward`
- Zentrale Verwaltung für alle Navigation

#### **Step 3-4: Quest-Log & Settings Screens**
- **QuestLogScreen**: Zeigt alle gefundenen Objekte mit Timestamp
- **SettingsScreen**: Theme-Wechsel via SegmentedButton

#### **Step 5: Named Routing Integration**
- Konvertierung von `routes` auf `onGenerateRoute`
- Alle Screens verwenden `NavigationPushNamed()`
- Dynamische Argument-Übergabe (z.B. VisionResult für Reward)

#### **Step 6: Responsive Layouts**
- Standard-Pattern: `LayoutBuilder` + `ConstrainedBox`
- Dynamic Content-Width basierend auf Breakpoints:
  - Mobile: 480px
  - Tablet: 620px-820px
  - Desktop: 760px-1040px

#### **Step 7: Analyzer-Validierung**
- ✅ Flutter analyze: No issues
- Alle 6 Screens responsive + geroutet

### Phase 2: State Management ✅ (8 Steps)

#### **Step 1: Riverpod Dependency**
- `flutter_riverpod: ^2.6.1` zu pubspec.yaml
- Grundlage für Global State

#### **Step 2-3: AppState Models**
```dart
class AppState {
  final AppThemeOption theme;           // Aktuelles Design
  final QuestProgress progress;         // Level/XP/Streak
  final List<QuestLogEntry> logEntries; // Quest-Historie
}

enum AppThemeOption { light, dark, system, retroArcade, adventureMap }

class QuestProgress {
  final int totalXp;                    // Kumulativ
  final int level;                      // Calculated from XP
  final int streak;                     // Consecutive days
  final DateTime? lastCompletedDate;
}

class QuestLogEntry {
  final String label;    // "Apfel", "Buch", etc.
  final int xp;          // 10-100 XP
  final double confidence; // 0.0-1.0 Vision Score
  final DateTime timestamp;
}
```

#### **Step 4: Theme System (5 Varianten)**
- **Light/Dark**: Purple Material You Seed (#5D4E8C)
- **System**: Folgt OS-Einstellung
- **RetroArcade**: Cyan Neon (#00C2FF)
- **AdventureMap**: Warm Brown (#8B5E3C)

Implementierung:
```dart
class AppThemes {
  static ThemeData themeFor(AppThemeOption option) { ... }
  static ThemeData darkThemeFor(AppThemeOption option) { ... }
  static ThemeMode themeModeFor(AppThemeOption option) { ... }
}
```

#### **Step 5-7: Riverpod Integration**
- Screens zu `ConsumerWidget`/`ConsumerStatefulWidget` konvertiert
- Home-Screen: Live XP/Level/Streak Anzeige via `ref.watch()`
- Settings-Screen: Theme-Umschaltung via `ref.read().setTheme()`
- Reward-Screen: Quest-Erfolg speichern via `ref.read().addQuestResult()`
- QuestLog-Screen: Echte Daten + Empty-State UI

#### **Step 8: Quest-Logik Hardened**
```dart
// XP-Berechnung: Confidence → 10-100 XP
int _xpFromConfidence(double confidence) {
  final normalized = confidence.clamp(0.0, 1.0);
  return (10 + (normalized * 90)).round();
}

// Level-Berechnung: 1000 XP pro Level
int _levelFromXp(int xp) => (xp ~/ 1000) + 1;

// Streak-Logik: Date-basiert, keine Doppel-Zählung
int _calculateStreak(QuestProgress prev, DateTime now) {
  if (prev.lastCompletedDate == null) return 1;
  final daysDiff = now.difference(prev.lastCompletedDate!).inDays;
  if (daysDiff == 0) return prev.streak;     // Same day: no increment
  if (daysDiff == 1) return prev.streak + 1; // Next day: increment
  return 1;                                   // Gap: reset to 1
}
```

### Phase 3: Finalisierung & Abgabe ✅ (6 Steps)

#### **Step 1: Lottie Dependency**
- `lottie: ^3.1.2` zu pubspec.yaml
- Free Lottie-Animationen von lottie.host

#### **Step 2: Reward-Screen Animationen**
- **Analyzing Phase**: Lottie Loading-Spinner
- **Success Phase**: Lottie Celebration + ScaleTransition (1.0→1.15)
- Fallbacks auf Material Icons bei Netzwerkfehler

#### **Step 3: Home-Screen Polish**
- **Streak-Pulse**: 1500ms Scale-Animation (1.0⇄1.15)
- **XP-Bar Glow**: BoxShadow mit Primary-Color (0.3 alpha)
- **Daily-Quest**: Check-Icon + Dynamic Shadow bei Completion

#### **Step 4: Navigation-Übergänge**
- `PageRouteBuilder` für alle 7 Routes
- `SlideTransition` von rechts mit 400ms Duration
- easeInOut Curve für sanfte Bewegung

#### **Step 5: Code Cleanup & Dartdoc**
Dokumentierte Public APIs:
- AppRoutes (7 Konstanten)
- Models (4 Data Classes)
- Providers (1 GlobalProvider + 1 Notifier)
- AppThemes (3 Public Methods)
- Main Entry Point

#### **Step 6: Final Analysis**
- ✅ flutter analyze: **No issues found!**
- Alle 6 Screens + Animations + Routing + State Management + Docs integriert

---

## Features

### 🎮 Quest-System
**Ablauf:**
1. User öffnet Scanner-Screen
2. Kamera erfasst Objekt
3. Vision-Service erkennt Objekt + Genauigkeit
4. Reward-Screen zeigt XP + animiert Erfolg
5. Quest-Ergebnis wird in globalem State gespeichert
6. Home-Screen aktualisiert Level/XP/Streak live
7. QuestLog zeigt Historie mit Timestamp

**XP-Berechnung:**
- Base: 10 XP (für 0% Confidence)
- Max: 100 XP (für 100% Confidence)
- Linear skaliert basierend auf Vision-Genauigkeit

**Level-System:**
- 1000 XP pro Level
- Level = (totalXp / 1000) + 1
- Berechnete Properties im UI: levelProgress, nextLevelXp, etc.

**Streak-Tracking:**
- Zählt konsekutive Tage mit mindestens 1 Quest
- Gleicher Tag = keine Increment
- 1+ Tag Pause = Reset auf 1
- Anzeige mit 🔥 Icon im Home-Screen

### 🎨 Theme System
**5 Designs:**
1. **Light** - Hell mit Purple Seed
2. **Dark** - Dunkel mit Purple Seed
3. **System** - Folgt OS Dark/Light Einstellung
4. **RetroArcade** - Neon Cyan mit Material You
5. **AdventureMap** - Warm Brown mit Material You

**Implementierung:**
- Alle Themes nutzen Material You (useMaterial3: true)
- ColorScheme.fromSeed mit Brightness-Varianten
- Dynamisches Switching ohne App-Restart via Riverpod

### 📱 Responsive Design
**Breakpoints:**
| Screen | Width | Layout |
|--------|-------|--------|
| Mobile | <700px | Single Column, 480px content |
| Tablet | 700-1000px | 620px content |
| Desktop | >1000px | 760px+ content |

**Pattern:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth;
    final contentWidth = width > 1000 ? 760 : (width > 700 ? 620 : 480);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: contentWidth),
      child: SingleChildScrollView(child: Column(...)),
    );
  }
)
```

### ✨ Animations
| Element | Animation | Duration | Effect |
|---------|-----------|----------|--------|
| Streak Counter | Pulse Scale | 1500ms | 1.0 ⇄ 1.15 |
| XP Progress-Bar | Glow Shadow | Static | BoxShadow mit Primary |
| Reward Success | Lottie + Scale | 900ms | Celebration Effect |
| Navigation | Slide | 400ms | Right → Left |

### 🔐 Authentication
- Email/Password Login
- Registrierung mit Validierung
- Secure Token Storage via flutter_secure_storage
- Session Management für Auth-State

---

## Technical Stack

### Frontend
- **Framework:** Flutter 3.10.3
- **Language:** Dart (null-safe)
- **State Mgmt:** Riverpod 2.6.1 (StateNotifier Pattern)
- **Design:** Material You (useMaterial3: true)
- **Animations:** Lottie 3.1.2 + Flutter Built-in
- **Camera:** camera 0.11.0+2
- **Storage:** flutter_secure_storage 9.2.4
- **HTTP:** http 1.6.0

### Backend (Separate Node.js Project)
- **Server:** Node.js + Express
- **Database:** SQL (Schema-based)
- **APIs:**
  - Authentication: /auth/login, /auth/register
  - Vision: /api/vision (ML Vision Integration)
  - Database: /api/db/* (CRUD Operations)

### Build & Deployment
- **Build System:** Flutter (gradle für Android)
- **Code Quality:** flutter analyze (strict, no issues)
- **Testing:** Jest (Backend Unit Tests)
- **Version:** 1.0.0+1

---

## Setup & Installation

### Voraussetzungen
- Flutter SDK 3.10.3+
- Dart 3.0+
- Android SDK / Xcode (für Zielplattform)
- Node.js 16+ (für Backend, separat)

### Installation Frontend

```bash
# 1. Repository klonen
cd c:\Users\matth\OneDrive\Desktop\WMC-Projekt_5a\Project\frontend

# 2. Dependencies installieren
flutter pub get

# 3. Code-Generator ausführen (falls nötig)
flutter pub run build_runner build

# 4. Analyzer ausführen
flutter analyze

# 5. App starten
flutter run -d chrome  # Web
flutter run           # Mobile (mit verbundenem Device)
```

### Projektstruktur nach Installation

```
frontend/
├── .flutter-plugins          # Auto-generated
├── pubspec.yaml              # Dependencies
├── lib/                       # Source Code
├── test/                      # Unit Tests
├── web/                       # Web Entry
├── android/                   # Android Native
├── ios/                       # iOS Native
└── build/                     # Build Output
```

### Backend Setup (separat)

```bash
cd c:\Users\matth\OneDrive\Desktop\WMC-Projekt_5a\Project\backend

# Node.js Dependencies
npm install

# Starte Server
npm start  # oder: npm run dev

# Teste Backend
npm test
```

---

## Entwickler-Guide

### Code-Konventionen

#### **Naming**
- **Screens:** `[Name]Screen` (HomeScreen, ScannerScreen)
- **Services:** `[Name]Service` (AuthService, VisionService)
- **Providers:** `[name]Provider` (appStateProvider)
- **Models:** `[Name]` (AppState, QuestProgress)
- **Methods:** camelCase (buildAnimatedRoute, addQuestResult)

#### **File Organization**
```
lib/
├── [Features grouped by type]
├── models/       ← Data & ValueTypes
├── providers/    ← State Management
├── screens/      ← UI Pages
├── services/     ← Business Logic
├── theme/        ← Styling
└── widgets/      ← Reusable Components
```

### State Management Pattern (Riverpod)

#### **Reading State**
```dart
// In ConsumerWidget/ConsumerStatefulWidget
final data = ref.watch(appStateProvider);

// Selective Watch (nur nötige Rebuilds)
final theme = ref.watch(
  appStateProvider.select((state) => state.theme)
);
```

#### **Modifying State**
```dart
// In BuildMethode (nur read)
ref.read(appStateProvider.notifier).setTheme(theme);

// In State-Änderung (write)
ref.read(appStateProvider.notifier).addQuestResult(
  label: 'Apfel',
  confidence: 0.95,
);
```

### Adding New Features

#### **Neue Theme hinzufügen**
1. `AppThemeOption` Enum erweitern
2. `app_themes.dart` → `themeFor()` Case hinzufügen
3. Settings-Screen automatisch aktualisiert

#### **Neuer Screen hinzufügen**
1. Datei in `screens/` erstellen (als ConsumerWidget)
2. Route in `AppRoutes` hinzufügen
3. Route in `main.dart` → `_buildAnimatedRoute()` hinzufügen
4. Navigation-Call in anderer Screen

#### **Neuer API-Endpoint**
1. Service in `services/` erstellen
2. HTTP-Calls via http Package
3. Error-Handling hinzufügen
4. In entsprechender State-Methode aufrufen

---

## API-Dokumentation

### Riverpod Provider

#### **appStateProvider**
```dart
/// Global State Provider für App-State Management
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(...);

/// Accesso:
/// - ref.watch(appStateProvider)              // Vollständiger State
/// - ref.watch(appStateProvider.select(...))  // Selektiver Watch
/// - ref.read(appStateProvider.notifier)      // Modifizierung
```

### AppState Methods

#### **setTheme(AppThemeOption option)**
```dart
/// Ändert das aktuelle Theme
/// Parameter: option - Eine der 5 Theme-Optionen
ref.read(appStateProvider.notifier).setTheme(AppThemeOption.dark);
```

#### **addQuestResult(String label, double confidence)**
```dart
/// Verarbeitet einen Quest-Erfolg
/// - Normalisiert Confidence (0.0-1.0)
/// - Berechnet XP (10-100)
/// - Updated Level, Streak
/// - Speichert in Quest-Log (max 200)
/// Parameter:
///   label: Name des Objekts ("Apfel", etc.)
///   confidence: Vision-Genauigkeit (0.0-1.0)
ref.read(appStateProvider.notifier).addQuestResult(
  label: 'Apfel',
  confidence: 0.92,
);
```

### AppThemes Methods

#### **themeFor(AppThemeOption option) → ThemeData**
```dart
/// Light-Mode ThemeData für Option
final theme = AppThemes.themeFor(AppThemeOption.dark);
```

#### **darkThemeFor(AppThemeOption option) → ThemeData**
```dart
/// Dark-Mode ThemeData für Option
final darkTheme = AppThemes.darkThemeFor(AppThemeOption.retroArcade);
```

#### **themeModeFor(AppThemeOption option) → ThemeMode**
```dart
/// ThemeMode für Option (light, dark, system)
final themeMode = AppThemes.themeModeFor(AppThemeOption.system);
```

### Screen Routing

#### **Named Routes**
```dart
// Navigation
Navigator.of(context).pushNamed(AppRoutes.home);

// Mit Argumenten (z.B. VisionResult)
Navigator.of(context).pushNamed(
  AppRoutes.reward,
  arguments: VisionResult(label: 'Apfel', confidence: 0.95),
);

// Replacement (z.B. nach Login)
Navigator.of(context).pushReplacementNamed(AppRoutes.home);

// Remove Until (Z.B. Logout)
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.login,
  (route) => false,
);
```

---

## Testing & Quality Assurance

### Analyzer

```bash
# Detaillierte Analyse
flutter analyze

# Mit Performance Insights
flutter analyze --pedantic
```

### Unit Tests (Backend)

```bash
# Backend Tests ausführen
cd backend
npm test

# Mit Coverage
npm run test:coverage
```

### Manual Testing Checklist

- [ ] Alle 6 Screens navigierbar
- [ ] Theme-Wechsel funktioniert (5 Designs)
- [ ] Responsive Layout auf verschiedenen Breakpoints
- [ ] Animationen smooth (60 FPS)
- [ ] QuestResult speichert und zeigt in Log
- [ ] Level/XP/Streak updated live
- [ ] Streak-Logik: Kein Doppel-Zählung
- [ ] Logout funktioniert & entfernt Daten

---

## Troubleshooting

### Common Issues

#### **Analyzer Error nach pubspec-Change**
```bash
flutter pub get
flutter pub upgrade
flutter analyze
```

#### **Hot-Reload funktioniert nicht**
```bash
# Full rebuild
flutter clean
flutter pub get
flutter run
```

#### **Theme wird nicht angewendet**
- Stelle sicher: Riverpod Watch aktiv in ConsumerWidget
- Check: `AppThemes.themeFor()` und `AppThemes.darkThemeFor()` beide definiert
- Debug: `ref.watch(appStateProvider)` um State zu inspizieren

#### **Lottie-Animation lädt nicht**
- Check: Internet-Verbindung aktiv
- Check: lottie.host URL erreichbar
- Fallback: Material-Icon wird angezeigt

---

## Performance-Tipps

### Rendering-Optimierung
- Nutze `.select()` bei Riverpod Watch um unnötige Rebuilds zu vermeiden
- ConsumerWidget statt Consumer für Performance
- Cached ColorScheme bei Theme-Wechsel

### Speicher-Optimierung
- Quest-Log maximal 200 Einträge (zu sehen in Constants)
- Alte Entries werden entfernt nach Insertion
- State ist immutable (keine unnötigen Kopien)

### Build-Optimierung
```bash
# Release Build
flutter build apk --release

# Größe reduzieren
flutter build web --release --web-renderer canvaskit
```

---

## Lizenzen & Credits

- **Flutter / Dart**: Open Source (BSD License)
- **Riverpod**: Open Source (MIT License)
- **Lottie**: Open Source (Apache 2.0)
- **Material Design**: © Google (Apache 2.0)
- **Lottie Animations**: Von lottie.host Community (Public Domain / CC0)

---

## Kontakt & Support

**Projektleiter:** [Dein Name / Team]  
**Repository:** VisionQuest (GitHub)  
**Dokumentation Version:** 1.0  
**Letztes Update:** März 2026

---

**🎉 VisionQuest ist produktionsreif und vollständig dokumentiert!**

Für Fragen zur Architektur, Implementation oder Deployment siehe entsprechende Abschnitte in dieser Dokumentation.
