const express = require('express');
const router = express.Router();
const dbService = require('../services/dbService');
const sessionService = require('../services/sessionService');
const adminActionService = require('../services/adminActionService');
const { sendError: authError, handleCatchError: authCatchError, validateRegisterInput, validateLoginInput } = require('../services/authErrorHandler');
const { sendError: userError, handleCatchError: userCatchError } = require('../services/userErrorHandler');
const { sendError: questError, handleCatchError: questCatchError, checkQuestOwnership } = require('../services/questErrorHandler');
const { sendError: statsError, handleCatchError: statsCatchError } = require('../services/statsErrorHandler');
const visionService = require('../services/visionService');
const multer = require('multer');
const jwt = require('jsonwebtoken');

// JWT Secret (sollte in .env stehen)
const JWT_SECRET = process.env.JWT_SECRET || 'dein_geheimes_jwt_secret_key';

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 }
});

// ============ AUTH MIDDLEWARE ============

/**
 * Middleware: JWT Token verifizieren mit detailliertem Error-Handling
 */
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return authError(res, 'NO_TOKEN');
    }

    // Token auf Blacklist prüfen
    if (sessionService.isTokenBlacklisted(token)) {
        return authError(res, 'TOKEN_REVOKED');
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            // Unterscheidung zwischen Token-Fehlern
            if (err.name === 'TokenExpiredError') {
                return authError(res, 'TOKEN_EXPIRED', { expiredAt: err.expiredAt });
            }

            if (err.name === 'JsonWebTokenError') {
                return authError(res, 'INVALID_TOKEN');
            }

            return authError(res, 'INVALID_TOKEN');
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
            return authError(res, 'MISSING_FIELDS', { errors: validationErrors });
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
        authCatchError(res, error, 'REGISTRATION_FAILED');
    }
});

/**
 * POST /api/auth/login
 * User-Login mit Email ODER Username
 */
router.post('/auth/login', async (req, res) => {
    try {
        const { email, username, password } = req.body;

        const normalizeUser = (rawUser) => {
            if (!rawUser) return null;
            return {
                id: rawUser.id ?? rawUser.ID,
                username: rawUser.username ?? rawUser.USERNAME,
                email: rawUser.email ?? rawUser.EMAIL,
                password_hash: rawUser.password_hash ?? rawUser.PASSWORD_HASH,
                level: rawUser.level ?? rawUser.LEVEL ?? 1,
                xp: rawUser.xp ?? rawUser.XP ?? 0,
                streak_days: rawUser.streak_days ?? rawUser.STREAK_DAYS ?? 0,
                last_quest_date: rawUser.last_quest_date ?? rawUser.LAST_QUEST_DATE ?? null,
                theme: rawUser.theme ?? rawUser.THEME ?? 'default',
                role: rawUser.role ?? rawUser.ROLE ?? 'user',
                is_active: rawUser.is_active ?? rawUser.IS_ACTIVE ?? 1,
                created_at: rawUser.created_at ?? rawUser.CREATED_AT,
                updated_at: rawUser.updated_at ?? rawUser.UPDATED_AT
            };
        };

        // Input Validierung - entweder email oder username erforderlich
        if (!password) {
            return authError(res, 'MISSING_FIELDS', { errors: ['password ist erforderlich'] });
        }

        if (!email && !username) {
            return authError(res, 'MISSING_FIELDS', { errors: ['email oder username ist erforderlich'] });
        }

        // User per Email oder Username finden
        let user;
        if (email) {
            user = await dbService.getUserByEmail(email);
        } else {
            user = await dbService.getUserByUsername(username);
        }

        user = normalizeUser(user);

        if (!user) {
            return authError(res, 'INVALID_CREDENTIALS');
        }

        // Passwort verifizieren
        const isPasswordValid = await dbService.verifyPassword(password, user.password_hash);

        if (!isPasswordValid) {
            return authError(res, 'INVALID_CREDENTIALS');
        }

        // JWT Token erstellen
        const token = jwt.sign(
            { userId: user.id, username: user.username, role: user.role },
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
        authCatchError(res, error, 'LOGIN_FAILED');
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
            return authError(res, 'NO_TOKEN');
        }

        // Token verifizieren (auch wenn abgelaufen)
        jwt.verify(token, JWT_SECRET, { ignoreExpiration: true }, (err, user) => {
            if (err) {
                return authError(res, 'INVALID_TOKEN');
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
        authCatchError(res, error, 'REFRESH_FAILED');
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
        authCatchError(res, error, 'LOGOUT_FAILED');
    }
});

// ============ VISION ROUTES ============

/**
 * POST /api/vision/detect
 * Bild hochladen und Objekt erkennen
 */
router.post('/vision/detect', authenticateToken, upload.single('image'), async (req, res) => {
    try {
        console.log('[VISION] Request received', {
            hasFile: !!req.file,
            fileSize: req.file?.size,
            fileName: req.file?.originalname,
            contentType: req.headers['content-type'],
            authHeader: !!req.headers['authorization']
        });

        if (!req.file) {
            console.error('[VISION] No file received. Headers:', req.headers);
            return res.status(400).json({
                success: false,
                code: 'IMAGE_MISSING',
                message: 'Kein Bild hochgeladen'
            });
        }

        const preferredModel = (req.headers['x-vision-model'] || 'yolo').toString().toLowerCase();
        const focusMode = (req.headers['x-vision-focus'] || 'balanced').toString().toLowerCase();

        const result = await visionService.detectImage(req.file.buffer, {
            preferredModel,
            focusMode
        });

        console.log('[VISION] Detection result:', {
            label: result.label,
            confidence: result.confidence,
            hasError: !!result.error
        });

        res.json({
            success: true,
            code: 'DETECTION_SUCCESS',
            message: 'Objekt erkannt',
            data: result
        });
    } catch (error) {
        console.error('[VISION ERROR]:', error.message);
        res.status(500).json({
            success: false,
            code: 'DETECTION_FAILED',
            message: 'Objekt-Erkennung fehlgeschlagen',
            details: error.message
        });
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
        authCatchError(res, error, 'SESSIONS_FAILED');
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
            code: 'USER_RETRIEVED',
            data: user
        });
    } catch (error) {
        userCatchError(res, error, 'GET_USER');
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
            code: 'USER_UPDATED',
            message: result.message
        });
    } catch (error) {
        userCatchError(res, error, 'UPDATE_USER');
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
            code: 'USER_DELETED',
            message: result.message
        });
    } catch (error) {
        userCatchError(res, error, 'DELETE_USER');
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
            code: 'QUEST_CREATED',
            message: result.message,
            data: result
        });
    } catch (error) {
        questCatchError(res, error, 'CREATE_QUEST');
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
            code: 'QUESTS_RETRIEVED',
            count: quests.length,
            data: quests
        });
    } catch (error) {
        questCatchError(res, error, 'GET_QUESTS');
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
        if (!checkQuestOwnership(quest.user_id, req.user.userId)) {
            return questError(res, 'QUEST_UNAUTHORIZED');
        }

        res.json({
            success: true,
            code: 'QUEST_RETRIEVED',
            data: quest
        });
    } catch (error) {
        questCatchError(res, error, 'GET_QUEST');
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
        if (!checkQuestOwnership(quest.user_id, req.user.userId)) {
            return questError(res, 'QUEST_UNAUTHORIZED');
        }

        const result = await dbService.updateQuest(req.params.id, req.body);

        res.json({
            success: true,
            code: 'QUEST_UPDATED',
            message: result.message
        });
    } catch (error) {
        questCatchError(res, error, 'UPDATE_QUEST');
    }
});

/**
 * POST /api/quests/:id/complete
 * Quest abschließen
 */
router.post('/quests/:id/complete', authenticateToken, async (req, res) => {
    try {
        const { detected_object } = req.body || {};
        const result = await dbService.completeQuest(
            req.params.id,
            req.user.userId,
            detected_object
        );

        res.json({
            success: true,
            code: 'QUEST_COMPLETED',
            message: result.message,
            data: result
        });
    } catch (error) {
        questCatchError(res, error, 'COMPLETE_QUEST');
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
        if (!checkQuestOwnership(quest.user_id, req.user.userId)) {
            return questError(res, 'QUEST_UNAUTHORIZED');
        }

        const result = await dbService.deleteQuest(req.params.id);

        res.json({
            success: true,
            code: 'QUEST_DELETED',
            message: result.message
        });
    } catch (error) {
        questCatchError(res, error, 'DELETE_QUEST');
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
            code: 'STATS_UPDATED',
            message: result.message
        });
    } catch (error) {
        statsCatchError(res, error, 'UPDATE_STATS');
    }
});

// ============ ADMIN MIDDLEWARE ============

/**
 * Middleware: Admin-Check - nur Admins dürfen diese Routes versenden
 */
const requireAdmin = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({
            success: false,
            code: 'UNAUTHORIZED',
            message: 'Authentifizierung erforderlich'
        });
    }

    // JWT Token dekodieren um rolle zu prüfen
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) {
        return res.status(403).json({
            success: false,
            code: 'FORBIDDEN',
            message: 'Admin-Zugriff erforderlich'
        });
    }

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err || !decoded || decoded.role !== 'admin') {
            return res.status(403).json({
                success: false,
                code: 'FORBIDDEN',
                message: 'Admin-Zugriff erforderlich'
            });
        }
        next();
    });
};

// ============ ADMIN ROUTES ============

/**
 * GET /api/admin/users
 * Alle User auflisten (nur für Admins)
 */
router.get('/admin/users', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const users = await dbService.getAllUsers();

        res.json({
            success: true,
            code: 'USERS_RETRIEVED',
            message: 'User-Liste erfolgreich abgerufen',
            data: {
                total: users.length,
                users: users
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Abrufen der User-Liste',
            error: error.message
        });
    }
});

/**
 * PUT /api/admin/users/:id
 * User bearbeiten (nur für Admins)
 */
router.put('/admin/users/:id', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const userId = parseInt(req.params.id);
        const updates = req.body;

        // Validierung: nur bestimmte Felder dürfen aktualisiert werden
        const allowedUpdates = ['username', 'email', 'level', 'xp', 'role', 'is_active'];
        const cleanUpdates = {};

        Object.keys(updates).forEach(key => {
            if (allowedUpdates.includes(key)) {
                cleanUpdates[key] = updates[key];
            }
        });

        if (Object.keys(cleanUpdates).length === 0) {
            return res.status(400).json({
                success: false,
                code: 'INVALID_UPDATE',
                message: 'Keine gültigen Update-Felder angegeben'
            });
        }

        const result = await dbService.updateUser(userId, cleanUpdates);

        // Log the action
        try {
            await adminActionService.logAction(
                req.user.userId,
                'update',
                userId,
                { fields: Object.keys(cleanUpdates), values: cleanUpdates }
            );
        } catch (logErr) {
            console.warn('Failed to log admin action:', logErr);
        }

        res.json({
            success: true,
            code: 'USER_UPDATED',
            message: result.message
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Aktualisieren des Users',
            error: error.message
        });
    }
});

/**
 * DELETE /api/admin/users/:id
 * User löschen (nur für Admins)
 */
router.delete('/admin/users/:id', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const userId = parseInt(req.params.id);

        // Sicherheit: User darf sich selbst nicht löschen
        if (userId === req.user.userId) {
            return res.status(400).json({
                success: false,
                code: 'CANNOT_DELETE_SELF',
                message: 'Du kannst deinen eigenen Account nicht löschen'
            });
        }

        const result = await dbService.deleteUser(userId);

        // Log the action
        try {
            await adminActionService.logAction(
                req.user.userId,
                'delete',
                userId,
                { deleted_user: userId }
            );
        } catch (logErr) {
            console.warn('Failed to log admin action:', logErr);
        }

        res.json({
            success: true,
            code: 'USER_DELETED',
            message: result.message
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Löschen des Users',
            error: error.message
        });
    }
});

/**
 * GET /api/admin/stats
 * Admin-Statistiken (nur für Admins)
 */
router.get('/admin/stats', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const users = await dbService.getAllUsers();

        // Berechne Statistiken
        const totalUsers = users.length;
        const totalXp = users.reduce((sum, u) => sum + (u.xp ?? u.XP ?? 0), 0);
        const averageLevel = users.length > 0
            ? (users.reduce((sum, u) => sum + (u.level ?? u.LEVEL ?? 1), 0) / users.length).toFixed(1)
            : 0;

        // Level-Verteilung
        const levelDistribution = {};
        users.forEach(u => {
            const lvl = u.level ?? u.LEVEL ?? 1;
            levelDistribution[lvl] = (levelDistribution[lvl] || 0) + 1;
        });

        // Top 5 User nach XP
        const topUsers = users
            .sort((a, b) => (b.xp ?? b.XP ?? 0) - (a.xp ?? a.XP ?? 0))
            .slice(0, 5)
            .map(u => ({
                id: u.id ?? u.ID,
                username: u.username ?? u.USERNAME,
                level: u.level ?? u.LEVEL ?? 1,
                xp: u.xp ?? u.XP ?? 0
            }));

        // Aktiv bedeutet is_active = 1
        const activeUsers = users.filter(u => (u.is_active ?? u.IS_ACTIVE ?? 1) === 1).length;
        const inactiveUsers = totalUsers - activeUsers;

        // Admin-Anteil
        const adminCount = users.filter(u => (u.role ?? u.ROLE ?? 'user') === 'admin').length;

        res.json({
            success: true,
            code: 'STATS_RETRIEVED',
            message: 'Admin-Statistiken erfolgreich abgerufen',
            data: {
                summary: {
                    totalUsers,
                    activeUsers,
                    inactiveUsers,
                    adminCount,
                    totalXp,
                    averageLevel: parseFloat(averageLevel)
                },
                distribution: {
                    byLevel: levelDistribution
                },
                topUsers
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Abrufen der Statistiken',
            error: error.message
        });
    }
});

/**
 * GET /api/admin/logs
 * Admin-Action Logs abrufen (nur für Admins)
 */
router.get('/admin/logs', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const limit = Math.min(parseInt(req.query.limit) || 100, 500);
        const offset = parseInt(req.query.offset) || 0;

        const logs = await adminActionService.getAllActions(limit, offset);

        res.json({
            success: true,
            code: 'LOGS_RETRIEVED',
            message: 'Admin-Logs erfolgreich abgerufen',
            data: {
                logs,
                count: logs.length
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Abrufen der Logs',
            error: error.message
        });
    }
});

/**
 * GET /api/admin/users/:id/history
 * Aktion-History für spezifischen User (nur für Admins)
 */
router.get('/admin/users/:id/history', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const userId = parseInt(req.params.id);
        const actions = await adminActionService.getUserActions(userId, 50);

        res.json({
            success: true,
            code: 'HISTORY_RETRIEVED',
            message: 'User-History erfolgreich abgerufen',
            data: {
                userId,
                actions,
                count: actions.length
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Abrufen der History',
            error: error.message
        });
    }
});

/**
 * POST /api/admin/users/:id/suspend
 * User suspendieren (nur für Admins)
 */
router.post('/admin/users/:id/suspend', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const userId = parseInt(req.params.id);
        const { reason } = req.body;

        // Sicherheit: User darf sich selbst nicht suspendieren
        if (userId === req.user.userId) {
            return res.status(400).json({
                success: false,
                code: 'CANNOT_SUSPEND_SELF',
                message: 'Du kannst deinen eigenen Account nicht suspendieren'
            });
        }

        const result = await adminActionService.suspendUser(userId, req.user.userId, reason || 'Kein Grund angegeben');

        // Log the action
        try {
            await adminActionService.logAction(
                req.user.userId,
                'suspend',
                userId,
                { reason: reason || 'Kein Grund angegeben' }
            );
        } catch (logErr) {
            console.warn('Failed to log admin action:', logErr);
        }

        res.json({
            success: true,
            code: 'USER_SUSPENDED',
            message: result.message,
            data: result
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Suspendieren des Users',
            error: error.message
        });
    }
});

/**
 * POST /api/admin/users/:id/unsuspend
 * User entsperren (nur für Admins)
 */
router.post('/admin/users/:id/unsuspend', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const userId = parseInt(req.params.id);

        const result = await adminActionService.unsuspendUser(userId);

        // Log the action
        try {
            await adminActionService.logAction(
                req.user.userId,
                'unsuspend',
                userId,
                { reason: 'User entsperrt' }
            );
        } catch (logErr) {
            console.warn('Failed to log admin action:', logErr);
        }

        res.json({
            success: true,
            code: 'USER_UNSUSPENDED',
            message: result.message
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Entsperren des Users',
            error: error.message
        });
    }
});

/**
 * GET /api/admin/suspensions
 * Alle Suspensionen abrufen (nur für Admins)
 */
router.get('/admin/suspensions', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const suspensions = await adminActionService.getAllSuspensions(false);

        res.json({
            success: true,
            code: 'SUSPENSIONS_RETRIEVED',
            message: 'Suspensionen erfolgreich abgerufen',
            data: {
                suspensions,
                count: suspensions.length
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Abrufen der Suspensionen',
            error: error.message
        });
    }
});

/**
 * GET /api/admin/users/export
 * User-Daten in CSV oder JSON exportieren (nur für Admins)
 * Query-Parameter: format=csv oder format=json
 */
router.get('/admin/users/export', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const format = (req.query.format || 'json').toLowerCase();
        const users = await dbService.getAllUsers();

        if (format === 'csv') {
            // Convert to CSV
            const csvHeader = 'ID,USERNAME,EMAIL,LEVEL,XP,ROLE,IS_ACTIVE,CREATED_AT\n';
            const csvRows = users.map(u => {
                const id = u.id ?? u.ID;
                const username = (u.username ?? u.USERNAME ?? '').replace(/,/g, ';');
                const email = (u.email ?? u.EMAIL ?? '').replace(/,/g, ';');
                const level = u.level ?? u.LEVEL ?? 1;
                const xp = u.xp ?? u.XP ?? 0;
                const role = u.role ?? u.ROLE ?? 'user';
                const isActive = u.is_active ?? u.IS_ACTIVE ?? 1;
                const createdAt = u.created_at ?? u.CREATED_AT ?? '';
                return `${id},"${username}","${email}",${level},${xp},"${role}",${isActive},"${createdAt}"`;
            }).join('\n');

            const csv = csvHeader + csvRows;

            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename="user-export.csv"');
            res.send(csv);

            // Log the export action
            try {
                await adminActionService.logAction(
                    req.user.userId,
                    'export',
                    null,
                    { format: 'csv', userCount: users.length }
                );
            } catch (logErr) {
                console.warn('Failed to log export action:', logErr);
            }
        } else {
            // JSON export (default)
            const jsonData = users.map(u => ({
                id: u.id ?? u.ID,
                username: u.username ?? u.USERNAME,
                email: u.email ?? u.EMAIL,
                level: u.level ?? u.LEVEL ?? 1,
                xp: u.xp ?? u.XP ?? 0,
                role: u.role ?? u.ROLE ?? 'user',
                is_active: u.is_active ?? u.IS_ACTIVE ?? 1,
                createdAt: u.created_at ?? u.CREATED_AT,
                updatedAt: u.updated_at ?? u.UPDATED_AT
            }));

            // Log the export action
            try {
                await adminActionService.logAction(
                    req.user.userId,
                    'export',
                    null,
                    { format: 'json', userCount: users.length }
                );
            } catch (logErr) {
                console.warn('Failed to log export action:', logErr);
            }

            res.setHeader('Content-Disposition', 'attachment; filename="user-export.json"');
            res.json({
                success: true,
                code: 'EXPORT_SUCCESS',
                message: 'User-Export erfolgreich',
                data: {
                    users: jsonData,
                    count: jsonData.length,
                    exportedAt: new Date().toISOString()
                }
            });
        }
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Exportieren der User-Daten',
            error: error.message
        });
    }
});

/**
 * GET /api/admin/activity
 * User Activity Dashboard (nur für Admins)
 */
router.get('/admin/activity', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const { db } = require('../../database/db');

        // Zuletzt aktive User
        const recentlyActiveUsers = await new Promise((resolve, reject) => {
            const sql = `
                SELECT 
                    ID, USERNAME, LEVEL, XP, LAST_QUEST_DATE
                FROM USERS
                WHERE LAST_QUEST_DATE IS NOT NULL
                ORDER BY LAST_QUEST_DATE DESC
                LIMIT 10
            `;
            db.all(sql, [], (err, rows) => {
                if (err) return reject(err);
                resolve((rows || []).map(u => ({
                    id: u.ID ?? u.id,
                    username: u.USERNAME ?? u.username,
                    level: u.LEVEL ?? u.level ?? 1,
                    xp: u.XP ?? u.xp ?? 0,
                    lastActive: u.LAST_QUEST_DATE ?? u.last_quest_date
                })));
            });
        });

        // Total Quests Completed
        const questStats = await new Promise((resolve, reject) => {
            const sql = `
                SELECT 
                    COUNT(*) as total_completed,
                    COUNT(USER_ID) as unique_users,
                    AVG(XP_REWARD) as avg_reward
                FROM QUESTS
                WHERE STATUS = 'completed'
            `;
            db.get(sql, [], (err, row) => {
                if (err) return reject(err);
                resolve({
                    totalCompleted: row?.total_completed ?? 0,
                    uniqueUsers: row?.unique_users ?? 0,
                    avgReward: row?.avg_reward?.toFixed(1) ?? 0
                });
            });
        });

        // Top Quest Categories
        const topCategories = await new Promise((resolve, reject) => {
            const sql = `
                SELECT 
                    CATEGORY,
                    COUNT(*) as count
                FROM QUESTS
                WHERE STATUS = 'completed'
                GROUP BY CATEGORY
                ORDER BY count DESC
                LIMIT 5
            `;
            db.all(sql, [], (err, rows) => {
                if (err) return reject(err);
                resolve((rows || []).map(r => ({
                    category: r.CATEGORY ?? r.category,
                    count: r.count
                })));
            });
        });

        res.json({
            success: true,
            code: 'ACTIVITY_RETRIEVED',
            message: 'Activity-Dashboard erfolgreich abgerufen',
            data: {
                recentlyActive: recentlyActiveUsers,
                questStats: questStats,
                topCategories: topCategories,
                lastUpdated: new Date().toISOString()
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            code: 'ADMIN_ERROR',
            message: 'Fehler beim Abrufen der Activity-Daten',
            error: error.message
        });
    }
});

module.exports = router;
