const API_KEYS = new Set(process.env.API_KEYS?.split(',') || []);

module.exports = {
    authenticate: (req, res, next) => {
        const apiKey = req.headers['x-api-key'] || req.query.apiKey;

        if (!apiKey || !API_KEYS.has(apiKey)) {
            return res.status(401).json({ error: 'Unauthorized' });
        }

        next();
    }
};