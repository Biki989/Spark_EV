// Firebase Cloud Messaging notification service
// NOTE: Requires firebase-admin SDK and a valid service account JSON file

let admin = null;

try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (serviceAccountPath) {
        const firebaseAdmin = require('firebase-admin');
        const fs = require('fs');

        if (fs.existsSync(serviceAccountPath)) {
            const serviceAccount = require(serviceAccountPath);
            firebaseAdmin.initializeApp({
                credential: firebaseAdmin.credential.cert(serviceAccount)
            });
            admin = firebaseAdmin;
            console.log('Firebase Admin initialized successfully');
        } else {
            console.warn('Firebase service account file not found. Push notifications disabled.');
        }
    }
} catch (err) {
    console.warn('Firebase initialization failed:', err.message);
}

const { query } = require('../config/database');

// Send notification to a specific user
const sendToUser = async (userId, title, body, data = {}) => {
    if (!admin) {
        console.log(`[Notification Mock] To user ${userId}: ${title} - ${body}`);
        return;
    }

    try {
        const result = await query('SELECT fcm_token FROM users WHERE id = $1 AND fcm_token IS NOT NULL', [userId]);
        if (result.rows.length === 0 || !result.rows[0].fcm_token) {
            console.log(`No FCM token for user ${userId}`);
            return;
        }

        const message = {
            notification: { title, body },
            data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
            token: result.rows[0].fcm_token
        };

        const response = await admin.messaging().send(message);
        console.log('Notification sent:', response);
        return response;
    } catch (err) {
        console.error('Failed to send notification:', err.message);
    }
};

// Booking confirmation notification
const sendBookingConfirmation = async (userId, bookingDetails) => {
    return sendToUser(userId,
        'Booking Confirmed ⚡',
        `Your charging slot at ${bookingDetails.stationName} is confirmed for ${bookingDetails.startTime}.`,
        { type: 'booking_confirmed', booking_id: bookingDetails.bookingId }
    );
};

// Upcoming charging reminder
const sendUpcomingReminder = async (userId, bookingDetails) => {
    return sendToUser(userId,
        'Charging Starts Soon ⏰',
        `Your charging slot at ${bookingDetails.stationName} starts in 30 minutes.`,
        { type: 'upcoming_slot', booking_id: bookingDetails.bookingId }
    );
};

// Payment success notification
const sendPaymentSuccess = async (userId, amount) => {
    return sendToUser(userId,
        'Payment Successful 💳',
        `CHF ${amount} has been charged successfully.`,
        { type: 'payment_success' }
    );
};

// Booking cancelled notification
const sendBookingCancelled = async (userId, reason) => {
    return sendToUser(userId,
        'Booking Cancelled ❌',
        reason || 'Your booking has been cancelled.',
        { type: 'booking_cancelled' }
    );
};

module.exports = {
    sendToUser,
    sendBookingConfirmation,
    sendUpcomingReminder,
    sendPaymentSuccess,
    sendBookingCancelled
};
