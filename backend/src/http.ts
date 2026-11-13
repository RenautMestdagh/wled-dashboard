import { isIPv4 } from 'node:net';
import type { ErrorRequestHandler } from 'express';

export class HttpError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export function notFound(what: string): never {
  throw new HttpError(404, `${what} not found`);
}

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof HttpError) {
    res.status(error.status).json({ error: error.message });
  } else if (error?.type === 'entity.parse.failed') {
    res.status(400).json({ error: 'Invalid JSON' });
  } else if (error?.code === 'SQLITE_CONSTRAINT_UNIQUE') {
    const message = String(error.message).includes('instances.ip')
      ? 'A device with this IP address already exists'
      : 'This name is already in use';
    res.status(409).json({ error: message });
  } else {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export function id(value: unknown): number {
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number < 1) throw new HttpError(400, 'Invalid id');
  return number;
}

export function ids(value: unknown): number[] {
  if (!Array.isArray(value) || value.length === 0) throw new HttpError(400, 'orderedIds must be a non-empty array');
  return value.map(id);
}

export function text(value: unknown, field: string, { required = true } = {}): string {
  if (value === undefined && !required) return '';
  if (typeof value !== 'string' || (required && value.trim() === '')) throw new HttpError(400, `${field} is required`);
  return value.trim();
}

export function ipv4(value: unknown): string {
  if (typeof value !== 'string' || !isIPv4(value)) throw new HttpError(400, 'A valid IPv4 address is required');
  return value;
}

export function date(value: unknown, field: string): string | null {
  if (value === undefined || value === null || value === '') return null;
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value) || !isRealDate(value)) {
    throw new HttpError(400, `${field} must be a date as YYYY-MM-DD`);
  }
  return value;
}

function isRealDate(value: string): boolean {
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().startsWith(value);
}
