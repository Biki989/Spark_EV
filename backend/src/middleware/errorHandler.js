const errorHandler = (err, req, res, next) => {
    console.error('Error:', err);

    // PostgreSQL unique violation
    if (err.code === '23505') {
        return res.status(409).json({ error: 'Resource already exists.' });
    }

    // PostgreSQL foreign key violation
    if (err.code === '23503') {
        return res.status(400).json({ error: 'Referenced resource not found.' });
    }

    // PostgreSQL check constraint violation
    if (err.code === '23514') {
        return res.status(400).json({ error: 'Invalid value provided.' });
    }

    // Stripe errors
    if (err.type && err.type.startsWith('Stripe')) {
        return res.status(400).json({ error: err.message });
    }

    // Default
    const statusCode = err.statusCode || 500;
    const message = process.env.NODE_ENV === 'production'
        ? 'Internal server error'
        : err.message;

    res.status(statusCode).json({ error: message });
};

module.exports = errorHandler;
