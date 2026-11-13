import Database from 'better-sqlite3';

export type Db = Database.Database;

// Append only: the index + 1 of a migration is the user_version it brings the database to.
const migrations = [
  // The schema 1.2.0 and earlier created at every start, so on their databases this changes nothing
  `
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
  `,
  `
    ALTER TABLE instances DROP COLUMN last_seen;
    UPDATE instances SET name = '' WHERE name IS NULL;
  `,
];

export function openDatabase(path: string): Db {
  const db = new Database(path);
  db.pragma('foreign_keys = ON');
  migrate(db);
  return db;
}

function migrate(db: Db): void {
  const version = db.pragma('user_version', { simple: true }) as number;

  db.transaction(() => {
    for (const [index, sql] of migrations.entries()) {
      if (index < version) continue;
      db.exec(sql);
      db.pragma(`user_version = ${index + 1}`);
    }
  })();
}
