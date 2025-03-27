const sqlite3 = require("sqlite3").verbose();

const db = new sqlite3.Database("./database.db", (err) => {
    if (err) {
        console.error("Database connection failed:", err.message);
    } else {
        console.log("Connected to SQLite database.");
    }
});

db.serialize(() => {
    db.run(`
        CREATE TABLE IF NOT EXISTS instances (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ip TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL
        )
    `);
});

module.exports = db;
