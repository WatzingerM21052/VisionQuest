# VisionQuest - Zukünftige Features & Aufgaben

## Phase 5 - Admin & Authentication Improvements

### 🔑 Authentication Enhancement
- [ ] Login mit Email **ODER** Username (nicht nur Email)
  - Backend: `POST /api/auth/login` erweitern um username-basierte Abfrage
  - Frontend: Login-Screen beide Optionen ermöglichen + UI-Feedback
  - Validierungslogik: User nach Email oder Username suchen

### 🛡️ Admin-Funktionalität
- [ ] Admin-Panel zum Verwalten von Benutzern
  - [ ] Benutzer löschen (mit Bestätigung)
  - [ ] Benutzer bearbeiten (Email, Username, Level, XP)
  - [ ] Benutzer-Übersichtsliste mit Filter/Suche
  - Backend-Endpoints:
    - `GET /api/admin/users` - Liste aller User
    - `DELETE /api/admin/users/:id` - User löschen
    - `PUT /api/admin/users/:id` - User bearbeiten
  - New Role-Field in DB: `role` (user | admin)
  - Admin-Check-Middleware für sensitive Endpoints
  - Frontend: Admin-Screen mit Zugriffskontrolle

### 📋 Database Schema Extension
- [ ] `users` Tabelle:
  - Neues Feld: `role` (VARCHAR, default: 'user')
  - Neues Feld: `is_active` (BOOLEAN, default: 1) - für Soft-Deletes optional

### 🎯 Admin UI
- [ ] Settings-Screen: Admin-Panel Link (nur für Admins sichtbar)
- [ ] Separate Admin-Screen mit:
  - User-Management Tab
  - Statistiken-Übersicht
  - Moderation-Tools

---

**Notiert am:** März 3, 2026  
**Status:** Geplant für Phase 5


Anderes:
Username wird irgendwie nur in der Session gespeichert, in der er angelegt wird, aber sonst nicht mehr. Nach anmelden beim erstellen wird er angezeigt ansonsten "Spieler"