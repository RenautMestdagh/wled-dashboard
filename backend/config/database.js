const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

// Resolve DB path based on environment
const resolveDBPath = () => {
    if (process.env.DB_PATH) {
        return process.env.DB_PATH;
    }
    return process.env.NODE_ENV === 'production'
        ? '/data/database.db'
        : path.join(__dirname, '../data/database.db');
};

const DB_PATH = resolveDBPath();
const DB_DIR = path.dirname(DB_PATH);

// Ensure directory exists
if (!fs.existsSync(DB_DIR)) {
    fs.mkdirSync(DB_DIR, {
        recursive: true,
        mode: process.env.NODE_ENV === 'production' ? 0o750 : 0o777
    });
}

const db = new Database(DB_PATH, {
    verbose: console.log
});

db.pragma('foreign_keys = ON');

// Initialize database schema
db.exec(`
    CREATE TABLE IF NOT EXISTS instances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ip TEXT UNIQUE NOT NULL,
        name TEXT,
        display_order INTEGER DEFAULT 0,
        last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        display_order INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS preset_instances (
        preset_id INTEGER NOT NULL,
        instance_id INTEGER NOT NULL,
        instance_preset TEXT NOT NULL,
        PRIMARY KEY (preset_id, instance_id),
        FOREIGN KEY (preset_id) REFERENCES presets(id) ON DELETE CASCADE,
        FOREIGN KEY (instance_id) REFERENCES instances(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        cron_expression TEXT NOT NULL,
        start_date TEXT,
        stop_date TEXT,
        enabled INTEGER NOT NULL DEFAULT 1,
        preset_id INTEGER NOT NULL,
        FOREIGN KEY (preset_id) REFERENCES presets(id) ON DELETE CASCADE
    );
`);

module.exports = db;