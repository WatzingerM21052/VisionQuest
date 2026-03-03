# VisionQuest - Projektdokumentation

**Projekt:** VisionQuest - AR-basierte Objekterkennungs-Quest-App  
**Sprache:** Dart/Flutter + Python (ML)  
**Version:** 2.1.0  
**Status:** ✅ Vollständig abgeschlossen (32 Steps über 4 Phasen)  
**Datum:** März 2026

---

## 📋 Inhaltsverzeichnis

1. [Projektübersicht](#projektübersicht)
2. [Architektur](#architektur)
3. [Implementierung - Phase 1-4](#implementierung)
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
- 🔄 **Daily Quest Rotation**: 6 täglich wechselnde Ziele (model-kompatibel)
- 🤖 **Dual Detection Models**: YOLO v11 + COCO-SSD mit umschaltbarem Fokus-Modus
- 🎯 **Circle-Focused Scanning**: Kreis-basierte Objekterkennung mit Context-Expansion
- 🎨 **5 Themes**: Light, Dark, System, RetroArcade, AdventureMap
- 📱 **Responsive Design**: Mobile + Tablet-unterstützt
- 🔥 **Streak-Tracking**: Konsekutive Tage mit Quests
- 📊 **Quest-Log**: Historie aller gefundenen Objekte mit Confidence-Anzeige
- ✨ **Animationen**: Multi-URL Lottie-Fallback + UI-Transitions

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
  │   ├── app_state.dart           # Root State Container + Detection Preferences
  │   ├── app_theme_option.dart    # Theme Enum (5 Varianten)
  │   ├── detection_model_option.dart  # YOLO vs COCO-SSD Enum
  │   ├── detection_focus_option.dart  # Strict vs Balanced Focus Enum
  │   ├── quest_progress.dart      # Level/XP/Streak Tracking
  │   └── quest_log_entry.dart     # Einzelner Quest-Erfolg
  │
  ├── providers/                   # Riverpod State Management
  │   └── app_state_provider.dart  # GlobalStateNotifier
  │
  ├── screens/                     # UI Screens (6 Total)
  │   ├── home_screen.dart         # Haupt-Dashboard mit Daily Quest Rotation
  │   ├── scanner_screen.dart      # Camera mit 62% Circle + Model-Status-Anzeige
  │   ├── reward_screen.dart       # Quest-Ergebnis mit Multi-URL Lottie-Fallback
  │   ├── quest_log_screen.dart    # Grid-Layout mit Confidence-Balken
  │   ├── settings_screen.dart     # Theme + Detection Model + Focus Mode
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

### Phase 4: Vision System Upgrades & Polish ✅ (11 Steps)

#### **Step 1: Logo Frame Removal**
- User-Feedback: Rahmen um Logo zu weit außen
- Iterative Anpassung → finale Entscheidung: Frame komplett entfernt
- Logo zeigt sich jetzt ohne Border-Overlay

#### **Step 2: Scanner Circle Vergrößerung**
- Problem: Kreis zu klein (200px statisch)
- Lösung: Responsive Sizing mit LayoutBuilder
- Berechnung: `shortestSide * 0.62` (clamped 240-380px)
- Dynamische Anpassung an Geräteauflösung

#### **Step 3: Daily Quest Rotation System**
Implementierung von 6 täglich wechselnden Quests:
- **Quest 0**: 📱 1 Handy scannen
- **Quest 1**: 👥 2 Personen scannen
- **Quest 2**: ☕ 1 Tasse/Flasche/Weinglas scannen
- **Quest 3**: 📚 1 Buch/Laptop scannen
- **Quest 4**: 🪑 3 Alltagsobjekte (Stuhl/Rucksack/Uhr) scannen
- **Quest 5**: 🖱️ 2 Technik-Items (Maus/Tastatur/TV) scannen

**Logik:**
```dart
int _questForDate(DateTime date) {
  final daysSinceEpoch = date.difference(DateTime(2020, 1, 1)).inDays;
  return daysSinceEpoch % 6;
}
```

**Quest-Match-Zählung:**
- Scanner-Result Labels werden gegen Quest-Targets geprüft
- Log-Entries filtern nach target-Strings
- UI zeigt Fortschritt: "2 / 3" mit Dynamic Color (incomplete/complete)

#### **Step 4: YOLO v11 Integration**
**Backend Enhancement:**
- Python-Subprocess-Ansatz für Ultralytics YOLO v11
- `yolo_detect.py` mit importlib (vermeidet Lint-Warnings)
- Environment-Variablen:
  - `VISION_YOLO_MODEL` (default: yolo11n.pt)
  - `VISION_YOLO_CONF` (default: 0.20)
  - `VISION_YOLO_IMGSZ` (default: 640)

**Detection Pipeline:**
```javascript
// visionService.js - YOLO First Approach
async function detectImage(imagePath, preferredModel, focusMode) {
  if (preferredModel === 'yolo') {
    try {
      return await detectWithYolo(imagePath, focusRegion, focusMode);
    } catch (error) {
      // Fallback to COCO-SSD
    }
  }
  return await detectWithCOCO(imagePath, focusRegion, focusMode);
}
```

**Dependencies:**
- Ultralytics 8.4.19 (Python Package)
- Python 3.13.7 (System Environment)
- Jimp 0.22.10 (Bildverarbeitung)

#### **Step 5: Circle-Intersection Detection**
**Filtering-Logik:**
- Nur Objekte im/nahe Scanner-Kreis werden erkannt
- `rectIntersectsCircle()` Algorithmus:
  ```javascript
  function rectIntersectsCircle(rect, circle) {
    const closestX = Math.max(rect.x, Math.min(circle.x, rect.x + rect.width));
    const closestY = Math.max(rect.y, Math.min(circle.y, rect.y + rect.height));
    const distX = circle.x - closestX;
    const distY = circle.y - closestY;
    return (distX * distX + distY * distY) <= (circle.radius * circle.radius);
  }
  ```

**Focus Crop mit Context-Expansion:**
- `createFocusCrop()` erstellt ROI (Region of Interest)
- **Strict Mode**: 1.35x Context-Scale (wenig Hintergrund)
- **Balanced Mode**: 1.85x Context-Scale (mehr Kontext für teilweise Objekte)
- Crop wird an YOLO/COCO weitergegeben, Koordinaten zurück-transformiert

#### **Step 6: Detection Model Switch UI**
**Settings-Screen Erweiterung:**
- Neue "Erkennungsmodus" Card mit SegmentedButton
- Optionen: **YOLO** (Standard) | **COCO-SSD**
- Labels mit Icons (Icons.precision_manufacturing / Icons.image_search)

**State Management:**
```dart
// app_state.dart
final DetectionModelOption detectionModel;  // yolo | cocoSsd

// app_state_provider.dart
void setDetectionModel(DetectionModelOption model) {
  state = state.copyWith(detectionModel: model);
}
```

**API-Integration:**
- Frontend sendet Header: `x-vision-model: yolo` oder `coco`
- Backend wählt entsprechende Pipeline

#### **Step 7: Detection Focus Switch UI**
**Settings-Screen zweiter SegmentedButton:**
- Optionen: **Strict** (Standard) | **Balanced**
- Labels: "Strikt (nur Kreis)" | "Ausgewogen (mit Kontext)"

**Auswirkung:**
- Header: `x-vision-focus: strict` oder `balanced`
- Backend nutzt 1.35x vs 1.85x contextScale
- Strict = weniger Fehlerkennungen, Balanced = bessere Erkennung bei teilweise sichtbaren Objekten

**Scanner-Status-Anzeige:**
Kleiner Chip zeigt aktive Konfiguration:
```
┌─────────────────────────┐
│ 🤖 YOLO · Strict        │
└─────────────────────────┘
```

#### **Step 8: Log Card Overflow Fix**
**Problem:** "Bottom overloaded by 20 pixels" bei längeren Object-Namen

**Vorher:**
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    childAspectRatio: 0.75,  // ← Instabil bei Theme-Font-Changes
  ),
)
```

**Nachher:**
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    mainAxisExtent: width > 700 ? 250 : 242,  // ← Feste Höhe
  ),
)
```

**Vorteile:**
- Keine Overflow-Errors mehr
- Stabil bei Theme-Wechsel
- Konsistentes Layout über alle Geräte

#### **Step 9: Multi-URL Lottie Fallback**
**Problem:** `assets.lottiefiles.com` liefert 403 Errors

**Lösung:** Dreistufige Fallback-Kette
```dart
Widget _buildLottieWithFallback({
  required String primaryUrl,
  required String secondaryUrl,
  required Widget fallback,
  bool repeat = true,
  bool reverse = false,
}) {
  return Lottie.network(
    primaryUrl,
    errorBuilder: (context, error, stackTrace) {
      return Lottie.network(
        secondaryUrl,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    },
  );
}
```

**Anwendung:**
- **Analyzing-State**: `lf20_jcikwtux.json` → `lottie.host` → CircularProgressIndicator
- **Reward-State**: `lf20_03ylnp7e.json` → `lottie.host` → TweenAnimationBuilder mit Icon

**Validierung:**
- ✅ flutter analyze: No issues
- User sieht nie eine Error-Message
- Graceful Degradation zu Material Widgets

#### **Step 10: Personalisierte Home-Begrüßung (Username)**
**Problem:** Home-Screen zeigte generischen Text (`Spieler`) statt eingeloggtem User.

**Lösung:**
- Username wird nach Login/Register aus Auth-Response persistiert (`auth_username`)
- Home-Screen lädt den gespeicherten Username aus Session/Storage
- UI-Texte personalisiert:
  - Begrüßung: `Willkommen zurück, <username>!`
  - Level-Profilkarte: Username statt statischem `Spieler`

**Fallback-Verhalten:**
- Wenn kein Username gespeichert ist, wird weiterhin `Spieler` angezeigt

#### **Step 11: Statistiken präzisiert (Gescannt vs Gefunden)**
**Problem:** Beide Stats zeigten denselben Wert, wodurch Semantik unklar war.

**Lösung:**
- **Gescannt** = alle Scan-Log-Einträge
- **Gefunden** = alle erfolgreichen Erkennungen (exklusive `nichts erkannt` und äquivalente Labels)

**Auswirkung:**
- Dashboard spiegelt jetzt realen Scan-Verlauf korrekt wider
- Fehlscans verfälschen den "Gefunden"-Wert nicht

---

## Features

### 🎮 Quest-System
**Ablauf:**
1. User öffnet Scanner-Screen mit Dynamic Circle (62% der kürzesten Bildschirmseite)
2. Model/Focus-Modus aus Settings wird geladen (YOLO/COCO + Strict/Balanced)
3. Kamera erfasst Objekt im Fokus-Kreis
4. Vision-Service (Backend) erkennt Objekt:
   - YOLO v11: Python-Subprocess mit Ultralytics
   - COCO-SSD: TensorFlow.js mit 80 Klassen
   - Circle-Intersection-Filter angewendet
5. Reward-Screen zeigt XP + Multi-URL Lottie-Animation
6. Quest-Ergebnis wird in globalem State gespeichert
7. Home-Screen aktualisiert Level/XP/Streak + Daily Quest Progress
8. Home-Screen zeigt personalisierte Begrüßung: `Willkommen zurück, <username>!`
9. Dashboard-Stats sind getrennt: `Gescannt` (alle) vs `Gefunden` (ohne `nichts erkannt`)
10. QuestLog zeigt Historie mit Confidence-Bar

**Daily Quest System:**
- 6 rotierende Quests (wechseln täglich basierend auf Datum)
- Quest-Targets sind model-kompatibel (COCO/YOLO-Klassen)
- Fortschritt wird live gezählt: gesammelte vs benötigte Objekte
- Beispiele:
  - 📱 "Scanne 1 Handy" → Target: ["cell phone"]
  - 👥 "Scanne 2 Personen" → Target: ["person"]
  - ☕ "Scanne 1 Tasse oder Flasche" → Target: ["cup", "bottle", "wine glass"]
  - 🪑 "Scanne 3 Alltagsobjekte" → Target: ["chair", "backpack", "clock"]

**XP-Berechnung:**
- Base: 10 XP (für 0% Confidence)
- Max: 100 XP (für 100% Confidence)
- Linear skaliert basierend auf Vision-Genauigkeit
- Formula: `10 + (confidence * 90)`

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

### 🤖 Detection Models & Focus Modes
**YOLO v11 (via Python Subprocess):**
- Model: yolo11n.pt (Nano-Variante, schnell)
- Confidence Threshold: 0.20
- Image Size: 640x640
- Erkennt 80+ COCO-Klassen
- Vorteil: Höhere Genauigkeit, weniger False Positives

**COCO-SSD (TensorFlow.js):**
- Model: @tensorflow-models/coco-ssd 2.2.3
- Confidence Threshold: 0.60
- Erkennt 80 Standard COCO-Klassen
- Vorteil: Rein JavaScript, kein Python nötig

**Focus Modes:**
- **Strict (1.35x Context)**: Minimal Hintergrund, nur Objekte nahe/im Kreis
- **Balanced (1.85x Context)**: Mehr Kontext für teilweise sichtbare Objekte

**Circle-Intersection Filtering:**
- Nur Predictions die den Scanner-Kreis schneiden werden akzeptiert
- Verhindert Hintergrund-Erkennungen
- Berechnung: Closest-Point Distance zwischen Bounding-Box und Kreis-Center

**User-Settings:**
Switches in Settings-Screen:
```
┌─ Erkennungsmodus ─────────────┐
│ Model:  [YOLO] [COCO-SSD]    │
│ Fokus:  [Strict] [Balanced]  │
└───────────────────────────────┘
```

### ✨ Animations
| Element | Animation | Duration | Effect |
|---------|-----------|----------|--------|
| Streak Counter | Pulse Scale | 1500ms | 1.0 ⇄ 1.15 |
| XP Progress-Bar | Glow Shadow | Static | BoxShadow mit Primary |
| Reward Success | Multi-URL Lottie + Scale | 900ms | Celebration Effect mit Fallback |
| Reward Analyzing | Multi-URL Lottie Spinner | Continuous | Loading mit Fallback |
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
- **Animations:** Lottie 3.1.2 + Flutter Built-in (Multi-URL Fallback)
- **Camera:** camera 0.11.0+2 (responsive circle 62% sizing)
- **Storage:** flutter_secure_storage 9.2.4
- **HTTP:** http 1.6.0 (mit Custom Headers für Model/Focus)

### Backend (Node.js + Python ML)
- **Server:** Node.js 16+ + Express 5.2.1
- **Database:** SQLite3 (Schema-based)
- **Image Processing:** Jimp 0.22.10 (Preprocessing, EXIF rotation)
- **ML Detection:**
  - **YOLO v11:** Ultralytics 8.4.19 (Python 3.13.7 Subprocess)
  - **COCO-SSD:** TensorFlow.js 4.11.0 + @tensorflow-models/coco-ssd 2.2.3
- **APIs:**
  - Authentication: /auth/login, /auth/register
  - Vision: /api/vision/detect (mit Model/Focus Headers)
  - Database: /api/db/* (CRUD Operations)

### Python ML Environment
- **Python:** 3.13.7 (System Environment: c:/python313/python.exe)
- **ML Framework:** Ultralytics 8.4.19 (YOLO v11)
- **Model:** yolo11n.pt (Nano, ~6MB, auto-download)
- **Integration:** Subprocess spawn mit candidate commands (py, python, python3)
- **Environment Variables:**
  - `VISION_YOLO_MODEL` - Model-Pfad (default: yolo11n.pt)
  - `VISION_YOLO_CONF` - Confidence Threshold (default: 0.20)
  - `VISION_YOLO_IMGSZ` - Input Image Size (default: 640)

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
- Node.js 16+ (für Backend)
- Python 3.13+ (für YOLO Detection, optional wenn nur COCO-SSD verwendet wird)

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

### Backend Setup

```bash
cd c:\Users\matth\OneDrive\Desktop\WMC-Projekt_5a\Project\backend

# Node.js Dependencies
npm install

# Starte Server
npm start  # oder: npm run dev

# Teste Backend
npm test
```

### Python ML Setup (für YOLO Detection)

```bash
# Python Package installieren (global oder venv)
pip install ultralytics==8.4.19

# Test YOLO Installation
python -c "from ultralytics import YOLO; print('YOLO OK')"

# Optional: Model vorher downloaden (sonst auto-download bei erstem Request)
python -c "from ultralytics import YOLO; YOLO('yolo11n.pt')"
```

**Environment Variables (Backend .env):**
```bash
# Optional: Custom YOLO Config
VISION_YOLO_MODEL=yolo11n.pt
VISION_YOLO_CONF=0.20
VISION_YOLO_IMGSZ=640
```

**Troubleshooting Python:**
- Stelle sicher Python in PATH ist: `python --version` oder `py --version`
- Backend versucht automatisch: `py`, `python`, `python3` commands
- Bei Fehler: Backend fällt automatisch auf COCO-SSD zurück

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
- Multi-URL Fallback ist implementiert (Primary → Secondary → Local Widget)
- Bei Fehlern werden Material Icons/Widgets als Fallback angezeigt
- Check: Console für 403 Errors (sollte keine geben dank Fallback)
- Optional: Lottie-Dateien lokal in `assets/` speichern und Pfade anpassen

#### **YOLO Detection funktioniert nicht**
- Check: Python installiert und in PATH (`python --version`)
- Check: Ultralytics installiert (`pip list | grep ultralytics`)
- Check: Backend Logs für Python-Subprocess Errors
- Fallback: App nutzt automatisch COCO-SSD wenn YOLO fehlschlägt
- Alternative: In Settings auf "COCO-SSD" Model umschalten

#### **Scanner erkennt Objekte nicht im Kreis**
- Stelle sicher Objekt schneidet den Kreis (nicht nur berührt)
- Wenn Objekt teilweise außerhalb: Wechsel zu "Balanced" Focus-Modus in Settings
- Strict Mode eignet sich für Objekte komplett im Kreis
- Balanced Mode erkennt auch Objekte die aus dem Kreis ragen

#### **Daily Quest wird nicht gezählt**
- Check: Gescanntes Objekt muss in Quest-Targets sein
- Beispiel: Quest "Scanne Tasse" → Model muss "cup", "bottle" oder "wine glass" erkennen
- Log-Screen zeigt erkannte Labels → vergleiche mit Quest-Anforderung
- Quest wechselt täglich → morgen ist ein neuer Quest aktiv

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
