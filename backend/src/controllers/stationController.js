const { query } = require('../config/database');

// GET /api/stations - List stations with geo filtering (optimized with bounding-box pre-filter)
exports.listStations = async (req, res, next) => {
    try {
        const { latitude, longitude, charger_type, min_power, max_price, page, limit } = req.query;
        // Default radius to 10km when coordinates are provided
        const radius = req.query.radius || (latitude && longitude ? 10 : null);
        const offset = (page - 1) * limit;

        let sql = `
      SELECT s.*, 
             u.name as owner_name,
             (SELECT COUNT(*) FROM availability a 
              WHERE a.station_id = s.id AND a.status = 'available' 
              AND a.date >= CURRENT_DATE
              AND (a.date > CURRENT_DATE OR a.start_time >= CURRENT_TIME)) as available_slots
    `;
        const params = [];
        let paramCount = 0;

        // Haversine distance calculation if coordinates provided
        if (latitude && longitude) {
            paramCount += 2;
            sql += `,
        (6371 * acos(
          LEAST(1.0, cos(radians($1)) * cos(radians(s.latitude)) *
          cos(radians(s.longitude) - radians($2)) +
          sin(radians($1)) * sin(radians(s.latitude)))
        )) AS distance
      `;
            params.push(latitude, longitude);
        }

        sql += ` FROM stations s JOIN users u ON s.owner_id = u.id WHERE s.is_active = true AND s.verification_status = 'verified'`;

        // ── Bounding-box pre-filter (index-friendly) ──
        // Calculates a lat/lng rectangle that encloses the search circle,
        // eliminating most rows before the expensive Haversine trig runs.
        if (latitude && longitude && radius) {
            const lat = parseFloat(latitude);
            const lng = parseFloat(longitude);
            const r = parseFloat(radius);

            // 1 degree latitude ≈ 111.32 km
            const latDelta = r / 111.32;
            // 1 degree longitude varies by latitude
            const lngDelta = r / (111.32 * Math.cos(lat * Math.PI / 180));

            const minLat = lat - latDelta;
            const maxLat = lat + latDelta;
            const minLng = lng - lngDelta;
            const maxLng = lng + lngDelta;

            paramCount++;
            sql += ` AND s.latitude >= $${paramCount}`;
            params.push(minLat);

            paramCount++;
            sql += ` AND s.latitude <= $${paramCount}`;
            params.push(maxLat);

            paramCount++;
            sql += ` AND s.longitude >= $${paramCount}`;
            params.push(minLng);

            paramCount++;
            sql += ` AND s.longitude <= $${paramCount}`;
            params.push(maxLng);

            // Precise Haversine filter within the bounding box
            paramCount++;
            sql += ` AND (6371 * acos(
        LEAST(1.0, cos(radians($1)) * cos(radians(s.latitude)) *
        cos(radians(s.longitude) - radians($2)) +
        sin(radians($1)) * sin(radians(s.latitude)))
      )) <= $${paramCount}`;
            params.push(r);
        }

        // Charger type filter
        if (charger_type) {
            paramCount++;
            sql += ` AND s.charger_type = $${paramCount}`;
            params.push(charger_type);
        }

        // Minimum power filter
        if (min_power) {
            paramCount++;
            sql += ` AND s.power_kw >= $${paramCount}`;
            params.push(min_power);
        }

        // Maximum price filter
        if (max_price) {
            paramCount++;
            sql += ` AND s.price_per_kwh <= $${paramCount}`;
            params.push(max_price);
        }

        // Order by distance if coordinates provided, otherwise by rating
        if (latitude && longitude) {
            sql += ` ORDER BY distance ASC`;
        } else {
            sql += ` ORDER BY s.rating DESC, s.created_at DESC`;
        }

        paramCount++;
        sql += ` LIMIT $${paramCount}`;
        params.push(limit);

        paramCount++;
        sql += ` OFFSET $${paramCount}`;
        params.push(offset);

        const result = await query(sql, params);

        // Get total count for pagination
        let countSql = `SELECT COUNT(*) FROM stations s WHERE s.is_active = true AND s.verification_status = 'verified'`;
        const countResult = await query(countSql);

        res.json({
            stations: result.rows,
            pagination: {
                page: parseInt(page) || 1,
                limit: parseInt(limit) || 20,
                total: parseInt(countResult.rows[0].count)
            }
        });
    } catch (err) {
        next(err);
    }
};

// GET /api/stations/:id - Station details
exports.getStation = async (req, res, next) => {
    try {
        const { id } = req.params;

        const result = await query(
            `SELECT s.*, u.name as owner_name
       FROM stations s JOIN users u ON s.owner_id = u.id
       WHERE s.id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Station not found.' });
        }

        // Get reviews
        const reviews = await query(
            `SELECT r.*, u.name as user_name, u.avatar_url
       FROM reviews r JOIN users u ON r.user_id = u.id
       WHERE r.station_id = $1
       ORDER BY r.created_at DESC LIMIT 10`,
            [id]
        );

        const station = result.rows[0];
        station.reviews = reviews.rows;

        res.json({ station });
    } catch (err) {
        next(err);
    }
};

// POST /api/stations - Create station (owner)
exports.createStation = async (req, res, next) => {
    try {
        const { name, address, latitude, longitude, charger_type, power_kw, price_per_kwh, ports, photos } = req.body;

        const result = await query(
            `INSERT INTO stations (owner_id, name, address, latitude, longitude, charger_type, power_kw, price_per_kwh, ports, photos)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
            [req.user.id, name, address, latitude, longitude, charger_type, power_kw, price_per_kwh, ports, photos || []]
        );

        // Auto-generate availability slots for the next 7 days
        const station = result.rows[0];
        const slots = [];
        for (let day = 0; day < 7; day++) {
            for (let port = 1; port <= ports; port++) {
                for (let hour = 6; hour < 22; hour++) {
                    slots.push(`('${station.id}', ${port}, CURRENT_DATE + ${day}, '${hour}:00', '${hour + 1}:00', 'available')`);
                }
            }
        }

        if (slots.length > 0) {
            await query(`INSERT INTO availability (station_id, port, date, start_time, end_time, status) VALUES ${slots.join(',')}`);
        }

        res.status(201).json({ message: 'Station created. Pending verification.', station });
    } catch (err) {
        next(err);
    }
};

// PUT /api/stations/:id - Update station (owner)
exports.updateStation = async (req, res, next) => {
    try {
        const { id } = req.params;

        // Check ownership
        const existing = await query('SELECT owner_id FROM stations WHERE id = $1', [id]);
        if (existing.rows.length === 0) {
            return res.status(404).json({ error: 'Station not found.' });
        }
        if (existing.rows[0].owner_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Not authorized to update this station.' });
        }

        const fields = req.body;
        const updates = [];
        const values = [];
        let paramCount = 0;

        for (const [key, value] of Object.entries(fields)) {
            paramCount++;
            updates.push(`${key} = $${paramCount}`);
            values.push(value);
        }

        if (updates.length === 0) {
            return res.status(400).json({ error: 'No fields to update.' });
        }

        paramCount++;
        values.push(id);

        const result = await query(
            `UPDATE stations SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`,
            values
        );

        res.json({ station: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// GET /api/stations/:id/availability
exports.getAvailability = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { date } = req.query;

        let sql = `SELECT * FROM availability WHERE station_id = $1`;
        const params = [id];

        if (date) {
            sql += ` AND date = $2`;
            params.push(date);
        } else {
            sql += ` AND date >= CURRENT_DATE AND date <= CURRENT_DATE + 7`;
        }

        sql += ` ORDER BY date, port, start_time`;

        const result = await query(sql, params);

        // Summary count
        const available_count = result.rows.filter(r => r.status === 'available').length;
        const total_count = result.rows.length;

        res.json({ availability: result.rows, available_count, total_count });
    } catch (err) {
        next(err);
    }
};

// GET /api/stations/:id/availability/realtime - Real-time slot availability snapshot
exports.getRealtimeAvailability = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { date } = req.query;
        const targetDate = date || new Date().toISOString().split('T')[0];

        // Get station port count
        const stationResult = await query('SELECT ports FROM stations WHERE id = $1', [id]);
        if (stationResult.rows.length === 0) {
            return res.status(404).json({ error: 'Station not found.' });
        }
        const totalPorts = stationResult.rows[0].ports;

        // Get availability grouped by port with slot details
        const result = await query(
            `SELECT port,
                    COUNT(*) FILTER (WHERE status = 'available') as available,
                    COUNT(*) FILTER (WHERE status = 'occupied') as occupied,
                    COUNT(*) FILTER (WHERE status = 'maintenance') as maintenance,
                    COUNT(*) as total,
                    json_agg(
                        json_build_object(
                            'start_time', start_time,
                            'end_time', end_time,
                            'status', status
                        ) ORDER BY start_time
                    ) as slots
             FROM availability
             WHERE station_id = $1 AND date = $2
             GROUP BY port
             ORDER BY port`,
            [id, targetDate]
        );

        // Build response with all ports (even those with no availability rows)
        const ports = [];
        for (let p = 1; p <= totalPorts; p++) {
            const portData = result.rows.find(r => r.port === p);
            ports.push({
                port: p,
                total: portData ? parseInt(portData.total) : 0,
                available: portData ? parseInt(portData.available) : 0,
                occupied: portData ? parseInt(portData.occupied) : 0,
                maintenance: portData ? parseInt(portData.maintenance) : 0,
                slots: portData ? portData.slots : []
            });
        }

        const totalAvailable = ports.reduce((sum, p) => sum + p.available, 0);
        const totalSlots = ports.reduce((sum, p) => sum + p.total, 0);

        res.json({
            station_id: id,
            date: targetDate,
            summary: {
                total_slots: totalSlots,
                available: totalAvailable,
                occupied: totalSlots - totalAvailable,
                utilization_pct: totalSlots > 0 ? Math.round((1 - totalAvailable / totalSlots) * 100) : 0
            },
            ports
        });
    } catch (err) {
        next(err);
    }
};

// PUT /api/stations/:id/availability - Update availability (owner)
exports.updateAvailability = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { port, date, start_time, end_time, status } = req.body;

        // Check ownership
        const station = await query('SELECT owner_id FROM stations WHERE id = $1', [id]);
        if (station.rows.length === 0) {
            return res.status(404).json({ error: 'Station not found.' });
        }
        if (station.rows[0].owner_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Not authorized.' });
        }

        const result = await query(
            `INSERT INTO availability (station_id, port, date, start_time, end_time, status)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (station_id, port, date, start_time)
       DO UPDATE SET status = $6, end_time = $5
       RETURNING *`,
            [id, port, date, start_time, end_time, status]
        );

        res.json({ availability: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// GET /api/stations/owner/my-stations - Owner's stations
exports.getOwnerStations = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT s.*,
              (SELECT COUNT(*) FROM bookings b WHERE b.station_id = s.id AND b.status = 'confirmed') as active_bookings,
              (SELECT COALESCE(SUM(p.amount), 0) FROM payments p 
               JOIN bookings b ON p.booking_id = b.id 
               WHERE b.station_id = s.id AND p.status = 'succeeded'
               AND p.created_at >= CURRENT_DATE) as today_earnings
       FROM stations s WHERE s.owner_id = $1
       ORDER BY s.created_at DESC`,
            [req.user.id]
        );
        res.json({ stations: result.rows });
    } catch (err) {
        next(err);
    }
};

// GET /api/stations/owner/dashboard - Owner dashboard stats
exports.getOwnerDashboard = async (req, res, next) => {
    try {
        const stats = await query(
            `SELECT 
        (SELECT COUNT(*) FROM stations WHERE owner_id = $1) as total_stations,
        (SELECT COUNT(*) FROM stations WHERE owner_id = $1 AND is_active = true) as active_stations,
        (SELECT COUNT(*) FROM bookings b JOIN stations s ON b.station_id = s.id 
         WHERE s.owner_id = $1) as total_bookings,
        (SELECT COUNT(*) FROM bookings b JOIN stations s ON b.station_id = s.id 
         WHERE s.owner_id = $1 AND b.status = 'confirmed') as active_bookings,
        (SELECT COALESCE(SUM(p.amount), 0) FROM payments p 
         JOIN bookings b ON p.booking_id = b.id
         JOIN stations s ON b.station_id = s.id
         WHERE s.owner_id = $1 AND p.status = 'succeeded') as total_earnings,
        (SELECT COALESCE(SUM(p.amount), 0) FROM payments p 
         JOIN bookings b ON p.booking_id = b.id
         JOIN stations s ON b.station_id = s.id
         WHERE s.owner_id = $1 AND p.status = 'succeeded'
         AND p.created_at >= CURRENT_DATE) as today_earnings`,
            [req.user.id]
        );

        // Get earnings for last 7 days
        const dailyEarnings = await query(
            `SELECT DATE(p.created_at) as date, SUM(p.amount) as earnings
       FROM payments p
       JOIN bookings b ON p.booking_id = b.id
       JOIN stations s ON b.station_id = s.id
       WHERE s.owner_id = $1 AND p.status = 'succeeded'
       AND p.created_at >= CURRENT_DATE - 7
       GROUP BY DATE(p.created_at)
       ORDER BY date`,
            [req.user.id]
        );

        res.json({
            dashboard: stats.rows[0],
            daily_earnings: dailyEarnings.rows
        });
    } catch (err) {
        next(err);
    }
};
