# VisionQuest - Augmented Reality Quest Experience

Ein Flutter-Frontend mit Express-Backend und YOLO ML-Integration für ein interaktives Augmented Reality Objekt-Scanning-Spiel.

## ✨ Features

- 🎮 **Quest-System**: Objekte scannen, XP verdienen, Level aufsteigen
- 🔄 **Daily Quests**: 6 täglich wechselnde Aufgaben mit model-kompatiblen Zielen
- 🤖 **Dual ML Models**: YOLO v11 (Python) + COCO-SSD (TensorFlow.js) umschaltbar
- 🎯 **Circle-Focused Detection**: Kreis-basierte Objekterkennung mit Strict/Balanced Modi
- 🎨 **5 Themes**: Light, Dark, System, RetroArcade, AdventureMap
- 📱 **Responsive Design**: Mobile, Tablet, Desktop
- 🔥 **Streak-Tracking**: Konsekutive Tage mit mindestens 1 Quest
- 📊 **Quest-Log**: Historie aller gescannten Objekte mit Confidence-Anzeige
- ✨ **Animations**: Multi-URL Lottie-Fallback + UI-Transitions

## 📁 Projektstruktur

```
Project/
├── frontend/          # Flutter App (iOS, Android, Web, etc.)
│   ├── lib/          # Dart Source Code
│   ├── pubspec.yaml  # Flutter Dependencies
│   └── ...
└── backend/          # Express.js Server
    ├── server.js     # Main Server Datei
    ├── package.json  # Node Dependencies
    ├── .env          # Environment Variablen
    └── node_modules/ # Dependencies
```

## 🚀 Schnellstart

### Backend starten

```bash
cd backend
npm install          # Falls noch nicht getan
npm start           # oder: npm run dev
```

Der Backend läuft dann auf: `http://localhost:5000`

**Verfügbare Endpoints:**
- `POST /api/auth/register` - Benutzer-Registrierung
- `POST /api/auth/login` - Benutzer-Login
- `GET /api/users/me` - User-Profil abrufen (Auth)
- `POST /api/vision/detect` - Objekterkennung mit YOLO/COCO-SSD (Auth)
- `GET /api/quests` - Quest-Liste abrufen (Auth)
- `POST /api/quests/:id/complete` - Quest abschließen (Auth)
- `PUT /api/stats` - User-Stats aktualisieren (Auth)

Vollständige API-Dokumentation: siehe `backend/API_DOCS.md`

### Frontend starten

```bash
cd frontend
flutter pub get     # Falls noch nicht getan
flutter run         # Starte die App
```

Wähle eine Platform (web/android/ios/windows/macos):
- **Web:** `flutter run -d chrome`
- **Android:** `flutter run -d emulator-5554` (oder physical device)
- **iOS:** `flutter run -d iphone` (nur auf macOS)

## 🔗 Verbindung Frontend-Backend

Die Verbindung wird automatisch beim App-Start getestet. Der Benutzer sieht:
- ✅ **Grüner Status**: Backend ist erreichbar
- ❌ **Roter Status**: Backend nicht erreichbar (stelle sicher, dass der Backend auf Port 5000 läuft)

Der "Verbindung testen" Button ermöglicht jederzeit einen erneuten Test.

### Debugging

**Falls die Verbindung fehlschlägt:**

1. **Backend läuft nicht?**
   ```bash
   cd backend
   npm start
   ```

2. **Port 5000 ist belegt?**
   Ändere den Port in `backend/.env`:
   ```
   PORT=3000
   ```
   Und in `frontend/lib/main.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:3000/api';
   ```

3. **Simulator/Emulator erreicht Localhost nicht?**
   - Verwende stattdessen `10.0.2.2` (Android) oder `host.docker.internal` (allgemein)
   - Oder starte Frontend auf `flutter run` (Web) für einferes Debugging

## 📦 Dependencies

### Frontend (Flutter)
- **flutter_riverpod** ^2.6.1 - State Management
- **camera** ^0.11.0+2 - Kamera-Zugriff
- **http** ^1.6.0 - HTTP Client für API Requests
- **lottie** ^3.1.2 - Animationen mit Multi-URL Fallback
- **flutter_secure_storage** ^9.2.4 - Sichere Token-Speicherung
- **intl** - Datum/Zeit-Formatierung

### Backend (Node.js)
- **express** ^5.2.1 - Web Framework
- **cors** - Cross-Origin Resource Sharing
- **dotenv** - Umgebungsvariablen
- **multer** ^1.4.5-lts.1 - File Upload Handling
- **jsonwebtoken** ^9.0.2 - JWT Authentication
- **bcrypt** ^5.1.1 - Password Hashing
- **sqlite3** ^5.1.7 - Database
- **jimp** ^0.22.10 - Image Processing
- **@tensorflow/tfjs-node** ^4.11.0 - TensorFlow.js Backend
- **@tensorflow-models/coco-ssd** ^2.2.3 - COCO-SSD Model

### Machine Learning (Python)
- **Python** 3.13+ - Runtime Environment
- **ultralytics** 8.4.19 - YOLO v11 Framework

## 🤖 YOLO Setup (Optional, für bessere Erkennung)

YOLO bietet höhere Erkennungsgenauigkeit. Wenn Python nicht verfügbar ist, nutzt die App automatisch COCO-SSD als Fallback.

```bash
# Python 3.13+ installieren (falls nicht vorhanden)
# Download von python.org

# Ultralytics Package installieren
pip install ultralytics==8.4.19

# Test Installation
python -c "from ultralytics import YOLO; print('YOLO OK')"

# Optional: Model vorher downloaden (6MB)
python -c "from ultralytics import YOLO; YOLO('yolo11n.pt')"
```

**Environment Variables (Backend .env):**
```bash
# Optional: Custom YOLO Config
VISION_YOLO_MODEL=yolo11n.pt
VISION_YOLO_CONF=0.20
VISION_YOLO_IMGSZ=640
```

## 📝 Features im Detail

### Detection Models
- **YOLO v11**: Höhere Genauigkeit, erfordert Python
- **COCO-SSD**: Schnell, rein JavaScript, kein Python nötig
- **Umschaltbar**: In Settings zwischen Modellen wechseln

### Focus Modes
- **Strict (1.35x Context)**: Minimal Hintergrund, nur Objekte nahe Circle
- **Balanced (1.85x Context)**: Mehr Kontext für teilweise sichtbare Objekte

### Daily Quest System
6 rotierende Quests (täglich wechselnd):
- 📱 1 Handy scannen
- 👥 2 Personen scannen
- ☕ 1 Tasse/Flasche/Glas scannen
- 📚 1 Buch/Laptop scannen
- 🪑 3 Alltagsobjekte scannen
- 🖱️ 2 Technik-Items scannen

### Scanner Features
- Responsive Circle (62% der kürzesten Bildschirmseite)
- Live-Anzeige des aktiven Models/Fokus
- Circle-Intersection Filtering (nur Objekte im Kreis)
- Multi-URL Lottie-Fallback für Animationen

## 👨‍💻 Entwicklung

**Hot Reload (Flutter):**
- Speichern (Ctrl+S): Code-Änderungen sichtbar ohne App-Neustart
- Hot Restart (Shift+Ctrl+R): State wird zurückgesetzt

**Backend im Dev-Modus:**
```bash
npm run dev   # Falls nodemon installiert
```

**Testing:**
```bash
# Backend Unit Tests
cd backend
npm test

# Flutter Analyzer
cd frontend
flutter analyze
```

## 📧 Support & Dokumentation

Bei Fragen oder Problemen:
- **Vollständige Dokumentation**: siehe `docs/Gesamtprotokoll.md`
- **API-Dokumentation**: siehe `backend/API_DOCS.md`
- **Frontend Logs**: Browser DevTools Console
- **Backend Logs**: Terminal wo `npm start` aktiv ist

---

**Projekt erstellt:** Februar 2026  
**Letzte Aktualisierung:** März 2026  
**Version:** 2.0.0
