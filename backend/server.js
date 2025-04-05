require('dotenv').config();
const morgan = require('morgan');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const {authenticate, rateLimitUnlessAuthenticated} = require("./middlewares/auth");
const path = require('path');

const app = express();

app.use(morgan('dev'));

const corsOptions = {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*', // Allow only this origin
    methods: 'GET,POST,PUT,DELETE', // Allow specific methods if needed
    allowedHeaders: 'Content-Type,X-API-Key,Authorization',  // Allow necessary headers
    credentials: true, // If you want to allow cookies and authentication headers
};
const corsOptionsDev = {
    origin: '*', // Allow all origins
    methods: 'GET,POST,PUT,DELETE',
    allowedHeaders: 'Content-Type,X-API-Key,Authorization',  // Allow necessary headers
    credentials: true,
};

if (process.env.NODE_ENV === 'production')
    app.use(cors(corsOptions));
else
    app.use(cors(corsOptionsDev));


// Security Middlewares
app.use(
    helmet({
        contentSecurityPolicy: {
            directives: {
                defaultSrc: ["'self'"],
                scriptSrc: ["'self'", "'unsafe-inline'", "https://www.gstatic.com", "'unsafe-eval'"],
                styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
                fontSrc: ["'self'", "https://fonts.gstatic.com"],
                connectSrc: ["'self'", "https://www.gstatic.com", "https://fonts.gstatic.com"],
                imgSrc: ["'self'", "data:"],
                objectSrc: ["'none'"],
                baseUri: ["'self'"],
                frameAncestors: ["'self'"],
            },
        },
    })
);

app.use(express.json());

// Apply conditional rate limiting
app.use(rateLimitUnlessAuthenticated);

// Serve Flutter web app before authentication
app.use(express.static(path.join(__dirname, 'public')));

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
