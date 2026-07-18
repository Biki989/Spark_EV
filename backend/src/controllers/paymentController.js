const stripe = require('../config/stripe');
const { query } = require('../config/database');
const { sendPaymentSuccess, sendBookingCancelled } = require('../services/notificationService');

// POST /api/payments/create-intent
exports.createPaymentIntent = async (req, res, next) => {
    try {
        const { booking_id } = req.body;

        // Get booking details
        const booking = await query(
            `SELECT b.*, s.name as station_name, s.owner_id
       FROM bookings b JOIN stations s ON b.station_id = s.id
       WHERE b.id = $1 AND b.user_id = $2 AND b.status = 'confirmed'`,
            [booking_id, req.user.id]
        );

        if (booking.rows.length === 0) {
            return res.status(404).json({ error: 'Booking not found.' });
        }

        const bookingData = booking.rows[0];

        // Ensure user has a Stripe customer ID
        let customerId = req.user.stripe_customer_id;
        if (!customerId) {
            const customer = await stripe.customers.create({
                email: req.user.email,
                name: req.user.name,
                metadata: { user_id: req.user.id }
            });
            customerId = customer.id;
            await query('UPDATE users SET stripe_customer_id = $1 WHERE id = $2', [customerId, req.user.id]);
        }

        // Create payment intent (amount in centimes for CHF)
        const amountInCentimes = Math.round(bookingData.total_amount * 100);

        const paymentIntent = await stripe.paymentIntents.create({
            amount: amountInCentimes,
            currency: 'chf',
            customer: customerId,
            metadata: {
                booking_id: bookingData.id,
                station_name: bookingData.station_name,
                user_id: req.user.id
            },
            description: `EV Charging - ${bookingData.station_name}`
        });

        // Record payment
        const payment = await query(
            `INSERT INTO payments (booking_id, user_id, amount, currency, stripe_payment_intent_id, status)
       VALUES ($1, $2, $3, 'CHF', $4, 'pending')
       RETURNING *`,
            [booking_id, req.user.id, bookingData.total_amount, paymentIntent.id]
        );

        // Link payment to booking
        await query(
            'UPDATE bookings SET payment_id = $1 WHERE id = $2',
            [payment.rows[0].id, booking_id]
        );

        res.json({
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
            amount: bookingData.total_amount,
            currency: 'CHF'
        });
    } catch (err) {
        next(err);
    }
};

// POST /api/payments/confirm
exports.confirmPayment = async (req, res, next) => {
    try {
        const { payment_intent_id } = req.body;

        const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

        if (paymentIntent.status === 'succeeded') {
            await query(
                `UPDATE payments SET status = 'succeeded', stripe_charge_id = $1
         WHERE stripe_payment_intent_id = $2`,
                [paymentIntent.latest_charge, payment_intent_id]
            );

            res.json({ status: 'succeeded', message: 'Payment confirmed.' });
        } else {
            res.json({ status: paymentIntent.status, message: `Payment status: ${paymentIntent.status}` });
        }
    } catch (err) {
        next(err);
    }
};

// POST /api/payments/webhook - Stripe webhook
exports.handleWebhook = async (req, res, next) => {
    const sig = req.headers['stripe-signature'];

    try {
        const event = stripe.webhooks.constructEvent(
            req.body,
            sig,
            process.env.STRIPE_WEBHOOK_SECRET
        );

        switch (event.type) {
            case 'payment_intent.succeeded': {
                const paymentIntent = event.data.object;
                const bookingId = paymentIntent.metadata?.booking_id;
                const userId = paymentIntent.metadata?.user_id;

                // Idempotency: skip if already processed
                const existing = await query(
                    `SELECT status FROM payments WHERE stripe_payment_intent_id = $1`,
                    [paymentIntent.id]
                );
                if (existing.rows.length > 0 && existing.rows[0].status === 'succeeded') {
                    break; // Already processed
                }

                // Update payment status
                await query(
                    `UPDATE payments SET status = 'succeeded', stripe_charge_id = $1
                     WHERE stripe_payment_intent_id = $2`,
                    [paymentIntent.latest_charge, paymentIntent.id]
                );

                // Activate the booking
                if (bookingId) {
                    await query(
                        `UPDATE bookings SET status = 'active' WHERE id = $1 AND status = 'confirmed'`,
                        [bookingId]
                    );
                }

                // Send push notification
                if (userId) {
                    const amount = (paymentIntent.amount / 100).toFixed(2);
                    await sendPaymentSuccess(userId, amount);
                }

                console.log(`✅ Payment succeeded: ${paymentIntent.id} (booking: ${bookingId})`);
                break;
            }

            case 'payment_intent.payment_failed': {
                const failedIntent = event.data.object;
                const failedBookingId = failedIntent.metadata?.booking_id;
                const failedUserId = failedIntent.metadata?.user_id;

                // Idempotency: skip if already processed
                const existingFailed = await query(
                    `SELECT status FROM payments WHERE stripe_payment_intent_id = $1`,
                    [failedIntent.id]
                );
                if (existingFailed.rows.length > 0 && existingFailed.rows[0].status === 'failed') {
                    break;
                }

                // Update payment status
                await query(
                    `UPDATE payments SET status = 'failed' WHERE stripe_payment_intent_id = $1`,
                    [failedIntent.id]
                );

                // Cancel the booking and free availability
                if (failedBookingId) {
                    const cancelledBooking = await query(
                        `UPDATE bookings SET status = 'cancelled' 
                         WHERE id = $1 AND status IN ('confirmed', 'active')
                         RETURNING station_id, port, start_time, end_time`,
                        [failedBookingId]
                    );

                    if (cancelledBooking.rows.length > 0) {
                        const b = cancelledBooking.rows[0];
                        await query(
                            `UPDATE availability SET status = 'available'
                             WHERE station_id = $1 AND port = $2
                             AND date = DATE($3)
                             AND start_time >= ($3)::time AND end_time <= ($4)::time`,
                            [b.station_id, b.port, b.start_time, b.end_time]
                        );
                    }
                }

                // Notify user
                if (failedUserId) {
                    await sendBookingCancelled(
                        failedUserId,
                        'Your payment failed. The booking has been cancelled.'
                    );
                }

                console.log(`❌ Payment failed: ${failedIntent.id} (booking: ${failedBookingId})`);
                break;
            }

            case 'charge.refunded': {
                const charge = event.data.object;
                const paymentIntentId = charge.payment_intent;

                if (paymentIntentId) {
                    // Update payment to refunded
                    await query(
                        `UPDATE payments SET status = 'refunded' WHERE stripe_payment_intent_id = $1`,
                        [paymentIntentId]
                    );

                    // Cancel associated booking
                    const paymentRow = await query(
                        `SELECT booking_id, user_id FROM payments WHERE stripe_payment_intent_id = $1`,
                        [paymentIntentId]
                    );

                    if (paymentRow.rows.length > 0) {
                        const { booking_id, user_id } = paymentRow.rows[0];

                        const cancelledBooking = await query(
                            `UPDATE bookings SET status = 'cancelled'
                             WHERE id = $1 AND status IN ('confirmed', 'active')
                             RETURNING station_id, port, start_time, end_time`,
                            [booking_id]
                        );

                        if (cancelledBooking.rows.length > 0) {
                            const b = cancelledBooking.rows[0];
                            await query(
                                `UPDATE availability SET status = 'available'
                                 WHERE station_id = $1 AND port = $2
                                 AND date = DATE($3)
                                 AND start_time >= ($3)::time AND end_time <= ($4)::time`,
                                [b.station_id, b.port, b.start_time, b.end_time]
                            );
                        }

                        if (user_id) {
                            await sendBookingCancelled(
                                user_id,
                                'Your payment has been refunded and the booking cancelled.'
                            );
                        }
                    }
                }

                console.log(`💰 Charge refunded: ${charge.id}`);
                break;
            }

            case 'charge.dispute.created': {
                const dispute = event.data.object;
                const disputePaymentIntent = dispute.payment_intent;

                if (disputePaymentIntent) {
                    // Flag the payment as disputed (using 'failed' status since schema doesn't have 'disputed')
                    await query(
                        `UPDATE payments SET status = 'failed' WHERE stripe_payment_intent_id = $1`,
                        [disputePaymentIntent]
                    );

                    console.log(`⚠️ Dispute created for payment intent: ${disputePaymentIntent}`);
                }
                break;
            }
        }

        res.json({ received: true });
    } catch (err) {
        console.error('Webhook error:', err.message);
        res.status(400).json({ error: `Webhook Error: ${err.message}` });
    }
};

// GET /api/payments/history - User payment history
exports.getPaymentHistory = async (req, res, next) => {
    try {
        const result = await query(
            `SELECT p.*, b.start_time, b.end_time, s.name as station_name
       FROM payments p
       JOIN bookings b ON p.booking_id = b.id
       JOIN stations s ON b.station_id = s.id
       WHERE p.user_id = $1
       ORDER BY p.created_at DESC`,
            [req.user.id]
        );
        res.json({ payments: result.rows });
    } catch (err) {
        next(err);
    }
};
