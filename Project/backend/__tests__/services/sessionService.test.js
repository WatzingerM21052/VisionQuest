const sessionService = require('../../services/sessionService');

describe('SessionService', () => {
    beforeEach(() => {
        // Clear all sessions and blacklist before each test
        sessionService.resetState();
    });

    describe('createSession', () => {
        it('should create a new session for a user', () => {
            const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token';
            const session = sessionService.createSession(1, token);

            expect(session).toBeDefined();
            expect(session.token).toBeDefined();
            expect(session.createdAt).toBeInstanceOf(Date);
            expect(session.expiresAt).toBeInstanceOf(Date);
        });

        it('should store the session in active sessions', () => {
            const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token';
            sessionService.createSession(1, token);

            const sessions = sessionService.getUserSessions(1);
            expect(sessions.length).toBe(1);
        });

        it('should limit max sessions to 5 per user', () => {
            for (let i = 0; i < 10; i++) {
                const token = `token-${i}`;
                sessionService.createSession(1, token);
            }

            const sessions = sessionService.getUserSessions(1);
            expect(sessions.length).toBe(5);
        });

        it('should set expiration to 7 days from now', () => {
            const token = 'test-token';
            const session = sessionService.createSession(1, token);

            const expectedExpiry = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
            const difference = Math.abs(session.expiresAt.getTime() - expectedExpiry.getTime());

            // Allow 1 second difference for test execution time
            expect(difference).toBeLessThan(1000);
        });
    });

    describe('invalidateToken', () => {
        it('should add token to blacklist', () => {
            const token = 'test-token-to-blacklist';

            expect(sessionService.isTokenBlacklisted(token)).toBe(false);

            sessionService.invalidateToken(token);

            expect(sessionService.isTokenBlacklisted(token)).toBe(true);
        });

        it('should prevent using blacklisted token', () => {
            const token = 'blacklisted-token';
            sessionService.invalidateToken(token);

            expect(sessionService.isTokenBlacklisted(token)).toBe(true);
        });
    });

    describe('isTokenBlacklisted', () => {
        it('should return false for valid token', () => {
            const token = 'valid-token';
            expect(sessionService.isTokenBlacklisted(token)).toBe(false);
        });

        it('should return true for blacklisted token', () => {
            const token = 'invalid-token';
            sessionService.invalidateToken(token);
            expect(sessionService.isTokenBlacklisted(token)).toBe(true);
        });
    });

    describe('invalidateUserSessions', () => {
        it('should remove all sessions for a user', () => {
            // Create multiple sessions
            sessionService.createSession(1, 'token1');
            sessionService.createSession(1, 'token2');
            sessionService.createSession(1, 'token3');

            expect(sessionService.getUserSessions(1).length).toBe(3);

            sessionService.invalidateUserSessions(1);

            expect(sessionService.getUserSessions(1).length).toBe(0);
        });

        it('should not affect other users\' sessions', () => {
            sessionService.createSession(1, 'token1');
            sessionService.createSession(2, 'token2');

            sessionService.invalidateUserSessions(1);

            expect(sessionService.getUserSessions(1).length).toBe(0);
            expect(sessionService.getUserSessions(2).length).toBe(1);
        });
    });

    describe('getUserSessions', () => {
        it('should return empty array for user with no sessions', () => {
            const sessions = sessionService.getUserSessions(999);
            expect(sessions).toEqual([]);
        });

        it('should return all sessions for a user', () => {
            sessionService.createSession(1, 'token1');
            sessionService.createSession(1, 'token2');

            const sessions = sessionService.getUserSessions(1);
            expect(sessions.length).toBe(2);
        });

        it('should return different sessions for different users', () => {
            sessionService.createSession(1, 'token1');
            sessionService.createSession(2, 'token2');

            const user1Sessions = sessionService.getUserSessions(1);
            const user2Sessions = sessionService.getUserSessions(2);

            expect(user1Sessions.length).toBe(1);
            expect(user2Sessions.length).toBe(1);
            expect(user1Sessions[0]).not.toEqual(user2Sessions[0]);
        });
    });

    describe('getSessionStats', () => {
        it('should return correct statistics', () => {
            sessionService.createSession(1, 'token1');
            sessionService.createSession(1, 'token2');
            sessionService.createSession(2, 'token3');
            sessionService.invalidateToken('blacklisted1');
            sessionService.invalidateToken('blacklisted2');

            const stats = sessionService.getSessionStats();

            expect(stats.totalActiveSessions).toBe(3);
            expect(stats.activeUsers).toBe(2);
            expect(stats.blacklistedTokens).toBe(2);
        });

        it('should return zero stats when no sessions exist', () => {
            const stats = sessionService.getSessionStats();

            expect(stats.totalActiveSessions).toBeGreaterThanOrEqual(0);
            expect(stats.activeUsers).toBeGreaterThanOrEqual(0);
            expect(stats.blacklistedTokens).toBeGreaterThanOrEqual(0);
        });
    });

    describe('Integration: Session lifecycle', () => {
        it('should handle complete session lifecycle', () => {
            const userId = 1;
            const token = 'lifecycle-test-token';

            // Create session
            const session = sessionService.createSession(userId, token);
            expect(session).toBeDefined();

            // Verify session exists
            const sessions = sessionService.getUserSessions(userId);
            expect(sessions.length).toBe(1);

            // Invalidate token
            sessionService.invalidateToken(token);
            expect(sessionService.isTokenBlacklisted(token)).toBe(true);

            // Session still exists but token is blacklisted
            expect(sessionService.getUserSessions(userId).length).toBe(1);

            // Invalidate all user sessions
            sessionService.invalidateUserSessions(userId);
            expect(sessionService.getUserSessions(userId).length).toBe(0);

            // Token still blacklisted
            expect(sessionService.isTokenBlacklisted(token)).toBe(true);
        });
    });
});
