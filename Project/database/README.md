# VisionQuest Datenbank

## 📊 Schema-Übersicht

### **Users** - Benutzer-Tabelle
- `id`: Primary Key
- `username`: Eindeutiger Benutzername
- `email`: E-Mail-Adresse (eindeutig)
- `password_hash`: Verschlüsseltes Passwort (bcrypt)
- `level`: Spieler-Level (Standard: 1)
- `xp`: Experience Points (Standard: 0)
- `streak_days`: Anzahl aufeinanderfolgender Tage
- `last_quest_date`: Letztes Quest-Datum
- `theme`: UI-Theme (Standard: 'default')
- `created_at`, `updated_at`: Zeitstempel

### **Quests** - Aufgaben-Tabelle
- `id`: Primary Key
- `user_id`: Foreign Key → users(id)
- `title`: Quest-Titel
- `description`: Beschreibung
- `category`: Kategorie (z.B. "Natur", "Stadt")
- `difficulty`: Schwierigkeit ('easy', 'medium', 'hard')
- `xp_reward`: XP-Belohnung (Standard: 100)
- `status`: Status ('active', 'completed', 'failed')
- `image_path`: Pfad zum gescannten Bild
- `detected_object`: Erkanntes Objekt
- `completed_at`: Abschluss-Zeitstempel
- `created_at`: Erstellungs-Zeitstempel

### **User_Stats** - Statistiken
- `id`: Primary Key
- `user_id`: Foreign Key → users(id)
- `total_quests_completed`: Anzahl abgeschlossener Quests
- `total_scans`: Anzahl Scans
- `longest_streak`: Längste Streak
- `favorite_category`: Lieblingskategorie
- `updated_at`: Zeitstempel

### **Achievements** - Errungenschaften
- `id`: Primary Key
- `user_id`: Foreign Key → users(id)
- `achievement_name`: Name der Errungenschaft
- `achievement_description`: Beschreibung
- `unlocked_at`: Freischalt-Zeitstempel

## 🔧 Verwendung

### Datenbank initialisieren
```javascript
const { initDatabase, checkTables } = require('./db');

// Tables checken
checkTables().then(tables => {
  console.log('Tabellen:', tables);
});

// Manuell initialisieren
initDatabase();
```

### Datenbank zurücksetzen (Development nur!)
```javascript
const { resetDatabase } = require('./db');

resetDatabase().then(() => {
  console.log('Datenbank wurde zurückgesetzt');
});
```

## 📝 Hinweise

- Die Datenbank wird automatisch initialisiert beim ersten Import von `db.js`
- Passwörter werden mit **bcrypt** gehashed (Salt Rounds: 10)
- User Stats werden automatisch bei User-Erstellung angelegt
- CASCADE DELETE: Bei User-Löschung werden alle zugehörigen Quests, Stats und Achievements gelöscht
- Indexes optimieren Queries auf `email`, `username`, `user_id` und `status`

## 🗄️ SQLite

Die Datenbank ist eine **SQLite**-Datei: `visionquest.db`

### Vorteile:
- ✅ Keine separate Datenbank-Installation nötig
- ✅ Datei-basiert, leicht zu sichern
- ✅ Perfekt für Entwicklung und kleine bis mittlere Apps
- ✅ Schnell und zuverlässig

### Datenbank-Datei ansehen:
```bash
# Mit SQLite CLI
sqlite3 visionquest.db

# Tabellen anzeigen
.tables

# Schema anzeigen
.schema users

# Query ausführen
SELECT * FROM users;
```

## 🔐 Sicherheit

- Passwörter werden **niemals** im Klartext gespeichert
- JWT-Tokens für Authentication
- Prepared Statements verhindern SQL-Injection
- Foreign Keys erzwingen Datenintegrität

---

**Schema-Version:** 1.0  
**Erstellt:** 25.02.2026
