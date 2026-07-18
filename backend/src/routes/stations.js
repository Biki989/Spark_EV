const express = require('express');
const router = express.Router();
const stationController = require('../controllers/stationController');
const { validate, schemas } = require('../middleware/validate');
const { authenticate, requireRole } = require('../middleware/auth');

// Public routes
router.get('/', validate(schemas.stationQuery, 'query'), stationController.listStations);
router.get('/:id', stationController.getStation);
router.get('/:id/availability', stationController.getAvailability);
router.get('/:id/availability/realtime', stationController.getRealtimeAvailability);

// Owner routes
router.post('/', authenticate, requireRole('owner', 'admin'), validate(schemas.createStation), stationController.createStation);
router.put('/:id', authenticate, requireRole('owner', 'admin'), validate(schemas.updateStation), stationController.updateStation);
router.put('/:id/availability', authenticate, requireRole('owner', 'admin'), validate(schemas.updateAvailability), stationController.updateAvailability);

// Owner dashboard
router.get('/owner/my-stations', authenticate, requireRole('owner'), stationController.getOwnerStations);
router.get('/owner/dashboard', authenticate, requireRole('owner'), stationController.getOwnerDashboard);

module.exports = router;
