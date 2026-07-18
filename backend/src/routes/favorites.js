const express = require('express');
const router = express.Router();
const favoriteController = require('../controllers/favoriteController');
const { authenticate, requireRole } = require('../middleware/auth');

router.get('/', authenticate, favoriteController.getFavorites);
router.post('/', authenticate, favoriteController.addFavorite);
router.delete('/:stationId', authenticate, favoriteController.removeFavorite);

module.exports = router;
