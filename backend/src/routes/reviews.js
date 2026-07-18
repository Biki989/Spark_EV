const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { validate, schemas } = require('../middleware/validate');
const { authenticate, requireRole } = require('../middleware/auth');

router.post('/', authenticate, requireRole('driver'), validate(schemas.createReview), reviewController.createReview);
router.get('/station/:id', reviewController.getStationReviews);
router.get('/user', authenticate, reviewController.getUserReviews);

module.exports = router;
