const cron = require('node-cron');
const { query } = require('../config/database');
const { sendBookingCancelled, sendUpcomingReminder } = require('./notificationService');

const LATE_CANCEL_MINUTES = parseInt(process.env.BOOKING_LATE_CANCEL_MINUTES) || 15;

// Auto-cancel bookings where user is more than 15 minutes late
const cancelLateBookings = async () => {
    try {
        const result = await query(
            `UPDATE bookings 
       SET status = 'no_show'
       WHERE status = 'confirmed'
       AND start_time + INTERVAL '${LATE_CANCEL_MINUTES} minutes' < NOW()
       RETURNING id, user_id, station_id`
        );

        for (const booking of result.rows) {
            console.log(`Auto-cancelled booking ${booking.id} (no-show)`);

            // Free up availability
            await query(
                `UPDATE availability SET status = 'available'
         WHERE station_id = $1
         AND date = CURRENT_DATE
         AND status = 'occupied'`,
                [booking.station_id]
            );

            // Notify user
            await sendBookingCancelled(
                booking.user_id,
                `Your booking was cancelled because you were more than ${LATE_CANCEL_MINUTES} minutes late.`
            );
        }

        if (result.rows.length > 0) {
            console.log(`Auto-cancelled ${result.rows.length} late bookings`);
        }
    } catch (err) {
        console.error('Error in cancelLateBookings:', err.message);
    }
};

// Send reminders for upcoming bookings (30 min before)
const sendUpcomingReminders = async () => {
    try {
        const result = await query(
            `SELECT b.id, b.user_id, b.start_time, s.name as station_name
       FROM bookings b
       JOIN stations s ON b.station_id = s.id
       WHERE b.status = 'confirmed'
       AND b.start_time BETWEEN NOW() + INTERVAL '25 minutes' AND NOW() + INTERVAL '35 minutes'`
        );

        for (const booking of result.rows) {
            await sendUpcomingReminder(booking.user_id, {
                bookingId: booking.id,
                stationName: booking.station_name,
                startTime: booking.start_time
            });
        }
    } catch (err) {
        console.error('Error sending reminders:', err.message);
    }
};

// Start scheduled jobs
const startScheduler = () => {
    // Run every 5 minutes - cancel late bookings
    cron.schedule('*/5 * * * *', cancelLateBookings);

    // Run every 10 minutes - send upcoming reminders
    cron.schedule('*/10 * * * *', sendUpcomingReminders);

    console.log('Booking scheduler started (late cancellation: every 5min, reminders: every 10min)');
};

module.exports = { startScheduler, cancelLateBookings, sendUpcomingReminders };
