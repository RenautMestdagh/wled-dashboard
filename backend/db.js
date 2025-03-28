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

    db.run(`
        CREATE TABLE IF NOT EXISTS presets (
                                               id INTEGER PRIMARY KEY AUTOINCREMENT,
                                               name TEXT NOT NULL
        )
    `);

    db.run(`
        CREATE TABLE IF NOT EXISTS preset_instances (
            preset_id INTEGER NOT NULL,
            instance_id INTEGER NOT NULL,
            preset_value INTEGER NOT NULL,
            PRIMARY KEY (preset_id, instance_id)
        )
    `);
});

module.exports = db;