const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { validate, schemas } = require('../middleware/validate');
const { authenticate, requireRole } = require('../middleware/auth');

router.post('/', authenticate, requireRole('driver'), validate(schemas.createBooking), bookingController.createBooking);
router.get('/', authenticate, bookingController.getUserBookings);
router.get('/:id', authenticate, bookingController.getBooking);
router.post('/:id/cancel', authenticate, bookingController.cancelBooking);

// Owner: View station bookings
router.get('/station/:stationId', authenticate, requireRole('owner', 'admin'), bookingController.getStationBookings);

module.exports = router;
