import { once } from 'node:events';
import { createServer, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import type { TestContext } from 'node:test';
import { createApp } from '../src/app.ts';
import { openDatabase } from '../src/database.ts';
import { createWled } from '../src/wled.ts';

export const apiKey = 'test-key';

export interface FakeDevice {
  info: Record<string, unknown>;
  state: Record<string, unknown>;
  presets: Record<string, unknown>;
  received: Record<string, unknown>[];
}

export function fakeDevice(name: string): FakeDevice {
  return {
    info: { ver: '0.15.3', name, leds: { lc: 1 } },
    state: { on: false, bri: 128, ps: -1 },
    presets: { '0': {}, '1': { n: 'Warm' } },
    received: [],
  };
}

/** WLED devices behind one HTTP server: a request for `/<ip>/json/state` reaches the device with that IP. */
async function startFakeWled(devices: Map<string, FakeDevice>): Promise<Server> {
  const server = createServer(async (req, res) => {
    const [, ip, ...rest] = (req.url ?? '').split('/');
    const device = devices.get(ip ?? '');
    const path = `/${rest.join('/')}`;
    let body = '';
    for await (const chunk of req) body += chunk;

    if (!device) {
      res.writeHead(404).end();
    } else if (path === '/json/state' && req.method === 'POST') {
      device.received.push(JSON.parse(body));
      res.writeHead(200, { 'content-type': 'application/json' }).end('{"success":true}');
    } else {
      const routes: Record<string, unknown> = {
        '/json/info': device.info,
        '/json/state': device.state,
        '/presets.json': device.presets,
      };
      res.writeHead(200, { 'content-type': 'application/json' }).end(JSON.stringify(routes[path] ?? {}));
    }
  });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  return server;
}

export async function startApp(t: TestContext, { discovered = [] as string[] } = {}) {
  const devices = new Map<string, FakeDevice>();
  const fake = await startFakeWled(devices);
  const fakeUrl = `http://127.0.0.1:${(fake.address() as AddressInfo).port}`;

  const db = openDatabase(':memory:');
  const { app, scheduler } = createApp({
    db,
    apiKeys: new Set([apiKey]),
    wled: createWled({ url: (ip) => `${fakeUrl}/${ip}`, timeoutMs: 1000 }),
    discover: async () => discovered,
  });
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;

  t.after(() => {
    scheduler.stop();
    server.close();
    fake.close();
    db.close();
  });

  async function api(method: string, path: string, body?: unknown, key: string | null = apiKey) {
    const headers: Record<string, string> = { 'content-type': 'application/json' };
    if (key !== null) headers['x-api-key'] = key;
    const response = await fetch(url + path, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const json: any = response.status === 204 ? null : await response.json();
    return { status: response.status, body: json };
  }

  /** Adds a device to the fake network and to the dashboard. */
  async function addDevice(ip: string, name = '') {
    const device = fakeDevice(name || ip);
    devices.set(ip, device);
    const { body } = await api('POST', '/api/instances', { ip, name });
    return { ...device, id: body.id as number };
  }

  return { url, api, db, devices, scheduler, addDevice };
}
