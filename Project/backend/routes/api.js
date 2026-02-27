const express = require('express');
const router = express.Router();
const dbService = require('../services/dbService');
const jwt = require('jsonwebtoken');

// JWT Secret (sollte in .env stehen)
const JWT_SECRET = process.env.JWT_SECRET || 'dein_geheimes_jwt_secret_key';

// ============ AUTH MIDDLEWARE ============

/**
 * Middleware: JWT Token verifizieren mit detailliertem Error-Handling
 */
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({
            success: false,
            message: 'Nicht autorisiert - kein Token vorhanden',
            code: 'NO_TOKEN'
        });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            // Unterscheidung zwischen Token-Fehlern
            if (err.name === 'TokenExpiredError') {
                return res.status(401).json({
                    success: false,
                    message: 'Token abgelaufen',
                    code: 'TOKEN_EXPIRED',
                    expiredAt: err.expiredAt
                });
            }
            
            if (err.name === 'JsonWebTokenError') {
                return res.status(403).json({
                    success: false,
                    message: 'Token ungültig',
                    code: 'INVALID_TOKEN'
                });
            }

            return res.status(403).json({
                success: false,
                message: 'Token-Validierung fehlgeschlagen',
                code: 'TOKEN_INVALID'
            });
        }
        req.user = user; // User-Daten aus Token speichern
        next();
    });
};

// ============ AUTH ROUTES ============

/**
 * POST /api/auth/register
 * User-Registrierung
 */
router.post('/auth/register', async (req, res) => {
    try {
        const { username, email, password } = req.body;

        // Validierung
        if (!username || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Username, E-Mail und Passwort sind erforderlich'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Passwort muss mindestens 6 Zeichen lang sein'
            });
        }

        const result = await dbService.createUser(username, email, password);

        // JWT Token erstellen
        const token = jwt.sign(
            { userId: result.id, username: result.username },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            success: true,
            message: 'Registrierung erfolgreich',
            data: {
                user: result,
                token
            }
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * POST /api/auth/login
 * User-Login
 */
router.post('/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'E-Mail und Passwort sind erforderlich'
            });
        }

        const user = await dbService.getUserByEmail(email);

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Ungültige E-Mail oder Passwort'
            });
        }

        const isPasswordValid = await dbService.verifyPassword(password, user.password_hash);

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Ungültige E-Mail oder Passwort'
            });
        }

        // JWT Token erstellen
        const token = jwt.sign(
            { userId: user.id, username: user.username },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        // Passwort-Hash aus Response entfernen
        const { password_hash, ...userWithoutPassword } = user;

        res.json({
            success: true,
            message: 'Login erfolgreich',
            data: {
                user: userWithoutPassword,
                token
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * POST /api/auth/refresh
 * JWT Token erneuern (auch mit abgelaufenem Token)
 */
router.post('/auth/refresh', (req, res) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'Kein Token vorhanden'
            });
        }

        // Token verifizieren (auch wenn abgelaufen)
        jwt.verify(token, JWT_SECRET, { ignoreExpiration: true }, (err, user) => {
            if (err) {
                return res.status(403).json({
                    success: false,
                    message: 'Token ungültig'
                });
            }

            // Neuen Token erstellen
            const newToken = jwt.sign(
                { userId: user.userId, username: user.username },
                JWT_SECRET,
                { expiresIn: '7d' }
            );

            res.json({
                success: true,
                message: 'Token erneuert',
                data: {
                    token: newToken
                }
            });
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============ USER ROUTES ============

/**
 * GET /api/users/me
 * Aktuellen User abrufen (authentifiziert)
 */
router.get('/users/me', authenticateToken, async (req, res) => {
    try {
        const user = await dbService.getUserById(req.user.userId);

        res.json({
            success: true,
            data: user
        });
    } catch (error) {
        res.status(404).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * PUT /api/users/me
 * User-Profil updaten
 */
router.put('/users/me', authenticateToken, async (req, res) => {
    try {
        const updates = req.body;
        const result = await dbService.updateUser(req.user.userId, updates);

        res.json({
            success: true,
            message: result.message
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * DELETE /api/users/me
 * User-Account löschen
 */
router.delete('/users/me', authenticateToken, async (req, res) => {
    try {
        const result = await dbService.deleteUser(req.user.userId);

        res.json({
            success: true,
            message: result.message
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

// ============ QUEST ROUTES ============

/**
 * POST /api/quests
 * Neue Quest erstellen
 */
router.post('/quests', authenticateToken, async (req, res) => {
    try {
        const questData = req.body;
        const result = await dbService.createQuest(req.user.userId, questData);

        res.status(201).json({
            success: true,
            message: result.message,
            data: result
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * GET /api/quests
 * Alle Quests des Users abrufen
 * Query-Parameter: status (optional) - 'active', 'completed', 'failed'
 */
router.get('/quests', authenticateToken, async (req, res) => {
    try {
        const { status } = req.query;
        const quests = await dbService.getQuestsByUserId(req.user.userId, status);

        res.json({
            success: true,
            count: quests.length,
            data: quests
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * GET /api/quests/:id
 * Einzelne Quest abrufen
 */
router.get('/quests/:id', authenticateToken, async (req, res) => {
    try {
        const quest = await dbService.getQuestById(req.params.id);

        // Sicherstellen, dass Quest dem User gehört
        if (quest.user_id !== req.user.userId) {
            return res.status(403).json({
                success: false,
                message: 'Nicht autorisiert'
            });
        }

        res.json({
            success: true,
            data: quest
        });
    } catch (error) {
        res.status(404).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * PUT /api/quests/:id
 * Quest updaten
 */
router.put('/quests/:id', authenticateToken, async (req, res) => {
    try {
        const quest = await dbService.getQuestById(req.params.id);

        // Sicherstellen, dass Quest dem User gehört
        if (quest.user_id !== req.user.userId) {
            return res.status(403).json({
                success: false,
                message: 'Nicht autorisiert'
            });
        }

        const result = await dbService.updateQuest(req.params.id, req.body);

        res.json({
            success: true,
            message: result.message
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * POST /api/quests/:id/complete
 * Quest abschließen
 */
router.post('/quests/:id/complete', authenticateToken, async (req, res) => {
    try {
        const { detected_object } = req.body;
        const result = await dbService.completeQuest(
            req.params.id,
            req.user.userId,
            detected_object
        );

        res.json({
            success: true,
            message: result.message,
            data: result
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * DELETE /api/quests/:id
 * Quest löschen
 */
router.delete('/quests/:id', authenticateToken, async (req, res) => {
    try {
        const quest = await dbService.getQuestById(req.params.id);

        // Sicherstellen, dass Quest dem User gehört
        if (quest.user_id !== req.user.userId) {
            return res.status(403).json({
                success: false,
                message: 'Nicht autorisiert'
            });
        }

        const result = await dbService.deleteQuest(req.params.id);

        res.json({
            success: true,
            message: result.message
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

// ============ STATS ROUTES ============

/**
 * PUT /api/stats
 * User-Stats updaten
 */
router.put('/stats', authenticateToken, async (req, res) => {
    try {
        const updates = req.body;
        const result = await dbService.updateUserStats(req.user.userId, updates);

        res.json({
            success: true,
            message: result.message
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

module.exports = router;
