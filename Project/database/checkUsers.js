const sqlite3 = require('sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, 'visionquest.db');
const db = new sqlite3.Database(dbPath);

db.all("SELECT ID, USERNAME, EMAIL, ROLE FROM users ORDER BY created_at DESC", (err, rows) => {
    if (err) {
        console.error('Fehler:', err);
        process.exit(1);
    }

    console.log('\n=== ALLE USER ===\n');
    rows.forEach(user => {
        console.log(`ID: ${user.ID} | User: ${user.USERNAME} | Email: ${user.EMAIL} | Role: ${user.ROLE || 'user'}`);
    });
    console.log('');

    db.close();
});
