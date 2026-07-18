const { query } = require('../config/database');

// POST /api/reviews - Add review
exports.createReview = async (req, res, next) => {
    try {
        const { station_id, rating, comment } = req.body;

        // Check if user has a completed booking at this station
        const booking = await query(
            `SELECT id FROM bookings 
       WHERE user_id = $1 AND station_id = $2 
       AND status IN ('completed', 'active')
       LIMIT 1`,
            [req.user.id, station_id]
        );

        if (booking.rows.length === 0) {
            return res.status(400).json({ error: 'You can only review stations where you have charged.' });
        }

        const result = await query(
            `INSERT INTO reviews (user_id, station_id, rating, comment)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, station_id) 
       DO UPDATE SET rating = $3, comment = $4
       RETURNING *`,
            [req.user.id, station_id, rating, comment]
        );

        const review = result.rows[0];
        review.user_name = req.user.name;

        res.status(201).json({ review });
    } catch (err) {
        next(err);
    }
};

// GET /api/reviews/station/:id - Station reviews
exports.getStationReviews = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { page = 1, limit = 20 } = req.query;
        const offset = (page - 1) * limit;

        const result = await query(
            `SELECT r.*, u.name as user_name, u.avatar_url
       FROM reviews r JOIN users u ON r.user_id = u.id
       WHERE r.station_id = $1
       ORDER BY r.created_at DESC
       LIMIT $2 OFFSET $3`,
            [id, limit, offset]
        );

        const countResult = await query(
            'SELECT COUNT(*), AVG(rating) as avg_rating FROM reviews WHERE station_id = $1',
            [id]
        );

        res.json({
            reviews: result.rows,
            summary: {
                total: parseInt(countResult.rows[0].count),
                average_rating: parseFloat(countResult.rows[0].avg_rating) || 0
            }
        });
    } catch (err) {
        next(err);
    }
};

// GET /api/reviews/user - User's reviews
exports.getUserReviews = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT r.*, s.name as station_name
       FROM reviews r JOIN stations s ON r.station_id = s.id
       WHERE r.user_id = $1
       ORDER BY r.created_at DESC`,
            [req.user.id]
        );
        res.json({ reviews: result.rows });
    } catch (err) {
        next(err);
    }
};
