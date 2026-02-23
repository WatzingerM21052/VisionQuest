# VisionQuest - Augmented Reality Experience

Ein Flutter-Frontend mit Express-Backend Integration für ein Augmented Reality Erlebnis.

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
- `GET /api/health` - Health Check
- `GET /api/test` - Test GET Request
- `POST /api/test` - Test POST Request

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
- **http** - HTTP Client für API Requests
- **provider** - State Management

### Backend (Node.js)
- **express** - Web Framework
- **cors** - Cross-Origin Resource Sharing
- **dotenv** - Umgebungsvariablen

## 📝 Nächste Schritte

- [ ] Weitere API Endpoints implementieren
- [ ] Authentifizierung/JWT hinzufügen
- [ ] Datenbank-Integration
- [ ] Real-time Kommunikation (WebSocket)
- [ ] Error Handling verbessern
- [ ] Tests schreiben

## 👨‍💻 Entwicklung

**Hot Reload (Flutter):**
- Speichern (Ctrl+S): Code-Änderungen sichtbar ohne App-Neustart
- Hot Restart (Shift+Ctrl+R): State wird zurückgesetzt

**Backend im Dev-Modus:**
```bash
npm run dev   # Falls nodemon installiert
```

## 📧 Support

Bei Fragen oder Problemen mit der Verbindung die Logs checken:
- **Frontend**: Konsole im Running App
- **Backend**: Terminal wo `npm start` aktiv ist

---

**Projekt erstellt:** Februar 2026
**Version:** 1.0.0
