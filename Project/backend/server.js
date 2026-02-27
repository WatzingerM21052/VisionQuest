const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Datenbank initialisieren
const { checkTables } = require('../database/db');
const apiRoutes = require('./routes/api');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log alle Requests
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Health Check Endpoint
app.get('/api/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        message: 'Backend is running',
        timestamp: new Date().toISOString()
    });
});

// API Routes einbinden
app.use('/api', apiRoutes);

// Test GET Endpoint (Legacy für Kompatibilität)
app.get('/api/test', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'GET Request erfolgreich',
        data: {
            timestamp: new Date().toISOString(),
            serverVersion: '1.0.0'
        }
    });
});

// Test POST Endpoint  (Legacy für Kompatibilität)
app.post('/api/test', (req, res) => {
    const { message } = req.body;

    res.status(200).json({
        success: true,
        message: 'POST Request erfolgreich',
        receivedMessage: message,
        data: {
            timestamp: new Date().toISOString(),
            echo: message
        }
    });
});

// 404 Handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint not found',
        path: req.path
    });
});

// Error Handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        success: false,
        message: 'Internal Server Error',
        error: process.env.NODE_ENV === 'development' ? err.message : 'Unknown error'
    });
});

// Server starten
app.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════╗
║         VisionQuest Backend            ║
║         Express Server                 ║
╚════════════════════════════════════════╝

Server läuft auf: http://localhost:${PORT}
Health Check: http://localhost:${PORT}/api/health
Test Endpoint: http://localhost:${PORT}/api/test

${new Date().toISOString()}
  `);
});

// Graceful Shutdown
process.on('SIGINT', () => {
    console.log('\nServer wird beendet...');
    process.exit(0);
});

module.exports = app;
