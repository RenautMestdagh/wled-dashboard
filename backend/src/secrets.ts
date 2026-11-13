import { readFileSync } from 'node:fs';

/** The value of `${name}_FILE`'s file (Docker secrets), else of the `${name}` environment variable. */
export function readSecret(name: string): string | undefined {
  const path = process.env[`${name}_FILE`];
  return path ? readFileSync(path, 'utf8').trim() : process.env[name];
}
