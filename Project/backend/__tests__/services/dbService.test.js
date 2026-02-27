const dbService = require('../../services/dbService');
const { db } = require('../../../database/db');
const bcrypt = require('bcryptjs');

// Mock the database
jest.mock('../../../database/db', () => ({
    db: {
        run: jest.fn(),
        get: jest.fn(),
        all: jest.fn(),
    },
}));

describe('dbService - User Operations', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('createUser', () => {
        it('should create a new user successfully', async () => {
            const mockUser = { username: 'testuser', email: 'test@example.com', password: 'password123' };

            db.run.mockImplementation(function (sql, params, callback) {
                if (typeof callback === 'function') {
                    callback.call({ lastID: 1 }, null);
                }
                return this;
            });

            const result = await dbService.createUser(mockUser.username, mockUser.email, mockUser.password);

            expect(result).toEqual({
                id: 1,
                username: 'testuser',
                email: 'test@example.com',
                message: 'User erfolgreich erstellt',
            });
            expect(db.run).toHaveBeenCalledTimes(2); // Once for user, once for stats
        });

        it('should reject when username or email already exists', async () => {
            db.run.mockImplementation((sql, params, callback) => {
                callback(new Error('UNIQUE constraint failed: users.email'));
            });

            await expect(
                dbService.createUser('testuser', 'existing@example.com', 'password123')
            ).rejects.toThrow('Username oder E-Mail bereits vergeben');
        });

        it('should hash the password before storing', async () => {
            db.run.mockImplementation(function (sql, params, callback) {
                if (typeof callback === 'function') {
                    callback.call({ lastID: 1 }, null);
                }
                return this;
            });

            const password = 'mySecretPassword';
            await dbService.createUser('testuser', 'test@example.com', password);

            // Check that the password parameter passed to db.run is hashed
            const callArgs = db.run.mock.calls[0];
            const hashedPassword = callArgs[1][2]; // Third parameter
            expect(hashedPassword).not.toBe(password);
            expect(hashedPassword.length).toBeGreaterThan(20); // Bcrypt hash is long
        });
    });

    describe('getUserByEmail', () => {
        it('should return user when email exists', async () => {
            const mockUser = {
                id: 1,
                username: 'testuser',
                email: 'test@example.com',
                password_hash: 'hashedpassword123',
                level: 1,
                xp: 0,
            };

            db.get.mockImplementation((sql, params, callback) => {
                callback(null, mockUser);
            });

            const result = await dbService.getUserByEmail('test@example.com');

            expect(result).toEqual(mockUser);
            expect(db.get).toHaveBeenCalledWith(
                expect.stringContaining('SELECT'),
                ['test@example.com'],
                expect.any(Function)
            );
        });

        it('should return undefined when user not found', async () => {
            db.get.mockImplementation((sql, params, callback) => {
                callback(null, undefined);
            });

            const result = await dbService.getUserByEmail('nonexistent@example.com');

            expect(result).toBeUndefined();
        });
    });

    describe('getUserById', () => {
        it('should return user data without password', async () => {
            const mockUser = {
                id: 1,
                username: 'testuser',
                email: 'test@example.com',
                level: 1,
                xp: 100,
            };

            db.get.mockImplementation((sql, params, callback) => {
                callback(null, mockUser);
            });

            const result = await dbService.getUserById(1);

            expect(result).toEqual(mockUser);
            expect(result).not.toHaveProperty('password_hash');
        });

        it('should reject when user not found', async () => {
            db.get.mockImplementation((sql, params, callback) => {
                callback(null, undefined);
            });

            await expect(dbService.getUserById(999)).rejects.toThrow('User nicht gefunden');
        });
    });

    describe('deleteUser', () => {
        it('should delete user successfully', async () => {
            db.run.mockImplementation(function (sql, params, callback) {
                callback.call({ changes: 1 }, null);
            });

            const result = await dbService.deleteUser(1);

            expect(result).toEqual({
                message: 'User erfolgreich gelöscht',
                changes: 1,
            });
        });

        it('should reject when user does not exist', async () => {
            db.run.mockImplementation(function (sql, params, callback) {
                callback.call({ changes: 0 }, null);
            });

            await expect(dbService.deleteUser(999)).rejects.toThrow('User nicht gefunden');
        });
    });
});

describe('dbService - Quest Operations', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('createQuest', () => {
        it('should create a quest successfully', async () => {
            db.run.mockImplementation(function (sql, params, callback) {
                callback.call({ lastID: 1 }, null);
            });

            const result = await dbService.createQuest(
                1,
                {
                    title: 'Test Quest',
                    description: 'Description',
                    category: 'daily',
                    difficulty: 'medium',
                    xp_reward: 50,
                }
            );

            expect(result).toHaveProperty('id', 1);
            expect(result).toHaveProperty('title', 'Test Quest');
            expect(result).toHaveProperty('user_id', 1);
            expect(db.run).toHaveBeenCalled();
        });
    });

    describe('getQuestsByUserId', () => {
        it('should return all quests for a user', async () => {
            const mockQuests = [
                { id: 1, user_id: 1, title: 'Quest 1', type: 'daily', xp_value: 50 },
                { id: 2, user_id: 1, title: 'Quest 2', type: 'weekly', xp_value: 100 },
            ];

            db.all.mockImplementation((sql, params, callback) => {
                callback(null, mockQuests);
            });

            const result = await dbService.getQuestsByUserId(1);

            expect(result).toEqual(mockQuests);
            expect(result.length).toBe(2);
        });

        it('should return empty array when user has no quests', async () => {
            db.all.mockImplementation((sql, params, callback) => {
                callback(null, []);
            });

            const result = await dbService.getQuestsByUserId(1);

            expect(result).toEqual([]);
        });
    });

    describe('completeQuest', () => {
        it('should complete a quest and update user stats', async () => {
            const mockQuest = {
                id: 1,
                user_id: 1,
                xp_reward: 200,
                status: 'active',
            };
            const mockUser = {
                id: 1,
                username: 'testuser',
                email: 'test@example.com',
                xp: 300,
                level: 1,
            };

            db.get
                .mockImplementationOnce((sql, params, callback) => {
                    callback(null, mockQuest);
                })
                .mockImplementationOnce((sql, params, callback) => {
                    callback(null, mockUser);
                });

            db.run.mockImplementation((sql, params, callback) => {
                if (typeof callback === 'function') {
                    callback.call({ changes: 1 }, null);
                }
            });

            const result = await dbService.completeQuest(1, 1, 'object');

            expect(result.message).toBe('Quest abgeschlossen!');
            expect(result.xp_earned).toBe(200);
            expect(result.new_xp).toBe(500);
            expect(result.new_level).toBe(1);
        });

        it('should reject when user does not own quest', async () => {
            const mockQuest = {
                id: 1,
                user_id: 2,
                xp_reward: 50,
                status: 'active',
            };

            db.get.mockImplementationOnce((sql, params, callback) => {
                callback(null, mockQuest);
            });

            await expect(dbService.completeQuest(1, 1)).rejects.toThrow(
                'Nicht autorisiert'
            );
        });
    });

    describe('deleteQuest', () => {
        it('should delete quest successfully', async () => {
            db.run.mockImplementation(function (sql, params, callback) {
                callback.call({ changes: 1 }, null);
            });

            const result = await dbService.deleteQuest(1);

            expect(result).toEqual({
                message: 'Quest erfolgreich gelöscht',
                changes: 1,
            });
        });
    });
});

describe('dbService - Stats Operations', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('updateUserStats', () => {
        it('should update stats successfully', async () => {
            db.run.mockImplementation(function (sql, params, callback) {
                callback.call({ changes: 1 }, null);
            });

            const result = await dbService.updateUserStats(1, {
                total_scans: 5,
            });

            expect(result).toEqual({ message: 'Stats aktualisiert', changes: 1 });
        });

        it('should reject when no valid fields are provided', async () => {
            await expect(dbService.updateUserStats(1, { foo: 'bar' })).rejects.toThrow(
                'Keine gültigen Update-Felder'
            );
        });
    });
});

describe('dbService - Update Operations', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('updateUser', () => {
        it('should reject when no valid fields are provided', async () => {
            await expect(dbService.updateUser(1, { foo: 'bar' })).rejects.toThrow(
                'Keine gültigen Update-Felder'
            );
        });
    });

    describe('updateQuest', () => {
        it('should reject when no valid fields are provided', async () => {
            await expect(dbService.updateQuest(1, { foo: 'bar' })).rejects.toThrow(
                'Keine gültigen Update-Felder'
            );
        });
    });
});
