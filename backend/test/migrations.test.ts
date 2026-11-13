import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import Database from 'better-sqlite3';
import { openDatabase } from '../src/database.ts';
import { createStore } from '../src/store.ts';

// The schema and kind of rows of a production database made by 1.2.0, which created its tables at every start
function createVersion120Database(path: string): void {
  const db = new Database(path);
  db.pragma('foreign_keys = ON');
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

    INSERT INTO instances (id, ip, name, display_order, last_seen) VALUES
      (1, '192.168.0.10', 'Bureau', 1, '2026-11-01T20:00:00.000Z'),
      (2, '192.168.0.11', NULL, 0, '2026-11-01T20:00:00.000Z');
    INSERT INTO presets (id, name, display_order) VALUES (1, 'Avond', 0), (2, 'Film', 1);
    INSERT INTO preset_instances (preset_id, instance_id, instance_preset) VALUES
      (1, 1, '3'),
      (1, 2, '{"on":true,"bri":80,"seg":[{"col":[[255,160,0]]}]}'),
      (2, 2, '7');
    INSERT INTO schedules (id, name, cron_expression, start_date, stop_date, enabled, preset_id) VALUES
      (1, 'Weekdagen', '30 19 * * 1-5', '2026-11-01', NULL, 1, 1),
      (2, 'Zomer', '0 22 * * *', NULL, '2026-08-31', 0, 2);
  `);
  db.close();
}

function tempDatabasePath(t: { after: (fn: () => void) => void }): string {
  const dir = mkdtempSync(join(tmpdir(), 'wled-migration-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  return join(dir, 'database.db');
}

test('it upgrades a 1.2.0 database in place and keeps every row', (t) => {
  // Arrange
  const path = tempDatabasePath(t);
  createVersion120Database(path);

  // Act
  const db = openDatabase(path);
  t.after(() => db.close());
  const store = createStore(db);

  // Assert
  assert.deepEqual(store.instances(), [
    { id: 2, ip: '192.168.0.11', name: '', display_order: 0 },
    { id: 1, ip: '192.168.0.10', name: 'Bureau', display_order: 1 },
  ]);
  assert.deepEqual(
    store.preset(1)?.instances.map((instance) => instance.instance_preset),
    [{ on: true, bri: 80, seg: [{ col: [[255, 160, 0]] }] }, 3],
  );
  assert.equal(store.preset(2)?.instance_count, 1);
  assert.deepEqual(store.schedules(), [
    {
      id: 1,
      name: 'Weekdagen',
      cron_expression: '30 19 * * 1-5',
      start_date: '2026-11-01',
      stop_date: null,
      enabled: true,
      preset_id: 1,
      preset_name: 'Avond',
    },
    {
      id: 2,
      name: 'Zomer',
      cron_expression: '0 22 * * *',
      start_date: null,
      stop_date: '2026-08-31',
      enabled: false,
      preset_id: 2,
      preset_name: 'Film',
    },
  ]);
  assert.deepEqual(db.pragma('foreign_key_check'), []);
});

test('opening a migrated database again changes nothing', (t) => {
  // Arrange
  const path = tempDatabasePath(t);
  createVersion120Database(path);
  openDatabase(path).close();

  // Act
  const db = openDatabase(path);
  t.after(() => db.close());

  // Assert
  assert.equal(db.pragma('user_version', { simple: true }), 2);
  assert.equal(createStore(db).instances().length, 2);
});

test('it creates the schema in a new database', (t) => {
  // Arrange
  const path = tempDatabasePath(t);

  // Act
  const db = openDatabase(path);
  t.after(() => db.close());

  // Assert
  assert.equal(db.pragma('user_version', { simple: true }), 2);
  assert.deepEqual(createStore(db).presets(), []);
});
