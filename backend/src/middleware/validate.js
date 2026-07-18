const Joi = require('joi');

const validate = (schema, property = 'body') => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req[property], {
            abortEarly: false,
            stripUnknown: true
        });

        if (error) {
            const errors = error.details.map(detail => ({
                field: detail.path.join('.'),
                message: detail.message
            }));
            return res.status(400).json({ error: 'Validation failed', details: errors });
        }

        req[property] = value;
        next();
    };
};

// Validation schemas
const schemas = {
    register: Joi.object({
        name: Joi.string().min(2).max(100).required(),
        email: Joi.string().email().required(),
        password: Joi.string().min(8).max(128).required(),
        role: Joi.string().valid('driver', 'owner').default('driver')
    }),

    login: Joi.object({
        email: Joi.string().email().required(),
        password: Joi.string().required()
    }),

    updateProfile: Joi.object({
        name: Joi.string().min(2).max(100),
        avatar_url: Joi.string().uri().allow(''),
        fcm_token: Joi.string()
    }),

    createStation: Joi.object({
        name: Joi.string().min(2).max(255).required(),
        address: Joi.string().required(),
        latitude: Joi.number().min(-90).max(90).required(),
        longitude: Joi.number().min(-180).max(180).required(),
        charger_type: Joi.string().valid('CCS', 'Type2', 'Tesla', 'CHAdeMO').required(),
        power_kw: Joi.number().positive().max(1000).required(),
        price_per_kwh: Joi.number().positive().max(10).required(),
        ports: Joi.number().integer().min(1).max(50).required(),
        photos: Joi.array().items(Joi.string().uri()).max(10)
    }),

    updateStation: Joi.object({
        name: Joi.string().min(2).max(255),
        address: Joi.string(),
        latitude: Joi.number().min(-90).max(90),
        longitude: Joi.number().min(-180).max(180),
        charger_type: Joi.string().valid('CCS', 'Type2', 'Tesla', 'CHAdeMO'),
        power_kw: Joi.number().positive().max(1000),
        price_per_kwh: Joi.number().positive().max(10),
        ports: Joi.number().integer().min(1).max(50),
        photos: Joi.array().items(Joi.string().uri()).max(10),
        is_active: Joi.boolean()
    }),

    updateAvailability: Joi.object({
        port: Joi.number().integer().min(1).required(),
        date: Joi.date().iso().required(),
        start_time: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required(),
        end_time: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required(),
        status: Joi.string().valid('available', 'occupied', 'maintenance').required()
    }),

    createBooking: Joi.object({
        station_id: Joi.string().uuid().required(),
        port: Joi.number().integer().min(1).required(),
        start_time: Joi.date().iso().required(),
        end_time: Joi.date().iso().required()
    }),

    createReview: Joi.object({
        station_id: Joi.string().uuid().required(),
        rating: Joi.number().integer().min(1).max(5).required(),
        comment: Joi.string().max(1000).allow('')
    }),

    createPaymentIntent: Joi.object({
        booking_id: Joi.string().uuid().required()
    }),

    stationQuery: Joi.object({
        latitude: Joi.number().min(-90).max(90),
        longitude: Joi.number().min(-180).max(180),
        radius: Joi.number().positive().max(100).default(10),
        charger_type: Joi.string().valid('CCS', 'Type2', 'Tesla', 'CHAdeMO'),
        min_power: Joi.number().positive(),
        max_price: Joi.number().positive(),
        page: Joi.number().integer().min(1).default(1),
        limit: Joi.number().integer().min(1).max(100).default(20)
    })
};

module.exports = { validate, schemas };
