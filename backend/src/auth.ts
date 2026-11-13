import type { Request, RequestHandler } from 'express';
import { rateLimit } from 'express-rate-limit';

export function auth(apiKeys: Set<string>) {
  const isAuthenticated = (req: Request) => apiKeys.has(req.get('x-api-key') ?? '');

  return {
    // Guessing keys (or anything else without one) is slowed down; the app itself is never limited
    rateLimit: rateLimit({ windowMs: 15 * 60 * 1000, limit: 500, skip: isAuthenticated }),

    requireKey: ((req, res, next) => {
      if (isAuthenticated(req)) next();
      else res.status(401).json({ error: 'Unauthorized' });
    }) satisfies RequestHandler,
  };
}
