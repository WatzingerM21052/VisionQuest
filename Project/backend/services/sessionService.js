/**
 * Session-Management Service
 * Verwaltet aktive Sessions und Token-Blacklist
 */

// In-Memory Token-Blacklist (Logout)
// In Produktion: Redis oder Datenbank nutzen
const tokenBlacklist = new Set();

// Aktive Sessions per User
const activeSessions = new Map();

/**
 * Session erstellen nach Login
 */
function createSession(userId, token) {
    if (!activeSessions.has(userId)) {
        activeSessions.set(userId, []);
    }

    const session = {
        token: token.substring(0, 20) + '...', // Token Snippet für Logging
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 Tage
    };

    activeSessions.get(userId).push(session);

    // Max 5 Sessions pro User
    if (activeSessions.get(userId).length > 5) {
        activeSessions.get(userId).shift();
    }

    return session;
}

/**
 * Session beenden (Logout)
 */
function invalidateToken(token) {
    tokenBlacklist.add(token);
}

/**
 * Token auf Blacklist prüfen
 */
function isTokenBlacklisted(token) {
    return tokenBlacklist.has(token);
}

/**
 * Alle Sessions eines Users beenden
 */
function invalidateUserSessions(userId) {
    if (activeSessions.has(userId)) {
        activeSessions.delete(userId);
    }
}

/**
 * Aktive Sessions eines Users abrufen
 */
function getUserSessions(userId) {
    return activeSessions.get(userId) || [];
}

/**
 * Session-Statistiken
 */
function getSessionStats() {
    return {
        totalActiveSessions: Array.from(activeSessions.values()).reduce((sum, sessions) => sum + sessions.length, 0),
        blacklistedTokens: tokenBlacklist.size,
        activeUsers: activeSessions.size
    };
}

module.exports = {
    createSession,
    invalidateToken,
    isTokenBlacklisted,
    invalidateUserSessions,
    getUserSessions,
    getSessionStats
};
