require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const {authenticate} = require("./middlewares/auth");

const app = express();

// Security Middlewares
app.use(helmet());
app.use(cors({
    origin: /*process.env.ALLOWED_ORIGINS?.split(',') ||*/ '*'
}));
app.use(express.json());

// Rate Limiting
app.use(rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per window
}));

// All routes require authentication
app.use(authenticate);

// Routes
app.use('/api', require('./routes/api'));
app.use('/wled', require('./routes/wled'));

// Health Check
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy' });
});

// Error Handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});