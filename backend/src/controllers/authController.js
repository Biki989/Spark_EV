const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

const generateToken = (userId, role) => {
    return jwt.sign(
        { userId, role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );
};

// POST /api/auth/register
exports.register = async (req, res, next) => {
    try {
        const { name, email, password, role } = req.body;

        // Check if user exists
        const existing = await query('SELECT id FROM users WHERE email = $1', [email]);
        if (existing.rows.length > 0) {
            return res.status(409).json({ error: 'Email already registered.' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(12);
        const password_hash = await bcrypt.hash(password, salt);

        // Create user
        const result = await query(
            `INSERT INTO users (name, email, password_hash, role) 
       VALUES ($1, $2, $3, $4) 
       RETURNING id, name, email, role, created_at`,
            [name, email, password_hash, role]
        );

        const user = result.rows[0];
        const token = generateToken(user.id, user.role);

        res.status(201).json({
            message: 'Registration successful',
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role }
        });
    } catch (err) {
        next(err);
    }
};

// POST /api/auth/login
exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        const result = await query(
            'SELECT id, name, email, password_hash, role, avatar_url FROM users WHERE email = $1',
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        const user = result.rows[0];

        if (!user.password_hash) {
            return res.status(401).json({ error: 'Please login with Google or Apple.' });
        }

        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        const token = generateToken(user.id, user.role);

        res.json({
            message: 'Login successful',
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role, avatar_url: user.avatar_url }
        });
    } catch (err) {
        next(err);
    }
};

// POST /api/auth/google
exports.googleLogin = async (req, res, next) => {
    try {
        const { google_id, email, name, avatar_url } = req.body;

        // Check if user exists by google_id or email
        let result = await query('SELECT id, name, email, role FROM users WHERE google_id = $1 OR email = $2', [google_id, email]);

        let user;
        if (result.rows.length > 0) {
            user = result.rows[0];
            // Update google_id if not set
            await query('UPDATE users SET google_id = $1, avatar_url = COALESCE(avatar_url, $2) WHERE id = $3', [google_id, avatar_url, user.id]);
        } else {
            // Create new user
            result = await query(
                `INSERT INTO users (name, email, google_id, avatar_url, role) 
         VALUES ($1, $2, $3, $4, 'driver') 
         RETURNING id, name, email, role`,
                [name, email, google_id, avatar_url]
            );
            user = result.rows[0];
        }

        const token = generateToken(user.id, user.role);
        res.json({ message: 'Login successful', token, user });
    } catch (err) {
        next(err);
    }
};

// GET /api/auth/profile
exports.getProfile = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT id, name, email, role, avatar_url, created_at,
              stripe_customer_id, stripe_connect_account_id
       FROM users WHERE id = $1`,
            [req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found.' });
        }

        res.json({ user: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// PUT /api/auth/profile
exports.updateProfile = async (req, res, next) => {
    try {
        const { name, avatar_url, fcm_token } = req.body;
        const updates = [];
        const values = [];
        let paramCount = 0;

        if (name) { paramCount++; updates.push(`name = $${paramCount}`); values.push(name); }
        if (avatar_url !== undefined) { paramCount++; updates.push(`avatar_url = $${paramCount}`); values.push(avatar_url); }
        if (fcm_token) { paramCount++; updates.push(`fcm_token = $${paramCount}`); values.push(fcm_token); }

        if (updates.length === 0) {
            return res.status(400).json({ error: 'No fields to update.' });
        }

        paramCount++;
        values.push(req.user.id);

        const result = await query(
            `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount}
       RETURNING id, name, email, role, avatar_url`,
            values
        );

        res.json({ user: result.rows[0] });
    } catch (err) {
        next(err);
    }
};
