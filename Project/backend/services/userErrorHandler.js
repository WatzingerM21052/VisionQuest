/**
 * User Error Handler
 * Standardisierte Fehlerbehandlung für User-Operations
 */

const USER_ERRORS = {
    USER_NOT_FOUND: {
        code: 'USER_NOT_FOUND',
        status: 404,
        message: 'Benutzer nicht gefunden'
    },
    INVALID_UPDATE: {
        code: 'INVALID_UPDATE',
        status: 400,
        message: 'Ungültige Update-Daten'
    },
    DELETE_FAILED: {
        code: 'DELETE_FAILED',
        status: 400,
        message: 'Account konnte nicht gelöscht werden'
    },
    UNAUTHORIZED: {
        code: 'UNAUTHORIZED',
        status: 403,
        message: 'Nicht autorisiert - User-Zugriff verweigert'
    },
    SERVER_ERROR: {
        code: 'SERVER_ERROR',
        status: 500,
        message: 'Interner Serverfehler'
    }
};

function sendError(res, errorType, details = null) {
    const error = USER_ERRORS[errorType] || USER_ERRORS.SERVER_ERROR;

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

function handleCatchError(res, error, operation = 'USER_OPERATION') {
    console.error(`[USER ERROR ${operation}]:`, error.message);
    sendError(res, 'SERVER_ERROR', { details: error.message });
}

module.exports = {
    USER_ERRORS,
    sendError,
    handleCatchError
};
