const express = require('express');
const router = express.Router();
const dbService = require('../services/dbService');
const sessionService = require('../services/sessionService');
const { sendError, handleCatchError, validateRegisterInput, validateLoginInput } = require('../services/authErrorHandler');
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
        return sendError(res, 'NO_TOKEN');
    }

    // Token auf Blacklist prüfen
    if (sessionService.isTokenBlacklisted(token)) {
        return sendError(res, 'TOKEN_REVOKED');
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            // Unterscheidung zwischen Token-Fehlern
            if (err.name === 'TokenExpiredError') {
                return sendError(res, 'TOKEN_EXPIRED', { expiredAt: err.expiredAt });
            }

            if (err.name === 'JsonWebTokenError') {
                return sendError(res, 'INVALID_TOKEN');
            }

            return sendError(res, 'INVALID_TOKEN');
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

        // Input Validierung
        const validationErrors = validateRegisterInput(username, email, password);
        if (validationErrors.length > 0) {
            return sendError(res, 'MISSING_FIELDS', { errors: validationErrors });
        }

        const result = await dbService.createUser(username, email, password);

        // JWT Token erstellen
        const token = jwt.sign(
            { userId: result.id, username: result.username },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        // Session erstellen
        const session = sessionService.createSession(result.id, token);

        res.status(201).json({
            success: true,
            code: 'REGISTRATION_SUCCESS',
            message: 'Registrierung erfolgreich',
            data: {
                user: result,
                token,
                session: {
                    createdAt: session.createdAt,
                    expiresAt: session.expiresAt
                }
            }
        });
    } catch (error) {
        handleCatchError(res, error, 'REGISTRATION_FAILED');
    }
});

/**
 * POST /api/auth/login
 * User-Login
 */
router.post('/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Input Validierung
        const validationErrors = validateLoginInput(email, password);
        if (validationErrors.length > 0) {
            return sendError(res, 'MISSING_FIELDS', { errors: validationErrors });
        }

        const user = await dbService.getUserByEmail(email);

        if (!user) {
            return sendError(res, 'INVALID_CREDENTIALS');
        }

        const isPasswordValid = await dbService.verifyPassword(password, user.password_hash);

        if (!isPasswordValid) {
            return sendError(res, 'INVALID_CREDENTIALS');
        }

        // JWT Token erstellen
        const token = jwt.sign(
            { userId: user.id, username: user.username },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        // Session erstellen
        const session = sessionService.createSession(user.id, token);

        // Passwort-Hash aus Response entfernen
        const { password_hash, ...userWithoutPassword } = user;

        res.json({
            success: true,
            code: 'LOGIN_SUCCESS',
            message: 'Login erfolgreich',
            data: {
                user: userWithoutPassword,
                token,
                session: {
                    createdAt: session.createdAt,
                    expiresAt: session.expiresAt,
                    totalActiveSessions: sessionService.getUserSessions(user.id).length
                }
            }
        });
    } catch (error) {
        handleCatchError(res, error, 'LOGIN_FAILED');
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
            return sendError(res, 'NO_TOKEN');
        }

        // Token verifizieren (auch wenn abgelaufen)
        jwt.verify(token, JWT_SECRET, { ignoreExpiration: true }, (err, user) => {
            if (err) {
                return sendError(res, 'INVALID_TOKEN');
            }

            // Neuen Token erstellen
            const newToken = jwt.sign(
                { userId: user.userId, username: user.username },
                JWT_SECRET,
                { expiresIn: '7d' }
            );

            res.json({
                success: true,
                code: 'TOKEN_REFRESHED',
                message: 'Token erneuert',
                data: {
                    token: newToken
                }
            });
        });
    } catch (error) {
        handleCatchError(res, error, 'REFRESH_FAILED');
    }
});

/**
 * POST /api/auth/logout
 * User-Logout (Token auf Blacklist)
 */
router.post('/auth/logout', authenticateToken, (req, res) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        // Token auf Blacklist setzen
        sessionService.invalidateToken(token);

        res.json({
            success: true,
            code: 'LOGOUT_SUCCESS',
            message: 'Logout erfolgreich',
            data: {
                userId: req.user.userId
            }
        });
    } catch (error) {
        handleCatchError(res, error, 'LOGOUT_FAILED');
    }
});

/**
 * GET /api/auth/sessions
 * Aktive Sessions des Users abrufen
 */
router.get('/auth/sessions', authenticateToken, (req, res) => {
    try {
        const userId = req.user.userId;
        const sessions = sessionService.getUserSessions(userId);

        res.json({
            success: true,
            code: 'SESSIONS_RETRIEVED',
            message: 'Aktive Sessions abgerufen',
            data: {
                sessions: sessions,
                totalSessions: sessions.length
            }
        });
    } catch (error) {
        handleCatchError(res, error, 'SESSIONS_FAILED');
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
