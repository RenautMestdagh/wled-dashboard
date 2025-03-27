// Install dependencies: npm install express sqlite3 cors dotenv

const express = require("express");
const cors = require("cors");
const path = require("path");
const db = require("./db");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Serve frontend from ../frontend/dist
app.use(express.static(path.join(__dirname, "../frontend/dist")));

// API Routes
const routes = require("./routes");
app.use("/api", routes);

// Catch-all route to serve frontend
app.get("*", (req, res) => {
    res.sendFile(path.join(__dirname, "../frontend/dist", "index.html"));
});

app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});
