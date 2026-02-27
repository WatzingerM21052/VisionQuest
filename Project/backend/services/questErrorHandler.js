/**
 * Quest Error Handler
 * Standardisierte Fehlerbehandlung für Quest-Operations
 */

const QUEST_ERRORS = {
    QUEST_NOT_FOUND: {
        code: 'QUEST_NOT_FOUND',
        status: 404,
        message: 'Quest nicht gefunden'
    },
    QUEST_UNAUTHORIZED: {
        code: 'QUEST_UNAUTHORIZED',
        status: 403,
        message: 'Nicht autorisiert - Quest gehört dem User nicht'
    },
    INVALID_QUEST_DATA: {
        code: 'INVALID_QUEST_DATA',
        status: 400,
        message: 'Ungültige Quest-Daten'
    },
    QUEST_ALREADY_COMPLETED: {
        code: 'QUEST_ALREADY_COMPLETED',
        status: 400,
        message: 'Quest ist bereits abgeschlossen'
    },
    DETECTION_FAILED: {
        code: 'DETECTION_FAILED',
        status: 400,
        message: 'Objekt-Erkennung fehlgeschlagen'
    },
    DELETE_FAILED: {
        code: 'DELETE_FAILED',
        status: 400,
        message: 'Quest konnte nicht gelöscht werden'
    },
    SERVER_ERROR: {
        code: 'SERVER_ERROR',
        status: 500,
        message: 'Interner Serverfehler'
    }
};

function sendError(res, errorType, details = null) {
    const error = QUEST_ERRORS[errorType] || QUEST_ERRORS.SERVER_ERROR;

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

function handleCatchError(res, error, operation = 'QUEST_OPERATION') {
    console.error(`[QUEST ERROR ${operation}]:`, error.message);
    sendError(res, 'SERVER_ERROR', { details: error.message });
}

function checkQuestOwnership(questUserId, currentUserId) {
    return questUserId === currentUserId;
}

module.exports = {
    QUEST_ERRORS,
    sendError,
    handleCatchError,
    checkQuestOwnership
};
