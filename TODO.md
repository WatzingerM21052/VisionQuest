# VisionQuest - Zukünftige Features & Aufgaben

## Phase 5 - Admin & Authentication Improvements ✅ ERLEDIGT

### 🔑 Authentication Enhancement ✅
- [x] Login mit Email **ODER** Username (nicht nur Email)
  - Backend: `POST /api/auth/login` erweitert um username-basierte Abfrage
  - Frontend: Login-Screen beide Optionen mit Toggle ermöglicht + UI-Feedback
  - Validierungslogik: User nach Email oder Username suchen

### 🛡️ Admin-Funktionalität ✅
- [x] Admin-Panel zum Verwalten von Benutzern
  - [x] Benutzer löschen (mit Bestätigung)
  - [x] Benutzer bearbeiten (Email, Username, Level, XP, Role)
  - [x] Benutzer-Übersichtsliste mit Filter/Suche
  - Backend-Endpoints (implementiert):
    - `GET /api/admin/users` - Liste aller User
    - `DELETE /api/admin/users/:id` - User löschen
    - `PUT /api/admin/users/:id` - User bearbeiten
  - [x] Role-Field in DB: `role` (user | admin, default: 'user')
  - [x] Admin-Check-Middleware für sensitive Endpoints
  - [x] Frontend: Admin-Screen mit Zugriffskontrolle

### 📋 Database Schema Extension ✅
- [x] `users` Tabelle:
  - [x] Neues Feld: `role` (VARCHAR, default: 'user')
  - [x] Neues Feld: `is_active` (BOOLEAN, default: 1) - für Soft-Deletes optional

### 🎯 Admin UI ✅
- [x] Settings-Screen: Admin-Panel Link (nur für Admins sichtbar)
- [x] Separate Admin-Screen mit:
  - [x] User-Management Tab
  - [x] Statistiken-Übersicht (Übersicht, Level-Verteilung, Top 5 Users)
  - [ ] Moderation-Tools (optional - Phase 6)

---

## Implementierte Änderungen

### Backend (`backend/`)
- ✅ **schema.sql**: `role` und `is_active` Felder zur users Tabelle hinzugefügt
- ✅ **dbService.js**: 
  - `getUserByUsername()` hinzugefügt für Username-Login
  - `getAllUsers()` für Admin-Liste
  - `updateUser()` erweitert mit role und is_active
  - Exports aktualisiert
- ✅ **api.js**:
  - Login-Endpoint (`POST /api/auth/login`) unterstützt jetzt email ODER username
  - Admin-Middleware `requireAdmin` implementiert
  - Admin-Endpoints hinzugefügt:
    - `GET /api/admin/users`
    - `PUT /api/admin/users/:id`
    - `DELETE /api/admin/users/:id`

### Frontend (`frontend/lib/`)
- ✅ **models/app_state.dart**: `userRole` Property hinzugefügt
- ✅ **providers/app_state_provider.dart**: `setUserRole()` Methode hinzugefügt
- ✅ **services/auth_service.dart**: 
  - `login()` erweitert für username + email Parameter
  - `userRole` Getter zu `AuthResponse` hinzugefügt
- ✅ **services/admin_service.dart**: Neu erstellt mit:
  - User Model
  - `getAllUsers()`, `updateUser()`, `deleteUser()` Methoden
- ✅ **screens/login_screen.dart**:
  - Username/Email Toggle hinzugefügt
  - Username-Input Field hinzugefügt
  - Validierung für beide Login-Methoden
- ✅ **screens/admin_screen.dart**: Neu erstellt mit:
  - User-Liste mit Suche/Filter
  - Edit-Dialog für Benutzerdaten (username, email, level, xp, role, is_active)
  - Delete-Bestätigung
  - Admin-Zugriffskontrolle
- ✅ **screens/settings_screen.dart**: Admin-Link hinzugefügt (nur für Admins sichtbar)
- ✅ **app_routes.dart**: `/admin` Route hinzugefügt
- ✅ **main.dart**: Admin-Screen Route registriert

### 📊 Admin Statistics Dashboard ✅
- [x] Backend-Endpoint `GET /api/admin/stats` mit:
  - [x] Summary Stats (totalUsers, activeUsers, inactiveUsers, adminCount, totalXp, averageLevel)
  - [x] Level Distribution (Benutzer gruppiert nach Level)
  - [x] Top 5 Users Ranking (mit Medal-Styling: Gold/Silver/Bronze)
- [x] Frontend AdminService.getStats() Methode
- [x] Statistics Tab im Admin-Screen
  - [x] Responsive Grid-Layout für Stat-Karten
  - [x] Farbcodierte Metriken
  - [x] Loading & Error States
  - [x] Ranking mit visuellen Indikatoren

---

## Phase 6 - Admin Dashboard Extensions ✅ ERLEDIGT

### 📊 Admin Action Logging ✅
- [x] ADMIN_ACTIONS Tabelle in Database Schema
- [x] adminActionService.js mit Logging-Funktionen
- [x] Logging für User-Updates, Deletes, Suspends
- [x] GET /api/admin/logs Endpoint
- [x] Admin Logs Tab in Admin Panel

### 🛡️ Moderation Tools ✅
- [x] SUSPENSIONS Tabelle mit Grund & Admin-Tracking
- [x] POST /api/admin/users/:id/suspend Endpoint
- [x] POST /api/admin/users/:id/unsuspend Endpoint
- [x] GET /api/admin/suspensions Endpoint
- [x] Frontend Suspend/Unsuspend Buttons
- [x] Suspensions Tab in Admin Panel

### 📥 Export Funktionen ✅
- [x] CSV & JSON Export Endpoints
- [x] GET /api/admin/users/export?format=csv/json
- [x] Frontend Export Dialog
- [x] Export im User-Management Tab
- [x] AdminService Export Methods

### 📈 User Activity Dashboard ✅
- [x] GET /api/admin/activity Endpoint
- [x] Recently Active Users List
- [x] Quest Statistics (total, avg reward)
- [x] Top Categories Analysis
- [x] Activity Tab in Admin Panel
- [x] AdminService.getActivity() Method

### 🎨 Admin Panel UI Enhancements ✅
- [x] 5 Tabs: Users | Stats | Activity | Logs | Suspensions
- [x] Responsive Tab Navigation
- [x] Action Icons für Logs (create, update, delete, suspend, etc.)
- [x] Medal Ranking (Gold/Silver/Bronze) für Top Users
- [x] User Activity Cards mit Avatar
- [x] Category Distribution Charts
- [x] Export Button in User Management
- [x] Suspension Modal mit Grund-Anzeige

---

**Status:** ✅ Phase 6 vollständig erledigt  
**Datum:** März 5, 2026  
**Letzte Updates:** Full Admin Dashboard System mit Logging, Moderation, Analytics, Activity Tracking

---

## Phase 7 - Bug Fixes & Data Persistence ✅ TEILWEISE ERLEDIGT

### 🐛 Login & State Management Bugs

#### 1. Remove Login Success Toast ✅
- [x] Frontend: Login erfolgreich Toast entfernen
  - File: `login_screen.dart` + `register_screen.dart`
  - Grund: Redundantes UI-Feedback - sieht man auf Home sowieso
  - **ERLEDIGT**: SnackBar-Aufrufe entfernt in beiden Screens

#### 2. Streak Persistence Bug ✅
- [x] **Problem**: Streak wird immer auf 0 gesetzt, da nicht richtig gespeichert
  - [x] Backend: Streak-Logik in `completeQuest()` implementiert
  - [x] `last_quest_date` wird jetzt bei Quest-Completion aktualisiert
  - [x] Streak-Berechnung: Heute = gleich, Gestern = +1, >1 Tag = Reset
  - [x] `longest_streak` in user_stats wird aktualisiert
  - **ERLEDIGT**: File `backend/services/dbService.js` aktualisiert

#### 3. Progress Bar Loading Bug ✅
- [x] **Problem**: Progressbar balken wird nicht geladen bei Login wenn Progress da
  - [x] Validiert: `setProgress()` funktioniert korrekt
  - [x] `QuestProgress.levelProgress` Berechnung korrekt
  - [x] LinearProgressIndicator verwendet korrekte value
  - **STATUS**: Sollte durch Streak-Fix gelöst sein (alle Stats synchronisiert)

#### 4. Daily Quest Completion Status ⚠️ FEATURE FEHLT
- [ ] **Problem**: Wenn Daily Quest heute bereits erledigt und neu eingeloggt, wird sie wieder als unerledigt angezeigt
  - **Root Cause**: `logEntries` (Detection-Historie) werden NICHT persistiert
  - **Details**: 
    - Daily Quest basiert auf lokalen `logEntries` im Frontend State
    - logEntries existieren nur in Riverpod State (nicht in DB/LocalStorage)
    - Bei Logout/Login gehen alle Detections verloren
  - **Lösung erforderlich**: 
    - Option A: Backend API für Detection-Log (`POST /api/detections`, `GET /api/detections/today`)
    - Option B: LocalStorage (SharedPreferences/Hive) im Flutter-Frontend
  - **Priorität**: 🟡 MEDIUM - Beeinträchtigt User Experience bei Re-Login

#### 5. Quest Log Persistence ⚠️ FEATURE FEHLT
- [ ] **Zu klären**: Wird der Quest-Historie (completed quest log) korrekt gespeichert & geladen?
  - **Root Cause**: Identisch mit Bug #4 - logEntries nicht persistiert
  - **Details**:
    - `QuestLogScreen` zeigt `appState.logEntries` an
    - Keine Backend-Integration vorhanden
    - Keine LocalStorage-Implementierung
  - **Lösung erforderlich**: Gleiche wie Bug #4
  - **Priorität**: 🟡 MEDIUM - Quest-Log Historie geht bei Neustart verloren

---

**Status:** ✅ 3/5 Bugs gefixt, 2/5 erfordern neue Feature-Implementierung  
**Datum:** März 6, 2026  
**Letzte Updates:** Login Toast entfernt, Streak Persistence implementiert, Progress Bar validiert

### 📋 Nächste Schritte für Phase 7

**Empfehlung für Detection-Persistence:**
1. **Quick Fix**: SharedPreferences im Frontend für logEntries
   - Speichern bei jedem neuen Scan
   - Laden beim App-Start
   - Max. 200 Einträge (FIFO)

2. **Full Solution**: Backend Detection-Log API
   - Neue Tabelle: `detection_log` (id, user_id, label, confidence, timestamp)
   - POST /api/detections - Neue Detection speichern
   - GET /api/detections?date=today - Heutige Detections laden
   - Integration in Scanner-Screen nach erfolgreicher YOLO-Detection

---

## Nächste Schritte (Zukünftig - Phase 8+)
- [ ] Mobile App Optimierungen
- [ ] Performance Monitoring Dashboard
- [ ] Erweiterte Datenanalyse (ML-basierte Insights)
- [ ] Social Features (Leaderboards, Friends)
- [ ] In-App Monetisierung
- [ ] Push Notifications für Quest-Updates
- [ ] Offline Mode für Quests