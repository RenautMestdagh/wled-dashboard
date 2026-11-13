import { HttpError } from './http.ts';

export type DeviceState = Record<string, unknown>;

export interface DeviceInfo {
  ver: string;
  name: string;
  leds: { lc: number };
}

export interface WledOptions {
  url?: (ip: string) => string;
  timeoutMs?: number;
}

export type Wled = ReturnType<typeof createWled>;

export function createWled({ url = (ip) => `http://${ip}`, timeoutMs = 3000 }: WledOptions = {}) {
  async function request(ip: string, path: string, body?: DeviceState): Promise<unknown> {
    let response: Response;
    try {
      response = await fetch(url(ip) + path, {
        method: body ? 'POST' : 'GET',
        headers: body ? { 'content-type': 'application/json' } : undefined,
        body: body && JSON.stringify(body),
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch (error) {
      const timedOut = error instanceof DOMException && error.name === 'TimeoutError';
      throw new HttpError(502, timedOut ? `${ip} did not answer in time` : `${ip} is unreachable`);
    }

    if (!response.ok) throw new HttpError(502, `${ip} answered with HTTP ${response.status}`);
    try {
      return await response.json();
    } catch {
      throw new HttpError(502, `${ip} did not answer with JSON`);
    }
  }

  return {
    async info(ip: string): Promise<DeviceInfo> {
      const info = (await request(ip, '/json/info')) as Partial<DeviceInfo> | null;
      if (typeof info?.ver !== 'string') throw new HttpError(502, `${ip} is not a WLED device`);
      return info as DeviceInfo;
    },
    state: (ip: string) => request(ip, '/json/state'),
    setState: (ip: string, state: DeviceState) => request(ip, '/json/state', state),
    presets: (ip: string) => request(ip, '/presets.json'),
  };
}
