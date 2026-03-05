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
  - [ ] Statistiken-Übersicht (optional - Phase 6)
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

---

**Status:** ✅ Phase 5 vollständig erledigt  
**Datum:** März 5, 2026

---

## Nächste Schritte (Zukünftig - Phase 6)
- [ ] Admin-Statistiken Dashboard (User-Aktivität, Top-Leistungen)
- [ ] Moderation-Tools (User-Berichte, Suspensionen)
- [ ] Transaktionslogger für Admin-Aktionen
- [ ] Export-Funktionen (CSV, JSON)