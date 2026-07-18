const { v4: uuidv4 } = require('uuid');

// Generate a unique booking reference
const generateBookingRef = () => {
    return `SPK-${Date.now().toString(36).toUpperCase()}-${uuidv4().substring(0, 4).toUpperCase()}`;
};

// Format currency
const formatCHF = (amount) => {
    return `CHF ${parseFloat(amount).toFixed(2)}`;
};

// Calculate distance between two coordinates (Haversine formula)
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Earth's radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
};

// Validate Swiss phone number format
const isValidSwissPhone = (phone) => {
    const swissPhoneRegex = /^(\+41|0041|0)[1-9]\d{8}$/;
    return swissPhoneRegex.test(phone.replace(/\s/g, ''));
};

module.exports = {
    generateBookingRef,
    formatCHF,
    calculateDistance,
    isValidSwissPhone
};
