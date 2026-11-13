import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { createApp } from './app.ts';
import { openDatabase } from './database.ts';
import { readSecret } from './secrets.ts';

const apiKeys = new Set(
  (readSecret('API_KEYS') ?? '')
    .split(',')
    .map((key) => key.trim())
    .filter(Boolean),
);
if (apiKeys.size === 0) throw new Error('Set API_KEYS (or API_KEYS_FILE) to at least one key');

const dbPath = process.env.DB_PATH ?? 'data/database.db';
mkdirSync(dirname(dbPath), { recursive: true });

const { app, scheduler } = createApp({
  db: openDatabase(dbPath),
  apiKeys,
  trustProxy: process.env.TRUST_PROXY,
  logRequests: true,
});

const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => {
  console.log(`Listening on port ${port}`);
  scheduler.start();
});
