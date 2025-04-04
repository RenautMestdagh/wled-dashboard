const rateLimit = require("express-rate-limit");
const API_KEYS = new Set(process.env.API_KEYS?.split(',') || []);

// Initialize rate limiter once
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per window
});

module.exports = {
    // Custom rate limiting middleware that skips if API key is valid
    rateLimitUnlessAuthenticated: (req, res, next) => {
        const apiKey = req.headers['x-api-key'] || req.query.apiKey;

        if (apiKey && API_KEYS.has(apiKey)) {
            return next(); // Skip rate limiting if authenticated
        }

        // Apply pre-initialized rate limiter
        return limiter(req, res, next);
    },

    authenticate: (req, res, next) => {
        const apiKey = req.headers['x-api-key'] || req.query.apiKey;

        if (!apiKey || !API_KEYS.has(apiKey)) {
            return res.status(401).json({ error: 'Unauthorized' });
        }

        next();
    }
};
