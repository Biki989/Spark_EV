const { query } = require('../config/database');

// GET /api/admin/stations - All stations (with pending)
exports.getStations = async (req, res, next) => {
    try {
        const { status } = req.query;
        let sql = `SELECT s.*, u.name as owner_name, u.email as owner_email
               FROM stations s JOIN users u ON s.owner_id = u.id`;
        const params = [];

        if (status) {
            sql += ` WHERE s.verification_status = $1`;
            params.push(status);
        }

        sql += ` ORDER BY s.created_at DESC`;

        const result = await query(sql, params);
        res.json({ stations: result.rows });
    } catch (err) {
        next(err);
    }
};

// POST /api/admin/stations/:id/verify
exports.verifyStation = async (req, res, next) => {
    try {
        const { action } = req.body; // 'verify' or 'reject'
        const newStatus = action === 'verify' ? 'verified' : 'rejected';

        const result = await query(
            `UPDATE stations SET verification_status = $1 WHERE id = $2 RETURNING *`,
            [newStatus, req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Station not found.' });
        }

        res.json({ message: `Station ${newStatus}`, station: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// GET /api/admin/users - All users
exports.getUsers = async (req, res, next) => {
    try {
        const { role, page = 1, limit = 50 } = req.query;
        const offset = (page - 1) * limit;

        let sql = `SELECT id, name, email, role, created_at,
                      (SELECT COUNT(*) FROM bookings WHERE user_id = users.id) as booking_count
               FROM users`;
        const params = [];
        let paramCount = 0;

        if (role) {
            paramCount++;
            sql += ` WHERE role = $${paramCount}`;
            params.push(role);
        }

        sql += ` ORDER BY created_at DESC`;
        paramCount++;
        sql += ` LIMIT $${paramCount}`;
        params.push(limit);
        paramCount++;
        sql += ` OFFSET $${paramCount}`;
        params.push(offset);

        const result = await query(sql, params);

        const countResult = await query('SELECT COUNT(*) FROM users');

        res.json({
            users: result.rows,
            total: parseInt(countResult.rows[0].count)
        });
    } catch (err) {
        next(err);
    }
};

// DELETE /api/admin/users/:id
exports.deleteUser = async (req, res, next) => {
    try {
        const result = await query(
            'DELETE FROM users WHERE id = $1 AND role != $2 RETURNING id, email',
            [req.params.id, 'admin']
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found or cannot delete admin.' });
        }

        res.json({ message: 'User deleted', user: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// DELETE /api/admin/stations/:id
exports.deleteStation = async (req, res, next) => {
    try {
        const result = await query(
            'DELETE FROM stations WHERE id = $1 RETURNING id, name',
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Station not found.' });
        }

        res.json({ message: 'Station deleted', station: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// GET /api/admin/dashboard - Admin stats
exports.getDashboard = async (req, res, next) => {
    try {
        const stats = await query(`
      SELECT 
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM users WHERE role = 'driver') as total_drivers,
        (SELECT COUNT(*) FROM users WHERE role = 'owner') as total_owners,
        (SELECT COUNT(*) FROM stations) as total_stations,
        (SELECT COUNT(*) FROM stations WHERE verification_status = 'pending') as pending_stations,
        (SELECT COUNT(*) FROM bookings) as total_bookings,
        (SELECT COUNT(*) FROM bookings WHERE status = 'confirmed') as active_bookings,
        (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'succeeded') as total_revenue
    `);

        res.json({ dashboard: stats.rows[0] });
    } catch (err) {
        next(err);
    }
};
