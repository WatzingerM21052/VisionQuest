const request = require('supertest');
const express = require('express');
const router = require('../../routes/api');
const dbService = require('../../services/dbService');
const sessionService = require('../../services/sessionService');
const jwt = require('jsonwebtoken');

// Create express app for testing
const app = express();
app.use(express.json());
app.use('/api', router);

// Mock dependencies
jest.mock('../../services/dbService');
jest.mock('../../services/sessionService');

const JWT_SECRET = process.env.JWT_SECRET || 'dein_geheimes_jwt_secret_key';

describe('Auth API Routes', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        sessionService.isTokenBlacklisted = jest.fn().mockReturnValue(false);
    });

    describe('POST /api/auth/register', () => {
        it('should register a new user successfully', async () => {
            const mockUser = {
                id: 1,
                username: 'testuser',
                email: 'test@example.com',
                message: 'User erfolgreich erstellt',
            };

            const mockSession = {
                createdAt: new Date().toISOString(),
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
            };

            dbService.createUser.mockResolvedValue(mockUser);
            sessionService.createSession.mockReturnValue(mockSession);

            const response = await request(app)
                .post('/api/auth/register')
                .send({
                    username: 'testuser',
                    email: 'test@example.com',
                    password: 'password123',
                });

            expect(response.status).toBe(201);
            expect(response.body.success).toBe(true);
            expect(response.body.code).toBe('REGISTRATION_SUCCESS');
            expect(response.body.data.user).toEqual(mockUser);
            expect(response.body.data.token).toBeDefined();
            expect(dbService.createUser).toHaveBeenCalledWith('testuser', 'test@example.com', 'password123');
        });

        it('should reject registration with missing fields', async () => {
            const response = await request(app)
                .post('/api/auth/register')
                .send({
                    username: 'testuser',
                    // Missing email and password
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('MISSING_FIELDS');
        });

        it('should reject registration with invalid email', async () => {
            const response = await request(app)
                .post('/api/auth/register')
                .send({
                    username: 'testuser',
                    email: 'invalid-email',
                    password: 'password123',
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
        });

        it('should reject registration with duplicate email', async () => {
            dbService.createUser.mockRejectedValue(new Error('Username oder E-Mail bereits vergeben'));

            const response = await request(app)
                .post('/api/auth/register')
                .send({
                    username: 'testuser',
                    email: 'existing@example.com',
                    password: 'password123',
                });

            expect(response.status).toBe(500);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('SERVER_ERROR');
        });
    });

    describe('POST /api/auth/login', () => {
        it('should login successfully with valid credentials', async () => {
            const mockUser = {
                id: 1,
                username: 'testuser',
                email: 'test@example.com',
                password_hash: '$2a$10$hashedpassword',
                level: 1,
                xp: 100,
            };

            const mockSession = {
                createdAt: new Date().toISOString(),
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
            };

            dbService.getUserByEmail.mockResolvedValue(mockUser);
            dbService.verifyPassword.mockResolvedValue(true);
            sessionService.createSession.mockReturnValue(mockSession);
            sessionService.getUserSessions.mockReturnValue([mockSession]);

            const response = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@example.com',
                    password: 'password123',
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.code).toBe('LOGIN_SUCCESS');
            expect(response.body.data.user).toBeDefined();
            expect(response.body.data.user.password_hash).toBeUndefined();
            expect(response.body.data.token).toBeDefined();
        });

        it('should reject login with invalid email', async () => {
            dbService.getUserByEmail.mockResolvedValue(null);

            const response = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'nonexistent@example.com',
                    password: 'password123',
                });

            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('INVALID_CREDENTIALS');
        });

        it('should reject login with invalid password', async () => {
            const mockUser = {
                id: 1,
                username: 'testuser',
                email: 'test@example.com',
                password_hash: '$2a$10$hashedpassword',
            };

            dbService.getUserByEmail.mockResolvedValue(mockUser);
            dbService.verifyPassword.mockResolvedValue(false);

            const response = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@example.com',
                    password: 'wrongpassword',
                });

            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('INVALID_CREDENTIALS');
        });

        it('should reject login with missing fields', async () => {
            const response = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@example.com',
                    // Missing password
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('MISSING_FIELDS');
        });
    });

    describe('POST /api/auth/refresh', () => {
        it('should refresh a valid token', async () => {
            const oldToken = jwt.sign(
                { userId: 1, username: 'testuser' },
                JWT_SECRET,
                { expiresIn: '7d' }
            );

            const response = await request(app)
                .post('/api/auth/refresh')
                .set('Authorization', `Bearer ${oldToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.code).toBe('TOKEN_REFRESHED');
            expect(response.body.data.token).toBeDefined();
            expect(response.body.data.token).toEqual(expect.any(String));
        });

        it('should refresh an expired token', async () => {
            const expiredToken = jwt.sign(
                { userId: 1, username: 'testuser' },
                JWT_SECRET,
                { expiresIn: '-1s' } // Already expired
            );

            const response = await request(app)
                .post('/api/auth/refresh')
                .set('Authorization', `Bearer ${expiredToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.code).toBe('TOKEN_REFRESHED');
        });

        it('should reject refresh without token', async () => {
            const response = await request(app).post('/api/auth/refresh');

            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('NO_TOKEN');
        });

        it('should reject refresh with invalid token', async () => {
            const response = await request(app)
                .post('/api/auth/refresh')
                .set('Authorization', 'Bearer invalid-token');

            expect(response.status).toBe(403);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('INVALID_TOKEN');
        });
    });

    describe('POST /api/auth/logout', () => {
        it('should logout successfully with valid token', async () => {
            const token = jwt.sign(
                { userId: 1, username: 'testuser' },
                JWT_SECRET,
                { expiresIn: '7d' }
            );

            sessionService.invalidateToken.mockReturnValue(undefined);

            const response = await request(app)
                .post('/api/auth/logout')
                .set('Authorization', `Bearer ${token}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.code).toBe('LOGOUT_SUCCESS');
            expect(sessionService.invalidateToken).toHaveBeenCalledWith(token);
        });

        it('should reject logout without token', async () => {
            const response = await request(app).post('/api/auth/logout');

            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('NO_TOKEN');
        });

        it('should reject logout with blacklisted token', async () => {
            const token = jwt.sign(
                { userId: 1, username: 'testuser' },
                JWT_SECRET,
                { expiresIn: '7d' }
            );

            sessionService.isTokenBlacklisted.mockReturnValue(true);

            const response = await request(app)
                .post('/api/auth/logout')
                .set('Authorization', `Bearer ${token}`);

            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('TOKEN_REVOKED');
        });
    });
});

describe('User API Routes', () => {
    let validToken;

    beforeEach(() => {
        jest.clearAllMocks();
        sessionService.isTokenBlacklisted = jest.fn().mockReturnValue(false);
        validToken = jwt.sign(
            { userId: 1, username: 'testuser' },
            JWT_SECRET,
            { expiresIn: '7d' }
        );
    });

    describe('GET /api/users/me', () => {
        it('should return current user data', async () => {
            const mockUser = {
                id: 1,
                username: 'testuser',
                email: 'test@example.com',
                level: 5,
                xp: 250,
            };

            dbService.getUserById.mockResolvedValue(mockUser);

            const response = await request(app)
                .get('/api/users/me')
                .set('Authorization', `Bearer ${validToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data).toEqual(mockUser);
        });

        it('should reject without authentication', async () => {
            const response = await request(app).get('/api/users/me');

            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('NO_TOKEN');
        });
    });

    describe('DELETE /api/users/me', () => {
        it('should delete user account', async () => {
            dbService.deleteUser.mockResolvedValue({
                message: 'User erfolgreich gelöscht',
                changes: 1,
            });

            const response = await request(app)
                .delete('/api/users/me')
                .set('Authorization', `Bearer ${validToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(dbService.deleteUser).toHaveBeenCalledWith(1);
        });
    });

    describe('PUT /api/users/me', () => {
        it('should update user profile', async () => {
            dbService.updateUser.mockResolvedValue({
                message: 'User erfolgreich aktualisiert',
                changes: 1,
            });

            const response = await request(app)
                .put('/api/users/me')
                .set('Authorization', `Bearer ${validToken}`)
                .send({ theme: 'dark' });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.code).toBe('USER_UPDATED');
            expect(dbService.updateUser).toHaveBeenCalledWith(1, { theme: 'dark' });
        });
    });
});

describe('Quest API Routes', () => {
    let validToken;

    beforeEach(() => {
        jest.clearAllMocks();
        sessionService.isTokenBlacklisted = jest.fn().mockReturnValue(false);
        validToken = jwt.sign(
            { userId: 1, username: 'testuser' },
            JWT_SECRET,
            { expiresIn: '7d' }
        );
    });

    describe('GET /api/quests', () => {
        it('should return all quests for a user', async () => {
            const mockQuests = [
                { id: 1, user_id: 1, title: 'Quest 1', category: 'daily', xp_reward: 50 },
                { id: 2, user_id: 1, title: 'Quest 2', category: 'weekly', xp_reward: 100 },
            ];

            dbService.getQuestsByUserId.mockResolvedValue(mockQuests);

            const response = await request(app)
                .get('/api/quests')
                .set('Authorization', `Bearer ${validToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.length).toBe(2);
        });
    });

    describe('POST /api/quests', () => {
        it('should create a new quest', async () => {
            const mockQuest = {
                id: 1,
                user_id: 1,
                title: 'New Quest',
                description: 'Description',
                category: 'daily',
                xp_reward: 50,
            };

            dbService.createQuest.mockResolvedValue(mockQuest);

            const response = await request(app)
                .post('/api/quests')
                .set('Authorization', `Bearer ${validToken}`)
                .send({
                    title: 'New Quest',
                    description: 'Description',
                    category: 'daily',
                    xp_reward: 50,
                });

            expect(response.status).toBe(201);
            expect(response.body.success).toBe(true);
            expect(response.body.data.title).toBe('New Quest');
        });

        it('should handle service errors', async () => {
            dbService.createQuest.mockRejectedValue(new Error('DB error'));

            const response = await request(app)
                .post('/api/quests')
                .set('Authorization', `Bearer ${validToken}`)
                .send({
                    title: 'New Quest',
                    description: 'Description',
                    category: 'daily',
                });

            expect(response.status).toBe(500);
            expect(response.body.success).toBe(false);
        });
    });

    describe('POST /api/quests/:id/complete', () => {
        it('should mark quest as completed', async () => {
            dbService.completeQuest.mockResolvedValue({
                message: 'Quest abgeschlossen!',
                xp_earned: 50,
            });

            const response = await request(app)
                .post('/api/quests/1/complete')
                .set('Authorization', `Bearer ${validToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(dbService.completeQuest).toHaveBeenCalledWith('1', 1, undefined);
        });

        it('should handle completion errors', async () => {
            dbService.completeQuest.mockRejectedValue(new Error('Not authorized'));

            const response = await request(app)
                .post('/api/quests/1/complete')
                .set('Authorization', `Bearer ${validToken}`);

            expect(response.status).toBe(500);
            expect(response.body.success).toBe(false);
        });
    });

    describe('GET /api/quests/:id', () => {
        it('should reject when quest is not owned by user', async () => {
            const mockQuest = { id: 1, user_id: 999 };

            dbService.getQuestById.mockResolvedValue(mockQuest);

            const response = await request(app)
                .get('/api/quests/1')
                .set('Authorization', `Bearer ${validToken}`);

            expect(response.status).toBe(403);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('QUEST_UNAUTHORIZED');
        });
    });

    describe('PUT /api/quests/:id', () => {
        it('should update quest when owned', async () => {
            const mockQuest = { id: 1, user_id: 1 };

            dbService.getQuestById.mockResolvedValue(mockQuest);
            dbService.updateQuest.mockResolvedValue({ message: 'Quest erfolgreich aktualisiert' });

            const response = await request(app)
                .put('/api/quests/1')
                .set('Authorization', `Bearer ${validToken}`)
                .send({ title: 'Updated' });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.code).toBe('QUEST_UPDATED');
        });
    });

    describe('DELETE /api/quests/:id', () => {
        it('should delete a quest', async () => {
            const mockQuest = { id: 1, user_id: 1 };

            dbService.getQuestById.mockResolvedValue(mockQuest);
            dbService.deleteQuest.mockResolvedValue({
                message: 'Quest erfolgreich gelöscht',
                changes: 1,
            });

            const response = await request(app)
                .delete('/api/quests/1')
                .set('Authorization', `Bearer ${validToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
        });
    });
});

describe('Stats API Routes', () => {
    let validToken;

    beforeEach(() => {
        jest.clearAllMocks();
        sessionService.isTokenBlacklisted = jest.fn().mockReturnValue(false);
        validToken = jwt.sign(
            { userId: 1, username: 'testuser' },
            JWT_SECRET,
            { expiresIn: '7d' }
        );
    });

    describe('PUT /api/stats', () => {
        it('should update user stats', async () => {
            dbService.updateUserStats.mockResolvedValue({
                message: 'Stats aktualisiert',
                changes: 1,
            });

            const response = await request(app)
                .put('/api/stats')
                .set('Authorization', `Bearer ${validToken}`)
                .send({ total_scans: 10 });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.code).toBe('STATS_UPDATED');
        });

        it('should handle stats update errors', async () => {
            dbService.updateUserStats.mockRejectedValue(new Error('Invalid data'));

            const response = await request(app)
                .put('/api/stats')
                .set('Authorization', `Bearer ${validToken}`)
                .send({ foo: 'bar' });

            expect(response.status).toBe(500);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('SERVER_ERROR');
        });
    });
});
