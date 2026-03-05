const { db } = require('../../database/db');
const bcrypt = require('bcryptjs');

// ============ USERS CRUD ============

/**
 * User erstellen (Registrierung)
 */
const createUser = (username, email, password) => {
    return new Promise(async (resolve, reject) => {
        try {
            // Passwort hashen
            const passwordHash = await bcrypt.hash(password, 10);

            const sql = `
                INSERT INTO users (username, email, password_hash)
                VALUES (?, ?, ?)
            `;

            db.run(sql, [username, email, passwordHash], function (err) {
                if (err) {
                    if (err.message.includes('UNIQUE constraint')) {
                        reject(new Error('Username oder E-Mail bereits vergeben'));
                    } else {
                        reject(err);
                    }
                } else {
                    // User Stats initialisieren
                    const statsSQL = `INSERT INTO user_stats (user_id) VALUES (?)`;
                    db.run(statsSQL, [this.lastID]);

                    resolve({
                        id: this.lastID,
                        username,
                        email,
                        message: 'User erfolgreich erstellt'
                    });
                }
            });
        } catch (error) {
            reject(error);
        }
    });
};

/**
 * User per E-Mail finden (für Login)
 */
const getUserByEmail = (email) => {
    return new Promise((resolve, reject) => {
        const sql = `
            SELECT
                id,
                username,
                email,
                password_hash,
                level,
                xp,
                streak_days,
                last_quest_date,
                theme,
                role,
                is_active,
                created_at,
                updated_at
            FROM users
            WHERE email = ?
        `;

        db.get(sql, [email], (err, row) => {
            if (err) {
                reject(err);
            } else {
                resolve(row);
            }
        });
    });
};

/**
 * User per Username finden (für Login mit Username)
 */
const getUserByUsername = (username) => {
    return new Promise((resolve, reject) => {
        const sql = `
            SELECT
                id,
                username,
                email,
                password_hash,
                level,
                xp,
                streak_days,
                last_quest_date,
                theme,
                role,
                is_active,
                created_at,
                updated_at
            FROM users
            WHERE username = ?
        `;

        db.get(sql, [username], (err, row) => {
            if (err) {
                reject(err);
            } else {
                resolve(row);
            }
        });
    });
};

/**
 * User per ID finden
 */
const getUserById = (id) => {
    return new Promise((resolve, reject) => {
        const sql = `
            SELECT u.*, us.total_quests_completed, us.total_scans, us.longest_streak
            FROM users u
            LEFT JOIN user_stats us ON u.id = us.user_id
            WHERE u.id = ?
        `;

        db.get(sql, [id], (err, row) => {
            if (err) {
                reject(err);
            } else if (!row) {
                reject(new Error('User nicht gefunden'));
            } else {
                // Passwort-Hash aus Antwort entfernen
                const { password_hash, ...userWithoutPassword } = row;
                resolve(userWithoutPassword);
            }
        });
    });
};

/**
 * User updaten
 */
const updateUser = (id, updates) => {
    return new Promise((resolve, reject) => {
        const allowedFields = ['username', 'level', 'xp', 'streak_days', 'theme', 'last_quest_date', 'email', 'role', 'is_active'];
        const fields = [];
        const values = [];

        // Nur erlaubte Felder filtern
        Object.keys(updates).forEach(key => {
            if (allowedFields.includes(key)) {
                fields.push(`${key} = ?`);
                values.push(updates[key]);
            }
        });

        if (fields.length === 0) {
            reject(new Error('Keine gültigen Update-Felder'));
            return;
        }

        fields.push('updated_at = CURRENT_TIMESTAMP');
        values.push(id);

        const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;

        db.run(sql, values, function (err) {
            if (err) {
                reject(err);
            } else if (this.changes === 0) {
                reject(new Error('User nicht gefunden'));
            } else {
                resolve({ message: 'User erfolgreich aktualisiert', changes: this.changes });
            }
        });
    });
};

/**
 * Alle User holen (für Admin)
 */
const getAllUsers = () => {
    return new Promise((resolve, reject) => {
        const sql = `
            SELECT
                id,
                username,
                email,
                level,
                xp,
                streak_days,
                theme,
                role,
                is_active,
                created_at,
                updated_at
            FROM users
            ORDER BY created_at DESC
        `;

        db.all(sql, [], (err, rows) => {
            if (err) {
                reject(err);
            } else {
                const normalizedRows = (rows || []).map((row) => ({
                    id: row.ID ?? row.id,
                    username: row.USERNAME ?? row.username,
                    email: row.EMAIL ?? row.email,
                    level: row.LEVEL ?? row.level ?? 1,
                    xp: row.XP ?? row.xp ?? 0,
                    streak_days: row.STREAK_DAYS ?? row.streak_days ?? 0,
                    theme: row.THEME ?? row.theme,
                    role: row.ROLE ?? row.role ?? 'user',
                    is_active: row.IS_ACTIVE ?? row.is_active ?? 1,
                    created_at: row.CREATED_AT ?? row.created_at,
                    updated_at: row.UPDATED_AT ?? row.updated_at
                }));

                resolve(normalizedRows);
            }
        });
    });
};

/**
 * User löschen
 */

const deleteUser = (id) => {
    return new Promise((resolve, reject) => {
        const sql = `DELETE FROM users WHERE id = ?`;

        db.run(sql, [id], function (err) {
            if (err) {
                reject(err);
            } else if (this.changes === 0) {
                reject(new Error('User nicht gefunden'));
            } else {
                resolve({ message: 'User erfolgreich gelöscht', changes: this.changes });
            }
        });
    });
};

/**
 * Passwort verifizieren
 */
const verifyPassword = async (plainPassword, hashedPassword) => {
    return await bcrypt.compare(plainPassword, hashedPassword);
};

// ============ QUESTS CRUD ============

/**
 * Quest erstellen
 */
const createQuest = (userId, questData) => {
    return new Promise((resolve, reject) => {
        const { title, description, category, difficulty = 'medium', xp_reward = 100 } = questData;

        const sql = `
            INSERT INTO quests (user_id, title, description, category, difficulty, xp_reward)
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        db.run(sql, [userId, title, description, category, difficulty, xp_reward], function (err) {
            if (err) {
                reject(err);
            } else {
                resolve({
                    id: this.lastID,
                    user_id: userId,
                    title,
                    message: 'Quest erfolgreich erstellt'
                });
            }
        });
    });
};

/**
 * Alle Quests eines Users holen
 */
const getQuestsByUserId = (userId, status = null) => {
    return new Promise((resolve, reject) => {
        let sql = `SELECT * FROM quests WHERE user_id = ?`;
        const params = [userId];

        if (status) {
            sql += ` AND status = ?`;
            params.push(status);
        }

        sql += ` ORDER BY created_at DESC`;

        db.all(sql, params, (err, rows) => {
            if (err) {
                reject(err);
            } else {
                resolve(rows || []);
            }
        });
    });
};

/**
 * Quest per ID holen
 */
const getQuestById = (questId) => {
    return new Promise((resolve, reject) => {
        const sql = `SELECT * FROM quests WHERE id = ?`;

        db.get(sql, [questId], (err, row) => {
            if (err) {
                reject(err);
            } else if (!row) {
                reject(new Error('Quest nicht gefunden'));
            } else {
                resolve(row);
            }
        });
    });
};

/**
 * Quest updaten
 */
const updateQuest = (questId, updates) => {
    return new Promise((resolve, reject) => {
        const allowedFields = ['title', 'description', 'status', 'image_path', 'detected_object', 'completed_at'];
        const fields = [];
        const values = [];

        Object.keys(updates).forEach(key => {
            if (allowedFields.includes(key)) {
                fields.push(`${key} = ?`);
                values.push(updates[key]);
            }
        });

        if (fields.length === 0) {
            reject(new Error('Keine gültigen Update-Felder'));
            return;
        }

        values.push(questId);
        const sql = `UPDATE quests SET ${fields.join(', ')} WHERE id = ?`;

        db.run(sql, values, function (err) {
            if (err) {
                reject(err);
            } else if (this.changes === 0) {
                reject(new Error('Quest nicht gefunden'));
            } else {
                resolve({ message: 'Quest erfolgreich aktualisiert', changes: this.changes });
            }
        });
    });
};

/**
 * Quest abschließen
 */
const completeQuest = (questId, userId, detectedObject = null) => {
    return new Promise(async (resolve, reject) => {
        try {
            // Quest holen
            const quest = await getQuestById(questId);

            if (quest.user_id !== userId) {
                reject(new Error('Nicht autorisiert'));
                return;
            }

            if (quest.status === 'completed') {
                reject(new Error('Quest bereits abgeschlossen'));
                return;
            }

            // Quest als abgeschlossen markieren
            await updateQuest(questId, {
                status: 'completed',
                completed_at: new Date().toISOString(),
                detected_object: detectedObject
            });

            // User XP und Stats updaten
            const user = await getUserById(userId);
            const newXP = user.xp + quest.xp_reward;
            const newLevel = Math.floor(newXP / 1000) + 1; // Alle 1000 XP = 1 Level

            await updateUser(userId, {
                xp: newXP,
                level: newLevel
            });

            // Stats updaten
            const statsSql = `
                UPDATE user_stats 
                SET total_quests_completed = total_quests_completed + 1,
                    updated_at = CURRENT_TIMESTAMP
                WHERE user_id = ?
            `;
            db.run(statsSql, [userId]);

            resolve({
                message: 'Quest abgeschlossen!',
                xp_earned: quest.xp_reward,
                new_xp: newXP,
                new_level: newLevel
            });

        } catch (error) {
            reject(error);
        }
    });
};

/**
 * Quest löschen
 */
const deleteQuest = (questId) => {
    return new Promise((resolve, reject) => {
        const sql = `DELETE FROM quests WHERE id = ?`;

        db.run(sql, [questId], function (err) {
            if (err) {
                reject(err);
            } else if (this.changes === 0) {
                reject(new Error('Quest nicht gefunden'));
            } else {
                resolve({ message: 'Quest erfolgreich gelöscht', changes: this.changes });
            }
        });
    });
};

// ============ USER STATS ============

/**
 * User Stats updaten
 */
const updateUserStats = (userId, updates) => {
    return new Promise((resolve, reject) => {
        const allowedFields = ['total_scans', 'longest_streak', 'favorite_category'];
        const fields = [];
        const values = [];

        Object.keys(updates).forEach(key => {
            if (allowedFields.includes(key)) {
                fields.push(`${key} = ?`);
                values.push(updates[key]);
            }
        });

        if (fields.length === 0) {
            reject(new Error('Keine gültigen Update-Felder'));
            return;
        }

        fields.push('updated_at = CURRENT_TIMESTAMP');
        values.push(userId);

        const sql = `UPDATE user_stats SET ${fields.join(', ')} WHERE user_id = ?`;

        db.run(sql, values, function (err) {
            if (err) {
                reject(err);
            } else {
                resolve({ message: 'Stats aktualisiert', changes: this.changes });
            }
        });
    });
};

module.exports = {
    // Users
    createUser,
    getUserByEmail,
    getUserByUsername,
    getUserById,
    getAllUsers,
    updateUser,
    deleteUser,
    verifyPassword,

    // Quests
    createQuest,
    getQuestsByUserId,
    getQuestById,
    updateQuest,
    completeQuest,
    deleteQuest,

    // Stats
    updateUserStats
};
