// Demo Mode Middleware
// When DEMO_MODE=true, intercepts API calls and returns mock data
// This allows the app to run without PostgreSQL

const jwt = require('jsonwebtoken');

const DEMO_USER = {
    id: 'demo-user-001',
    name: 'Alex Demo',
    email: 'demo@spark.ch',
    role: 'driver',
    phone: '+41791234567',
    created_at: new Date().toISOString(),
};

const DEMO_OWNER = {
    id: 'demo-owner-001',
    name: 'Station Owner',
    email: 'owner@spark.ch',
    role: 'owner',
    phone: '+41799876543',
    created_at: new Date().toISOString(),
};

const DEMO_STATIONS = [
    {
        id: 'station-001',
        owner_id: 'demo-owner-001',
        name: 'Zürich Central Charging Hub',
        address: 'Bahnhofstrasse 42, 8001 Zürich',
        latitude: 47.3769,
        longitude: 8.5417,
        charger_type: 'CCS',
        power_kw: 150,
        price_per_kwh: 0.45,
        ports: 4,
        status: 'active',
        rating: 4.7,
        review_count: 23,
        distance: 0.8,
        available_slots: 3,
    },
    {
        id: 'station-002',
        owner_id: 'demo-owner-001',
        name: 'Bern Tesla Supercharger',
        address: 'Bundesplatz 1, 3011 Bern',
        latitude: 46.9480,
        longitude: 7.4474,
        charger_type: 'Tesla',
        power_kw: 250,
        price_per_kwh: 0.55,
        ports: 8,
        status: 'active',
        rating: 4.9,
        review_count: 45,
        distance: 1.2,
        available_slots: 5,
    },
    {
        id: 'station-003',
        owner_id: 'demo-owner-001',
        name: 'Lausanne Type2 Station',
        address: 'Place de la Gare 5, 1003 Lausanne',
        latitude: 46.5197,
        longitude: 6.6323,
        charger_type: 'Type2',
        power_kw: 22,
        price_per_kwh: 0.35,
        ports: 2,
        status: 'active',
        rating: 4.2,
        review_count: 12,
        distance: 2.5,
        available_slots: 1,
    },
    {
        id: 'station-004',
        owner_id: 'demo-owner-001',
        name: 'Geneva Fast Charger',
        address: 'Rue du Mont-Blanc 18, 1201 Genève',
        latitude: 46.2044,
        longitude: 6.1432,
        charger_type: 'CHAdeMO',
        power_kw: 50,
        price_per_kwh: 0.40,
        ports: 2,
        status: 'active',
        rating: 3.8,
        review_count: 8,
        distance: 3.1,
        available_slots: 0,
    },
    {
        id: 'station-005',
        owner_id: 'demo-owner-001',
        name: 'Basel CCS Ultra-Rapid',
        address: 'Marktplatz 10, 4001 Basel',
        latitude: 47.5596,
        longitude: 7.5886,
        charger_type: 'CCS',
        power_kw: 350,
        price_per_kwh: 0.65,
        ports: 6,
        status: 'active',
        rating: 4.5,
        review_count: 31,
        distance: 4.2,
        available_slots: 4,
    },
    {
        id: 'station-006',
        owner_id: 'demo-owner-001',
        name: 'Luzern Lakeside Charging',
        address: 'Seebrücke 3, 6003 Luzern',
        latitude: 47.0502,
        longitude: 8.3093,
        charger_type: 'Type2',
        power_kw: 43,
        price_per_kwh: 0.38,
        ports: 3,
        status: 'active',
        rating: 4.6,
        review_count: 19,
        distance: 5.7,
        available_slots: 2,
    },
];

const now = new Date();
const tomorrow = new Date(now.getTime() + 86400000);

const DEMO_BOOKINGS = [
    {
        id: 'booking-001',
        user_id: 'demo-user-001',
        station_id: 'station-001',
        port: 1,
        start_time: new Date(tomorrow.setHours(10, 0, 0, 0)).toISOString(),
        end_time: new Date(tomorrow.setHours(11, 0, 0, 0)).toISOString(),
        status: 'confirmed',
        total_amount: '67.50',
        currency: 'CHF',
        station_name: 'Zürich Central Charging Hub',
        address: 'Bahnhofstrasse 42, 8001 Zürich',
        charger_type: 'CCS',
        power_kw: 150,
    },
    {
        id: 'booking-002',
        user_id: 'demo-user-001',
        station_id: 'station-002',
        port: 3,
        start_time: new Date(Date.now() - 86400000 * 3).toISOString(),
        end_time: new Date(Date.now() - 86400000 * 3 + 3600000).toISOString(),
        status: 'completed',
        total_amount: '137.50',
        currency: 'CHF',
        station_name: 'Bern Tesla Supercharger',
        address: 'Bundesplatz 1, 3011 Bern',
        charger_type: 'Tesla',
        power_kw: 250,
        payment_id: 'pay-001',
    },
];

const DEMO_REVIEWS = [
    { id: 'review-001', user_id: 'demo-user-001', station_id: 'station-001', rating: 5, comment: 'Super fast charging! Great location right next to the train station.', user_name: 'Alex Demo', station_name: 'Zürich Central Charging Hub', created_at: new Date().toISOString() },
    { id: 'review-002', user_id: 'demo-user-002', station_id: 'station-001', rating: 4, comment: 'Good charger but gets busy during rush hours.', user_name: 'Marie Schmidt', station_name: 'Zürich Central Charging Hub', created_at: new Date().toISOString() },
    { id: 'review-003', user_id: 'demo-user-001', station_id: 'station-002', rating: 5, comment: 'Amazing Tesla Supercharger. 250kW is lightning fast!', user_name: 'Alex Demo', station_name: 'Bern Tesla Supercharger', created_at: new Date().toISOString() },
];

function generateToken(userId, role) {
    return jwt.sign({ userId, role }, process.env.JWT_SECRET || 'spark-dev-secret-key-replace-in-production-2024', { expiresIn: '7d' });
}

function getAvailability(stationId) {
    const station = DEMO_STATIONS.find(s => s.id === stationId);
    if (!station) return [];
    const slots = [];
    const today = new Date();
    for (let d = 0; d < 7; d++) {
        const date = new Date(today.getTime() + d * 86400000);
        const dateStr = date.toISOString().split('T')[0];
        for (let h = 8; h < 22; h++) {
            for (let p = 1; p <= station.ports; p++) {
                slots.push({
                    date: dateStr,
                    start_time: `${h.toString().padStart(2, '0')}:00`,
                    end_time: `${(h + 1).toString().padStart(2, '0')}:00`,
                    port: p,
                    status: Math.random() > 0.3 ? 'available' : 'booked',
                });
            }
        }
    }
    return slots;
}

function demoMode(req, res, next) {
    if (process.env.DEMO_MODE !== 'true') return next();

    const path = req.path;
    const method = req.method;

    // Health
    if (path === '/api/health') return next();

    // AUTH
    if (path === '/api/auth/register' && method === 'POST') {
        const user = { ...DEMO_USER, name: req.body.name || 'Demo User', email: req.body.email || 'demo@spark.ch', role: req.body.role || 'driver' };
        return res.status(201).json({ user, token: generateToken(user.id, user.role) });
    }
    if (path === '/api/auth/login' && method === 'POST') {
        const user = req.body.email === 'owner@spark.ch' ? DEMO_OWNER : DEMO_USER;
        return res.json({ user, token: generateToken(user.id, user.role) });
    }
    if (path === '/api/auth/profile' && method === 'GET') {
        return res.json({ user: DEMO_USER });
    }

    // Inject demo user for authenticated routes
    req.user = DEMO_USER;

    // STATIONS
    if (path === '/api/stations' && method === 'GET') {
        return res.json({ stations: DEMO_STATIONS, total: DEMO_STATIONS.length, page: 1, limit: 20 });
    }
    if (path.match(/^\/api\/stations\/[^/]+$/) && method === 'GET') {
        const id = path.split('/').pop();
        const station = DEMO_STATIONS.find(s => s.id === id) || DEMO_STATIONS[0];
        return res.json({ station });
    }
    if (path.match(/^\/api\/stations\/[^/]+\/availability$/) && method === 'GET') {
        const id = path.split('/')[3];
        return res.json({ availability: getAvailability(id) });
    }
    if (path === '/api/stations' && method === 'POST') {
        return res.status(201).json({ station: { id: 'station-new', ...req.body, status: 'pending', rating: 0, review_count: 0 } });
    }
    if (path === '/api/stations/owner/dashboard' && method === 'GET') {
        return res.json({
            dashboard: { total_stations: 6, active_bookings: 3, today_earnings: '245.50', total_earnings: '12450.00' },
            daily_earnings: Array.from({ length: 7 }, (_, i) => ({
                date: new Date(Date.now() - (6 - i) * 86400000).toISOString().split('T')[0],
                earnings: (Math.random() * 300 + 100).toFixed(2),
            })),
        });
    }

    // BOOKINGS
    if (path === '/api/bookings' && method === 'GET') {
        return res.json({ bookings: DEMO_BOOKINGS });
    }
    if (path === '/api/bookings' && method === 'POST') {
        const station = DEMO_STATIONS.find(s => s.id === req.body.station_id) || DEMO_STATIONS[0];
        const newBooking = {
            id: `booking-${Date.now()}`,
            user_id: 'demo-user-001',
            station_id: req.body.station_id,
            port: req.body.port || 1,
            start_time: req.body.start_time,
            end_time: req.body.end_time,
            status: 'confirmed',
            total_amount: (station.power_kw * station.price_per_kwh).toFixed(2),
            currency: 'CHF',
            station_name: station.name,
            address: station.address,
            charger_type: station.charger_type,
            power_kw: station.power_kw,
        };
        return res.status(201).json({ booking: newBooking });
    }
    if (path.match(/^\/api\/bookings\/[^/]+\/cancel$/) && method === 'POST') {
        return res.json({ booking: { ...DEMO_BOOKINGS[0], status: 'cancelled' } });
    }

    // PAYMENTS
    if (path === '/api/payments/create-intent' && method === 'POST') {
        return res.json({ clientSecret: 'demo_secret_key', paymentIntentId: 'pi_demo_001' });
    }
    if (path === '/api/payments/history' && method === 'GET') {
        return res.json({ payments: [{ id: 'pay-001', amount: 13750, currency: 'chf', status: 'succeeded', booking_id: 'booking-002', created_at: new Date().toISOString() }] });
    }

    // REVIEWS
    if (path.match(/^\/api\/reviews\/station\//) && method === 'GET') {
        const stationId = path.split('/').pop();
        const reviews = DEMO_REVIEWS.filter(r => r.station_id === stationId);
        return res.json({ reviews });
    }
    if (path === '/api/reviews/user' && method === 'GET') {
        return res.json({ reviews: DEMO_REVIEWS.filter(r => r.user_id === 'demo-user-001') });
    }
    if (path === '/api/reviews' && method === 'POST') {
        return res.status(201).json({ review: { id: `review-new`, ...req.body, user_name: 'Alex Demo', created_at: new Date().toISOString() } });
    }

    // FAVORITES
    if (path === '/api/favorites' && method === 'GET') {
        return res.json({ favorites: [DEMO_STATIONS[0], DEMO_STATIONS[1]] });
    }
    if (path === '/api/favorites' && method === 'POST') {
        return res.status(201).json({ message: 'Added to favorites' });
    }
    if (path.match(/^\/api\/favorites\//) && method === 'DELETE') {
        return res.json({ message: 'Removed from favorites' });
    }

    // ADMIN
    if (path === '/api/admin/dashboard' && method === 'GET') {
        return res.json({ dashboard: { total_users: 156, total_stations: 42, pending_stations: 3, total_bookings: 1247, total_revenue: '45230.00' } });
    }
    if (path === '/api/admin/stations' && method === 'GET') {
        return res.json({ stations: DEMO_STATIONS.slice(0, 2).map(s => ({ ...s, status: 'pending', owner_name: 'Station Owner' })) });
    }
    if (path === '/api/admin/users' && method === 'GET') {
        return res.json({ users: [DEMO_USER, DEMO_OWNER, { id: 'admin-001', name: 'Admin', email: 'admin@spark.ch', role: 'admin' }] });
    }

    // Fallback
    return res.json({ message: 'Demo mode active', path, method });
}

module.exports = demoMode;
