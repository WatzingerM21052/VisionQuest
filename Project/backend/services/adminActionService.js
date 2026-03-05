/**
 * adminActionService.js
 * Service für Admin-Action Logging und Moderation
 */

const db = require('../database/db');

class AdminActionService {
    /**
     * Log eine Admin-Action
     * @param {number} adminId - Admin User ID
     * @param {string} actionType - Typ der Action (create, update, delete, suspend, unsuspend, export)
     * @param {number} targetUserId - Ziel-User ID (optional)
     * @param {object} details - Details der Action
     * @param {string} status - Status (success, failed)
     */
    static logAction(adminId, actionType, targetUserId, details, status = 'success') {
        return new Promise((resolve, reject) => {
            const detailsJson = JSON.stringify(details || {});
            const sql = `
        INSERT INTO ADMIN_ACTIONS (ADMIN_ID, ACTION_TYPE, TARGET_USER_ID, DETAILS, STATUS)
        VALUES (?, ?, ?, ?, ?)
      `;

            db.run(sql, [adminId, actionType, targetUserId || null, detailsJson, status], function (err) {
                if (err) return reject(err);
                resolve({
                    message: 'Action geloggt',
                    actionId: this.lastID
                });
            });
        });
    }

    /**
     * Get all admin actions (mit Pagination)
     */
    static getAllActions(limit = 100, offset = 0) {
        return new Promise((resolve, reject) => {
            const sql = `
        SELECT 
          a.ID,
          a.ADMIN_ID,
          au.USERNAME as admin_username,
          a.ACTION_TYPE,
          a.TARGET_USER_ID,
          tu.USERNAME as target_username,
          a.DETAILS,
          a.STATUS,
          a.CREATED_AT
        FROM ADMIN_ACTIONS a
        LEFT JOIN USERS au ON a.ADMIN_ID = au.ID
        LEFT JOIN USERS tu ON a.TARGET_USER_ID = tu.ID
        ORDER BY a.CREATED_AT DESC
        LIMIT ? OFFSET ?
      `;

            db.all(sql, [limit, offset], (err, rows) => {
                if (err) return reject(err);

                // Parse JSON details
                const actions = rows.map(row => ({
                    ...row,
                    details: row.DETAILS ? JSON.parse(row.DETAILS) : {}
                }));

                resolve(actions);
            });
        });
    }

    /**
     * Get admin actions für einen spezifischen Admin
     */
    static getAdminActions(adminId, limit = 50) {
        return new Promise((resolve, reject) => {
            const sql = `
        SELECT 
          ID,
          ADMIN_ID,
          ACTION_TYPE,
          TARGET_USER_ID,
          DETAILS,
          STATUS,
          CREATED_AT
        FROM ADMIN_ACTIONS
        WHERE ADMIN_ID = ?
        ORDER BY CREATED_AT DESC
        LIMIT ?
      `;

            db.all(sql, [adminId, limit], (err, rows) => {
                if (err) return reject(err);

                const actions = rows.map(row => ({
                    ...row,
                    details: row.DETAILS ? JSON.parse(row.DETAILS) : {}
                }));

                resolve(actions);
            });
        });
    }

    /**
     * Get actions for a specific target user
     */
    static getUserActions(targetUserId, limit = 50) {
        return new Promise((resolve, reject) => {
            const sql = `
        SELECT 
          a.ID,
          a.ADMIN_ID,
          au.USERNAME as admin_username,
          a.ACTION_TYPE,
          a.DETAILS,
          a.STATUS,
          a.CREATED_AT
        FROM ADMIN_ACTIONS a
        LEFT JOIN USERS au ON a.ADMIN_ID = au.ID
        WHERE a.TARGET_USER_ID = ?
        ORDER BY a.CREATED_AT DESC
        LIMIT ?
      `;

            db.all(sql, [targetUserId, limit], (err, rows) => {
                if (err) return reject(err);

                const actions = rows.map(row => ({
                    ...row,
                    details: row.DETAILS ? JSON.parse(row.DETAILS) : {}
                }));

                resolve(actions);
            });
        });
    }

    /**
     * Suspend einen User
     */
    static suspendUser(userId, suspendedBy, reason) {
        return new Promise((resolve, reject) => {
            const sql = `
        INSERT INTO SUSPENSIONS (USER_ID, SUSPENDED_BY, REASON, IS_ACTIVE)
        VALUES (?, ?, ?, 1)
        ON CONFLICT(USER_ID) DO UPDATE SET
          IS_ACTIVE = 1,
          SUSPENDED_BY = ?,
          REASON = ?,
          SUSPENDED_AT = CURRENT_TIMESTAMP,
          UNSUSPENDED_AT = NULL
      `;

            db.run(sql, [userId, suspendedBy, reason, suspendedBy, reason], function (err) {
                if (err) return reject(err);
                resolve({
                    message: 'User suspendiert',
                    suspensionId: this.lastID
                });
            });
        });
    }

    /**
     * Unsuspend einen User
     */
    static unsuspendUser(userId) {
        return new Promise((resolve, reject) => {
            const sql = `
        UPDATE SUSPENSIONS
        SET IS_ACTIVE = 0, UNSUSPENDED_AT = CURRENT_TIMESTAMP
        WHERE USER_ID = ? AND IS_ACTIVE = 1
      `;

            db.run(sql, [userId], function (err) {
                if (err) return reject(err);

                if (this.changes === 0) {
                    return reject(new Error('User ist nicht suspendiert'));
                }

                resolve({ message: 'User entsperrt' });
            });
        });
    }

    /**
     * Check ob User suspendiert ist
     */
    static isUserSuspended(userId) {
        return new Promise((resolve, reject) => {
            const sql = `
        SELECT ID, REASON, SUSPENDED_AT FROM SUSPENSIONS
        WHERE USER_ID = ? AND IS_ACTIVE = 1
        LIMIT 1
      `;

            db.get(sql, [userId], (err, row) => {
                if (err) return reject(err);
                resolve(row || null);
            });
        });
    }

    /**
     * Get all suspensions
     */
    static getAllSuspensions(includeUnsuspended = false) {
        return new Promise((resolve, reject) => {
            const sql = `
        SELECT 
          s.ID,
          s.USER_ID,
          u.USERNAME,
          u.EMAIL,
          s.SUSPENDED_BY,
          ab.USERNAME as suspended_by_username,
          s.REASON,
          s.SUSPENDED_AT,
          s.UNSUSPENDED_AT,
          s.IS_ACTIVE
        FROM SUSPENSIONS s
        LEFT JOIN USERS u ON s.USER_ID = u.ID
        LEFT JOIN USERS ab ON s.SUSPENDED_BY = ab.ID
        ${includeUnsuspended ? '' : 'WHERE s.IS_ACTIVE = 1'}
        ORDER BY s.SUSPENDED_AT DESC
      `;

            db.all(sql, [], (err, rows) => {
                if (err) return reject(err);
                resolve(rows || []);
            });
        });
    }
}

module.exports = AdminActionService;
