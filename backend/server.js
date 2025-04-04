require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const {authenticate, rateLimitUnlessAuthenticated} = require("./middlewares/auth");
const path = require('path');

const app = express();

// Security Middlewares
app.use(helmet());
app.use(cors({
    origin: /*process.env.ALLOWED_ORIGINS?.split(',') ||*/ '*'
}));
app.use(express.json());

// Apply conditional rate limiting
app.use(rateLimitUnlessAuthenticated);

// Serve Flutter web app before authentication
app.use(express.static(path.join(__dirname, 'build/web')));

// Health Check
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy' });
});

// All routes require authentication
app.use(authenticate);

// Routes
app.use('/api', require('./routes/api'));
app.use('/wled', require('./routes/wled'));

// Error Handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});