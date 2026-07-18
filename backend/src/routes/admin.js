const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate, requireRole } = require('../middleware/auth');

// All admin routes require admin role
router.use(authenticate, requireRole('admin'));

router.get('/dashboard', adminController.getDashboard);
router.get('/stations', adminController.getStations);
router.post('/stations/:id/verify', adminController.verifyStation);
router.delete('/stations/:id', adminController.deleteStation);
router.get('/users', adminController.getUsers);
router.delete('/users/:id', adminController.deleteUser);

module.exports = router;
