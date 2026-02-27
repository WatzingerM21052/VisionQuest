/**
 * Stats Error Handler
 * Standardisierte Fehlerbehandlung für Stats-Operations
 */

const STATS_ERRORS = {
    STATS_NOT_FOUND: {
        code: 'STATS_NOT_FOUND',
        status: 404,
        message: 'Benutzer-Statistiken nicht gefunden'
    },
    INVALID_STATS_DATA: {
        code: 'INVALID_STATS_DATA',
        status: 400,
        message: 'Ungültige Statistik-Daten'
    },
    UPDATE_FAILED: {
        code: 'UPDATE_FAILED',
        status: 400,
        message: 'Statistiken konnten nicht aktualisiert werden'
    },
    SERVER_ERROR: {
        code: 'SERVER_ERROR',
        status: 500,
        message: 'Interner Serverfehler'
    }
};

function sendError(res, errorType, details = null) {
    const error = STATS_ERRORS[errorType] || STATS_ERRORS.SERVER_ERROR;

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

function handleCatchError(res, error, operation = 'STATS_OPERATION') {
    console.error(`[STATS ERROR ${operation}]:`, error.message);
    sendError(res, 'SERVER_ERROR', { details: error.message });
}

module.exports = {
    STATS_ERRORS,
    sendError,
    handleCatchError
};
