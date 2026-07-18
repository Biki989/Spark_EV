const { query, getClient } = require('../config/database');

const MAX_BOOKING_DURATION_HOURS = parseInt(process.env.MAX_BOOKING_DURATION_HOURS) || 4;

// POST /api/bookings - Create booking
exports.createBooking = async (req, res, next) => {
    const client = await getClient();
    try {
        await client.query('BEGIN');

        const { station_id, port, start_time, end_time } = req.body;
        const user_id = req.user.id;
        const startDate = new Date(start_time);
        const endDate = new Date(end_time);
        const now = new Date();

        // ── Validation: reject bookings in the past ──
        if (startDate <= now) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Cannot book a time slot in the past.' });
        }

        // ── Validation: enforce max duration ──
        const durationHours = (endDate - startDate) / (1000 * 60 * 60);
        if (durationHours <= 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'End time must be after start time.' });
        }
        if (durationHours > MAX_BOOKING_DURATION_HOURS) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: `Booking duration cannot exceed ${MAX_BOOKING_DURATION_HOURS} hours.` });
        }

        // ── Lock the station row to prevent deactivation mid-transaction ──
        const station = await client.query(
            `SELECT * FROM stations 
             WHERE id = $1 AND is_active = true AND verification_status = 'verified'
             FOR UPDATE`,
            [station_id]
        );
        if (station.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Station not found or not available.' });
        }

        // ── Validate port number ──
        if (port > station.rows[0].ports) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Invalid port number.' });
        }

        // ── Conflict check with row-level locking (FOR UPDATE) ──
        // Prevents race conditions where two concurrent requests book the same slot
        const conflict = await client.query(
            `SELECT id FROM bookings 
             WHERE station_id = $1 AND port = $2 
             AND status IN ('confirmed', 'active')
             AND start_time < $4 AND end_time > $3
             FOR UPDATE`,
            [station_id, port, start_time, end_time]
        );

        if (conflict.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'Time slot already booked.' });
        }

        // ── Prevent same user from having overlapping bookings ──
        const userOverlap = await client.query(
            `SELECT id FROM bookings 
             WHERE user_id = $1
             AND status IN ('confirmed', 'active')
             AND start_time < $3 AND end_time > $2`,
            [user_id, start_time, end_time]
        );

        if (userOverlap.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'You already have a booking during this time period.' });
        }

        // ── Calculate amount ──
        const estimatedKwh = station.rows[0].power_kw * durationHours;
        const total_amount = (estimatedKwh * station.rows[0].price_per_kwh).toFixed(2);

        // ── Create booking ──
        const result = await client.query(
            `INSERT INTO bookings (user_id, station_id, port, start_time, end_time, total_amount, currency)
             VALUES ($1, $2, $3, $4, $5, $6, 'CHF')
             RETURNING *`,
            [user_id, station_id, port, start_time, end_time, total_amount]
        );

        // ── Update availability status ──
        await client.query(
            `UPDATE availability 
             SET status = 'occupied' 
             WHERE station_id = $1 AND port = $2 
             AND date = DATE($3) 
             AND start_time >= ($3)::time 
             AND end_time <= ($4)::time`,
            [station_id, port, start_time, end_time]
        );

        await client.query('COMMIT');

        const booking = result.rows[0];
        booking.station_name = station.rows[0].name;

        res.status(201).json({
            message: 'Booking confirmed',
            booking
        });
    } catch (err) {
        await client.query('ROLLBACK');
        // Handle the DB exclusion constraint as a user-friendly error
        if (err.code === '23P01') { // exclusion_violation
            return res.status(409).json({ error: 'Time slot already booked.' });
        }
        next(err);
    } finally {
        client.release();
    }
};

// GET /api/bookings - User's bookings
exports.getUserBookings = async (req, res, next) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;
        const offset = (page - 1) * limit;

        let sql = `
      SELECT b.*, s.name as station_name, s.address, s.charger_type, 
             s.power_kw, s.latitude, s.longitude
      FROM bookings b
      JOIN stations s ON b.station_id = s.id
      WHERE b.user_id = $1
    `;
        const params = [req.user.id];
        let paramCount = 1;

        if (status) {
            paramCount++;
            sql += ` AND b.status = $${paramCount}`;
            params.push(status);
        }

        sql += ` ORDER BY b.start_time DESC`;

        paramCount++;
        sql += ` LIMIT $${paramCount}`;
        params.push(limit);

        paramCount++;
        sql += ` OFFSET $${paramCount}`;
        params.push(offset);

        const result = await query(sql, params);
        res.json({ bookings: result.rows });
    } catch (err) {
        next(err);
    }
};

// GET /api/bookings/:id - Booking details
exports.getBooking = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT b.*, s.name as station_name, s.address, s.charger_type,
              s.power_kw, s.price_per_kwh, s.latitude, s.longitude,
              p.status as payment_status, p.stripe_payment_intent_id
       FROM bookings b
       JOIN stations s ON b.station_id = s.id
       LEFT JOIN payments p ON b.payment_id = p.id
       WHERE b.id = $1 AND (b.user_id = $2 OR $3 = 'admin')`,
            [req.params.id, req.user.id, req.user.role]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Booking not found.' });
        }

        res.json({ booking: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// POST /api/bookings/:id/cancel
exports.cancelBooking = async (req, res, next) => {
    try {
        const result = await query(
            `UPDATE bookings SET status = 'cancelled'
       WHERE id = $1 AND user_id = $2 AND status = 'confirmed'
       RETURNING *`,
            [req.params.id, req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Booking not found or cannot be cancelled.' });
        }

        // Free up availability
        const booking = result.rows[0];
        await query(
            `UPDATE availability SET status = 'available'
       WHERE station_id = $1 AND port = $2
       AND date = DATE($3)
       AND start_time >= ($3)::time AND end_time <= ($4)::time`,
            [booking.station_id, booking.port, booking.start_time, booking.end_time]
        );

        res.json({ message: 'Booking cancelled', booking: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// GET /api/bookings/station/:stationId - Station's bookings (for owner)
exports.getStationBookings = async (req, res, next) => {
    try {
        const { stationId } = req.params;

        // Verify ownership
        const station = await query('SELECT owner_id FROM stations WHERE id = $1', [stationId]);
        if (station.rows.length === 0) {
            return res.status(404).json({ error: 'Station not found.' });
        }
        if (station.rows[0].owner_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Not authorized.' });
        }

        const result = await query(
            `SELECT b.*, u.name as user_name, u.email as user_email
       FROM bookings b JOIN users u ON b.user_id = u.id
       WHERE b.station_id = $1
       ORDER BY b.start_time DESC`,
            [stationId]
        );

        res.json({ bookings: result.rows });
    } catch (err) {
        next(err);
    }
};
