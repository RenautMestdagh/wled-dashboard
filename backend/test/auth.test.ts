import assert from 'node:assert/strict';
import { test } from 'node:test';
import { startApp } from './support.ts';

test('it rejects api requests without a key', async (t) => {
  // Arrange
  const { api } = await startApp(t);

  // Act
  const response = await api('GET', '/api/instances', undefined, null);

  // Assert
  assert.equal(response.status, 401);
});

test('it rejects api requests with a wrong key', async (t) => {
  // Arrange
  const { api } = await startApp(t);

  // Act
  const response = await api('GET', '/api/instances', undefined, 'wrong-key');

  // Assert
  assert.equal(response.status, 401);
});

test('it accepts api requests with the right key', async (t) => {
  // Arrange
  const { api } = await startApp(t);

  // Act
  const response = await api('GET', '/api/instances');

  // Assert
  assert.equal(response.status, 200);
  assert.deepEqual(response.body, []);
});

test('it ignores a key passed in the query string', async (t) => {
  // Arrange
  const { api } = await startApp(t);

  // Act
  const response = await api('GET', '/api/instances?apiKey=test-key', undefined, null);

  // Assert
  assert.equal(response.status, 401);
});

test('it reports health without saying whether a key is valid', async (t) => {
  // Arrange
  const { api } = await startApp(t);

  // Act
  const response = await api('GET', '/health', undefined, 'wrong-key');

  // Assert
  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { status: 'ok' });
});

test('it hides internal errors from clients', async (t) => {
  // Arrange
  const { api, db } = await startApp(t);
  db.exec('DROP TABLE preset_instances');

  // Act
  const response = await api('GET', '/api/presets');

  // Assert
  assert.equal(response.status, 500);
  assert.deepEqual(response.body, { error: 'Internal server error' });
});
