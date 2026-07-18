const { query } = require('../config/database');

// GET /api/favorites - User's favorites
exports.getFavorites = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT f.id as favorite_id, f.created_at as favorited_at, s.*,
              (SELECT COUNT(*) FROM availability a 
               WHERE a.station_id = s.id AND a.status = 'available' 
               AND a.date >= CURRENT_DATE) as available_slots
       FROM favorites f
       JOIN stations s ON f.station_id = s.id
       WHERE f.user_id = $1
       ORDER BY f.created_at DESC`,
            [req.user.id]
        );
        res.json({ favorites: result.rows });
    } catch (err) {
        next(err);
    }
};

// POST /api/favorites - Add favorite
exports.addFavorite = async (req, res, next) => {
    try {
        const { station_id } = req.body;

        const result = await query(
            `INSERT INTO favorites (user_id, station_id)
       VALUES ($1, $2)
       ON CONFLICT (user_id, station_id) DO NOTHING
       RETURNING *`,
            [req.user.id, station_id]
        );

        if (result.rows.length === 0) {
            return res.status(200).json({ message: 'Already in favorites.' });
        }

        res.status(201).json({ message: 'Added to favorites', favorite: result.rows[0] });
    } catch (err) {
        next(err);
    }
};

// DELETE /api/favorites/:stationId - Remove favorite
exports.removeFavorite = async (req, res, next) => {
    try {
        const result = await query(
            'DELETE FROM favorites WHERE user_id = $1 AND station_id = $2 RETURNING id',
            [req.user.id, req.params.stationId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Favorite not found.' });
        }

        res.json({ message: 'Removed from favorites' });
    } catch (err) {
        next(err);
    }
};
