/**
 * Auth Error Handler
 * Standardisierte Fehlerbehandlung für Auth
 */

// Error Codes
const AUTH_ERRORS = {
    NO_TOKEN: {
        code: 'NO_TOKEN',
        status: 401,
        message: 'Nicht autorisiert - kein Token vorhanden'
    },
    TOKEN_EXPIRED: {
        code: 'TOKEN_EXPIRED',
        status: 401,
        message: 'Token abgelaufen'
    },
    INVALID_TOKEN: {
        code: 'INVALID_TOKEN',
        status: 403,
        message: 'Token ungültig'
    },
    TOKEN_REVOKED: {
        code: 'TOKEN_REVOKED',
        status: 401,
        message: 'Token wurde widerrufen (Logout)'
    },
    INVALID_CREDENTIALS: {
        code: 'INVALID_CREDENTIALS',
        status: 401,
        message: 'Ungültige E-Mail oder Passwort'
    },
    MISSING_FIELDS: {
        code: 'MISSING_FIELDS',
        status: 400,
        message: 'Erforderliche Felder fehlen'
    },
    PASSWORD_TOO_SHORT: {
        code: 'PASSWORD_TOO_SHORT',
        status: 400,
        message: 'Passwort muss mindestens 6 Zeichen lang sein'
    },
    USER_EXISTS: {
        code: 'USER_EXISTS',
        status: 409,
        message: 'Benutzer existiert bereits'
    },
    SERVER_ERROR: {
        code: 'SERVER_ERROR',
        status: 500,
        message: 'Interner Serverfehler'
    }
};

/**
 * Standardisierte Error Response
 */
function sendError(res, errorType, details = null) {
    const error = AUTH_ERRORS[errorType] || AUTH_ERRORS.SERVER_ERROR;

    const response = {
        success: false,
        code: error.code,
        message: error.message
    };

    if (details) {
        response.details = details;
    }

    res.status(error.status).json(response);
}

/**
 * Error Handler für Try-Catch Blöcke
 */
function handleCatchError(res, error, errorType = 'SERVER_ERROR') {
    console.error(`[AUTH ERROR ${errorType}]:`, error.message);

    if (error.code === 11000) {
        // MongoDB Duplicate Key Error
        return sendError(res, 'USER_EXISTS', { field: Object.keys(error.keyPattern)[0] });
    }

    sendError(res, errorType, { details: error.message });
}

/**
 * Validierung von Auth Input
 */
function validateRegisterInput(username, email, password) {
    const errors = [];

    if (!username || !email || !password) {
        errors.push('Alle Felder sind erforderlich');
    }

    if (password && password.length < 6) {
        errors.push('Passwort muss mindestens 6 Zeichen lang sein');
    }

    if (email && !email.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) {
        errors.push('Ungültiges E-Mail Format');
    }

    return errors;
}

/**
 * Validierung von Login Input
 */
function validateLoginInput(email, password) {
    const errors = [];

    if (!email || !password) {
        errors.push('E-Mail und Passwort sind erforderlich');
    }

    return errors;
}

module.exports = {
    AUTH_ERRORS,
    sendError,
    handleCatchError,
    validateRegisterInput,
    validateLoginInput
};
