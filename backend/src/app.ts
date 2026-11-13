import { fileURLToPath } from 'node:url';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import { auth } from './auth.ts';
import type { Db } from './database.ts';
import { discoverAddresses } from './discovery.ts';
import { errorHandler } from './http.ts';
import { instanceRoutes } from './routes/instances.ts';
import { presetRoutes } from './routes/presets.ts';
import { scheduleRoutes } from './routes/schedules.ts';
import { Scheduler } from './scheduler.ts';
import { createStore, type Store } from './store.ts';
import { createWled, type Wled } from './wled.ts';

export interface AppOptions {
  db: Db;
  apiKeys: Set<string>;
  wled?: Wled;
  discover?: () => Promise<string[]>;
  trustProxy?: string;
  logRequests?: boolean;
}

export interface Deps {
  store: Store;
  wled: Wled;
  scheduler: Scheduler;
  discover: () => Promise<string[]>;
}

const publicDir = fileURLToPath(new URL('../public', import.meta.url));

export function createApp({
  db,
  apiKeys,
  wled = createWled(),
  discover = discoverAddresses,
  trustProxy = 'loopback, linklocal, uniquelocal',
  logRequests = false,
}: AppOptions) {
  const store = createStore(db);
  const scheduler = new Scheduler(store, wled);
  const deps: Deps = { store, wled, scheduler, discover };
  const { rateLimit, requireKey } = auth(apiKeys);

  const app = express();
  // Only the reverse proxy in front of the app may set the client IP, or anyone could dodge the rate limit
  app.set('trust proxy', trustProxy);
  if (logRequests) app.use(morgan('short', { skip: (req) => req.url === '/health' }));
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          // Flutter web loads CanvasKit (WebAssembly) and its fallback fonts from Google's CDN
          scriptSrc: ["'self'", "'wasm-unsafe-eval'", 'https://www.gstatic.com'],
          connectSrc: ["'self'", 'https://www.gstatic.com', 'https://fonts.gstatic.com'],
          fontSrc: ["'self'", 'https://fonts.gstatic.com'],
          // On the LAN the app is also served over plain HTTP
          upgradeInsecureRequests: null,
        },
      },
    }),
  );
  app.use(rateLimit);
  app.use(express.static(publicDir));
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });
  app.use('/api', requireKey, express.json(), instanceRoutes(deps), presetRoutes(deps), scheduleRoutes(deps));
  app.use(errorHandler);

  return { app, scheduler };
}
