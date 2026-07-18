require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./middleware/errorHandler');
const demoMode = require('./middleware/demoMode');
const { startScheduler } = require('./services/bookingScheduler');

const app = express();
const PORT = process.env.PORT || 3000;

// ============================================
// MIDDLEWARE
// ============================================

// Security headers
app.use(helmet());

// CORS
app.use(cors({
    origin: process.env.NODE_ENV === 'production'
        ? ['https://spark-ev.ch']
        : '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute
    max: 100,
    message: { error: 'Too many requests, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});
app.use('/api/', limiter);

// Stricter rate limiting for auth endpoints
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 20,
    message: { error: 'Too many authentication attempts, please try again later.' }
});
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

// Body parsing (except for Stripe webhook which needs raw body)
app.use((req, res, next) => {
    if (req.originalUrl === '/api/payments/webhook') {
        next();
    } else {
        express.json({ limit: '10mb' })(req, res, next);
    }
});
app.use(express.urlencoded({ extended: true }));

// Demo mode (serves mock data when DEMO_MODE=true)
app.use(demoMode);

// ============================================
// ROUTES
// ============================================

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'Spark EV Charging API',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

// API routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/stations', require('./routes/stations'));
app.use('/api/bookings', require('./routes/bookings'));
app.use('/api/payments', require('./routes/payments'));
app.use('/api/reviews', require('./routes/reviews'));
app.use('/api/favorites', require('./routes/favorites'));
app.use('/api/admin', require('./routes/admin'));

// 404 handler
app.use('/api/*', (req, res) => {
    res.status(404).json({ error: 'Endpoint not found.' });
});

// Error handler
app.use(errorHandler);

// ============================================
// START SERVER
// ============================================

app.listen(PORT, () => {
    console.log(`
  ⚡ Spark EV Charging API
  ========================
  Environment: ${process.env.NODE_ENV || 'development'}
  Demo Mode:   ${process.env.DEMO_MODE === 'true' ? '✅ ON (mock data)' : '❌ OFF'}
  Port:        ${PORT}
  Health:      http://localhost:${PORT}/api/health
  ========================
  `);

    // Start booking scheduler (auto-cancel late bookings)
    startScheduler();
});

module.exports = app;
