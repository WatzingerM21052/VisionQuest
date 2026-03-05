const sqlite3 = require('sqlite3');
const bcrypt = require('bcryptjs');
const path = require('path');

const dbPath = path.join(__dirname, 'visionquest.db');
const db = new sqlite3.Database(dbPath);

const username = 'admin';
const email = 'admin@gmail.com';
const password = 'htlgkr';

async function createAdminUser() {
    try {
        // Passwort hashen (gleich wie in dbService.js)
        const passwordHash = await bcrypt.hash(password, 10);

        // Zuerst prüfen ob User schon existiert
        db.get(
            'SELECT id, username, email, role FROM users WHERE username = ? OR email = ?',
            [username, email],
            (err, row) => {
                if (err) {
                    console.error('❌ Fehler beim Prüfen:', err.message);
                    db.close();
                    process.exit(1);
                }

                if (row) {
                    console.log('⚠️  User existiert bereits:');
                    console.log(`   ID: ${row.id}`);
                    console.log(`   Username: ${row.username}`);
                    console.log(`   Email: ${row.email}`);
                    console.log(`   Role: ${row.role}`);
                    console.log('\n💡 Tipp: Verwende "node makeAdmin.js" um einen existierenden User zum Admin zu machen.');
                    db.close();
                    process.exit(0);
                }

                // User erstellen mit admin role
                const sql = `
          INSERT INTO users (username, email, password_hash, role, level, xp)
          VALUES (?, ?, ?, 'admin', 1, 0)
        `;

                db.run(sql, [username, email, passwordHash], function (err) {
                    if (err) {
                        console.error('❌ Fehler beim Erstellen:', err.message);
                        db.close();
                        process.exit(1);
                    }

                    const userId = this.lastID;

                    // User Stats initialisieren
                    const statsSQL = `INSERT INTO user_stats (user_id) VALUES (?)`;
                    db.run(statsSQL, [userId], (err) => {
                        if (err) {
                            console.warn('⚠️  Warnung: Konnte user_stats nicht erstellen:', err.message);
                        }

                        console.log('\n✅ Admin-User erfolgreich erstellt!');
                        console.log('═══════════════════════════════════════');
                        console.log(`   ID:       ${userId}`);
                        console.log(`   Username: ${username}`);
                        console.log(`   Email:    ${email}`);
                        console.log(`   Password: ${password}`);
                        console.log(`   Role:     admin`);
                        console.log('═══════════════════════════════════════\n');

                        db.close();
                        process.exit(0);
                    });
                });
            }
        );
    } catch (error) {
        console.error('❌ Fehler:', error.message);
        db.close();
        process.exit(1);
    }
}

createAdminUser();
