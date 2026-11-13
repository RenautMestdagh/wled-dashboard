import assert from 'node:assert/strict';
import { test } from 'node:test';
import { fakeDevice, startApp } from './support.ts';

test('it adds a device that answers as WLED', async (t) => {
  // Arrange
  const { api, devices } = await startApp(t);
  devices.set('192.168.1.20', fakeDevice('Desk'));

  // Act
  const response = await api('POST', '/api/instances', { ip: '192.168.1.20', name: 'Desk' });

  // Assert
  assert.equal(response.status, 201);
  assert.equal(response.body.ip, '192.168.1.20');
  assert.equal(response.body.name, 'Desk');
  assert.equal((await api('GET', '/api/instances')).body.length, 1);
});

test('a device added without a name gets the name it has in WLED', async (t) => {
  // Arrange
  const { api, devices } = await startApp(t);
  devices.set('192.168.1.20', fakeDevice('Desk'));

  // Act
  const response = await api('POST', '/api/instances', { ip: '192.168.1.20', name: '' });

  // Assert
  assert.equal(response.status, 201);
  assert.equal(response.body.name, 'Desk');
});

test('it refuses an address that is not a valid IPv4 address', async (t) => {
  // Arrange
  const { api } = await startApp(t);

  // Act
  const response = await api('POST', '/api/instances', { ip: '999.1.1.1', name: '' });

  // Assert
  assert.equal(response.status, 400);
});

test('it refuses a device that does not answer', async (t) => {
  // Arrange
  const { api } = await startApp(t);

  // Act
  const response = await api('POST', '/api/instances', { ip: '192.168.1.21', name: '' });

  // Assert
  assert.equal(response.status, 502);
  assert.equal((await api('GET', '/api/instances')).body.length, 0);
});

test('it refuses a second device with the same address', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  await addDevice('192.168.1.20');

  // Act
  const response = await api('POST', '/api/instances', { ip: '192.168.1.20', name: 'Again' });

  // Assert
  assert.equal(response.status, 409);
});

test('it renames a device', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  const device = await addDevice('192.168.1.20', 'Desk');

  // Act
  const response = await api('PUT', `/api/instances/${device.id}`, { ip: '192.168.1.20', name: 'Office' });

  // Assert
  assert.equal(response.status, 200);
  assert.equal(response.body.name, 'Office');
});

test('it reorders devices', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  const deviceA = await addDevice('192.168.1.20');
  const deviceB = await addDevice('192.168.1.21');

  // Act
  const response = await api('POST', '/api/instances/reorder', { orderedIds: [deviceB.id, deviceA.id] });

  // Assert
  assert.equal(response.status, 200);
  assert.deepEqual(
    response.body.map((instance: { id: number }) => instance.id),
    [deviceB.id, deviceA.id],
  );
});

test('deleting a device keeps its presets and schedules and only removes the device from them', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  const deviceA = await addDevice('192.168.1.20');
  const deviceB = await addDevice('192.168.1.21');
  const onlyA = await api('POST', '/api/presets', {
    name: 'Only A',
    instances: [{ instance_id: deviceA.id, instance_preset: 1 }],
  });
  const both = await api('POST', '/api/presets', {
    name: 'Both',
    instances: [
      { instance_id: deviceA.id, instance_preset: 1 },
      { instance_id: deviceB.id, instance_preset: 2 },
    ],
  });
  await api('POST', '/api/schedules', { name: 'Evening', cron_expression: '0 20 * * *', preset_id: onlyA.body.id });

  // Act
  const response = await api('DELETE', `/api/instances/${deviceA.id}`);

  // Assert
  assert.equal(response.status, 204);
  assert.equal((await api('GET', `/api/presets/${onlyA.body.id}`)).body.instances.length, 0);
  assert.deepEqual(
    (await api('GET', `/api/presets/${both.body.id}`)).body.instances.map(
      (i: { instance_id: number }) => i.instance_id,
    ),
    [deviceB.id],
  );
  assert.equal((await api('GET', '/api/schedules')).body.length, 1);
});

test('it passes a state change on to the device', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  const device = await addDevice('192.168.1.20');

  // Act
  const response = await api('POST', `/api/instances/${device.id}/state`, { on: true, bri: 40 });

  // Assert
  assert.equal(response.status, 200);
  assert.deepEqual(device.received, [{ on: true, bri: 40 }]);
});

test('it reports a device that does not answer as a bad gateway', async (t) => {
  // Arrange
  const { api, addDevice, devices } = await startApp(t);
  const device = await addDevice('192.168.1.20');
  devices.delete('192.168.1.20');

  // Act
  const response = await api('GET', `/api/instances/${device.id}/state`);

  // Assert
  assert.equal(response.status, 502);
  assert.match(response.body.error, /192\.168\.1\.20/);
});

test('discovery adds the WLED devices that are not added yet', async (t) => {
  // Arrange
  const { api, addDevice, devices } = await startApp(t, {
    discovered: ['192.168.1.20', '192.168.1.21', '192.168.1.99'],
  });
  await addDevice('192.168.1.20');
  devices.set('192.168.1.21', fakeDevice('Window'));

  // Act
  const response = await api('POST', '/api/instances/discover');

  // Assert
  assert.equal(response.status, 200);
  assert.deepEqual(
    response.body.added.map((instance: { ip: string; name: string }) => [instance.ip, instance.name]),
    [['192.168.1.21', 'Window']],
  );
  assert.equal((await api('GET', '/api/instances')).body.length, 2);
});
