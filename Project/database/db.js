const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

// Datenbank-Pfad
const DB_PATH = path.join(__dirname, 'visionquest.db');

// Datenbank-Verbindung erstellen
const db = new sqlite3.Database(DB_PATH, (err) => {
    if (err) {
        console.error('❌ Fehler beim Öffnen der Datenbank:', err.message);
    } else {
        console.log('✅ Datenbankverbindung hergestellt:', DB_PATH);
    }
});

// Schema initialisieren
const initDatabase = () => {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // Schema-Queries aufteilen und ausführen
    const queries = schema.split(';').filter(q => q.trim().length > 0);

    db.serialize(() => {
        queries.forEach((query) => {
            db.run(query, (err) => {
                if (err) {
                    console.error('❌ Schema-Fehler:', err.message);
                }
            });
        });
        console.log('✅ Datenbank-Schema initialisiert');
    });
};

// Datenbank zurücksetzen (nur für Development)
const resetDatabase = () => {
    return new Promise((resolve, reject) => {
        db.serialize(() => {
            db.run('DROP TABLE IF EXISTS achievements', handleError);
            db.run('DROP TABLE IF EXISTS user_stats', handleError);
            db.run('DROP TABLE IF EXISTS quests', handleError);
            db.run('DROP TABLE IF EXISTS users', (err) => {
                if (err) reject(err);
                else {
                    console.log('🔄 Datenbank zurückgesetzt');
                    initDatabase();
                    resolve();
                }
            });
        });
    });
};

// Helper: Error Handler
const handleError = (err) => {
    if (err) console.error('DB Error:', err.message);
};

// Datenbankverbindung schließen
const closeDatabase = () => {
    return new Promise((resolve, reject) => {
        db.close((err) => {
            if (err) {
                console.error('❌ Fehler beim Schließen der DB:', err.message);
                reject(err);
            } else {
                console.log('🔒 Datenbankverbindung geschlossen');
                resolve();
            }
        });
    });
};

// Schema-Check: Prüfen ob Tabellen existieren
const checkTables = () => {
    return new Promise((resolve, reject) => {
        db.all(`SELECT name FROM sqlite_master WHERE type='table'`, [], (err, rows) => {
            if (err) {
                reject(err);
            } else {
                const tables = rows.map(row => row.name);
                console.log('📊 Vorhandene Tabellen:', tables.join(', ') || 'keine');
                resolve(tables);
            }
        });
    });
};

// Beim ersten Import Schema initialisieren
(async () => {
    const tables = await checkTables();
    if (tables.length === 0) {
        console.log('🔨 Initialisiere Datenbank zum ersten Mal...');
        initDatabase();
    }
})();

// Exports
module.exports = {
    db,
    initDatabase,
    resetDatabase,
    closeDatabase,
    checkTables
};
