import assert from 'node:assert/strict';
import { test } from 'node:test';
import { startApp } from './support.ts';

test('it creates a preset with a WLED preset for one device and a saved state for another', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  const deviceA = await addDevice('192.168.1.20');
  const deviceB = await addDevice('192.168.1.21');

  // Act
  const response = await api('POST', '/api/presets', {
    name: 'Movie night',
    instances: [
      { instance_id: deviceA.id, instance_preset: 3 },
      { instance_id: deviceB.id, instance_preset: { on: true, bri: 20 } },
    ],
  });

  // Assert
  assert.equal(response.status, 201);
  assert.equal(response.body.name, 'Movie night');
  assert.equal(response.body.instance_count, 2);
  assert.deepEqual(
    response.body.instances.map((i: { instance_preset: unknown }) => i.instance_preset),
    [3, { on: true, bri: 20 }],
  );
});

test('it refuses a preset with a device that does not exist', async (t) => {
  // Arrange
  const { api } = await startApp(t);

  // Act
  const response = await api('POST', '/api/presets', {
    name: 'Ghost',
    instances: [{ instance_id: 42, instance_preset: 1 }],
  });

  // Assert
  assert.equal(response.status, 400);
});

test('it refuses a second preset with the same name', async (t) => {
  // Arrange
  const { api } = await startApp(t);
  await api('POST', '/api/presets', { name: 'Evening', instances: [] });

  // Act
  const response = await api('POST', '/api/presets', { name: 'Evening', instances: [] });

  // Assert
  assert.equal(response.status, 409);
});

test('it updates the name and devices of a preset', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  const device = await addDevice('192.168.1.20');
  const preset = await api('POST', '/api/presets', { name: 'Evening', instances: [] });

  // Act
  const response = await api('PUT', `/api/presets/${preset.body.id}`, {
    name: 'Late evening',
    instances: [{ instance_id: device.id, instance_preset: 2 }],
  });

  // Assert
  assert.equal(response.status, 200);
  assert.equal(response.body.name, 'Late evening');
  assert.equal(response.body.instance_count, 1);
});

test('applying a preset sends each device its preset and reports success per device', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  const deviceA = await addDevice('192.168.1.20', 'Desk');
  const deviceB = await addDevice('192.168.1.21', 'Window');
  const preset = await api('POST', '/api/presets', {
    name: 'Movie night',
    instances: [
      { instance_id: deviceA.id, instance_preset: 3 },
      { instance_id: deviceB.id, instance_preset: { on: true, bri: 20 } },
    ],
  });

  // Act
  const response = await api('POST', `/api/presets/${preset.body.id}/apply`);

  // Assert
  assert.equal(response.status, 200);
  assert.deepEqual(
    response.body.results.map((result: { ok: boolean }) => result.ok),
    [true, true],
  );
  assert.deepEqual(deviceA.received, [{ ps: 3 }]);
  assert.deepEqual(deviceB.received, [{ on: true, bri: 20 }]);
});

test('applying a preset reports the device that failed', async (t) => {
  // Arrange
  const { api, addDevice, devices } = await startApp(t);
  const deviceA = await addDevice('192.168.1.20', 'Desk');
  const deviceB = await addDevice('192.168.1.21', 'Window');
  const preset = await api('POST', '/api/presets', {
    name: 'Movie night',
    instances: [
      { instance_id: deviceA.id, instance_preset: 3 },
      { instance_id: deviceB.id, instance_preset: 4 },
    ],
  });
  devices.delete('192.168.1.21');

  // Act
  const response = await api('POST', `/api/presets/${preset.body.id}/apply`);

  // Assert
  assert.equal(response.status, 200);
  const [resultA, resultB] = response.body.results;
  assert.equal(resultA.ok, true);
  assert.equal(resultB.ok, false);
  assert.equal(resultB.instance_name, 'Window');
  assert.match(resultB.error, /192\.168\.1\.21/);
});

test('deleting a preset also deletes its schedules', async (t) => {
  // Arrange
  const { api } = await startApp(t);
  const preset = await api('POST', '/api/presets', { name: 'Evening', instances: [] });
  await api('POST', '/api/schedules', { name: 'Daily', cron_expression: '0 20 * * *', preset_id: preset.body.id });

  // Act
  const response = await api('DELETE', `/api/presets/${preset.body.id}`);

  // Assert
  assert.equal(response.status, 204);
  assert.equal((await api('GET', '/api/schedules')).body.length, 0);
});

test('it reorders presets', async (t) => {
  // Arrange
  const { api } = await startApp(t);
  const presetA = await api('POST', '/api/presets', { name: 'A', instances: [] });
  const presetB = await api('POST', '/api/presets', { name: 'B', instances: [] });

  // Act
  const response = await api('POST', '/api/presets/reorder', { orderedIds: [presetB.body.id, presetA.body.id] });

  // Assert
  assert.deepEqual(
    response.body.map((preset: { name: string }) => preset.name),
    ['B', 'A'],
  );
});
