const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { validate, schemas } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');

router.post('/create-intent', authenticate, validate(schemas.createPaymentIntent), paymentController.createPaymentIntent);
router.post('/confirm', authenticate, paymentController.confirmPayment);
router.post('/webhook', express.raw({ type: 'application/json' }), paymentController.handleWebhook);
router.get('/history', authenticate, paymentController.getPaymentHistory);

module.exports = router;
