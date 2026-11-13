import assert from 'node:assert/strict';
import { test } from 'node:test';
import cron from 'node-cron';
import { isActiveOn } from '../src/scheduler.ts';
import { startApp } from './support.ts';

const scheduleJobs = () => [...cron.getTasks().values()].filter((task) => task.name?.startsWith('schedule-'));

async function startWithPreset(t: Parameters<typeof startApp>[0]) {
  const app = await startApp(t);
  const preset = await app.api('POST', '/api/presets', { name: 'Evening', instances: [] });
  return { ...app, presetId: preset.body.id as number };
}

test('it creates a schedule and starts its job', async (t) => {
  // Arrange
  const { api, presetId } = await startWithPreset(t);

  // Act
  const response = await api('POST', '/api/schedules', {
    name: 'Daily',
    cron_expression: '0 20 * * 1-5',
    preset_id: presetId,
    start_date: '2026-12-01',
    stop_date: '2026-12-31',
  });

  // Assert
  assert.equal(response.status, 201);
  assert.equal(response.body.preset_name, 'Evening');
  assert.equal(response.body.enabled, true);
  assert.equal(scheduleJobs().length, 1);
});

test('it refuses an invalid cron expression', async (t) => {
  // Arrange
  const { api, presetId } = await startWithPreset(t);

  // Act
  const response = await api('POST', '/api/schedules', {
    name: 'Daily',
    cron_expression: '99 * * *',
    preset_id: presetId,
  });

  // Assert
  assert.equal(response.status, 400);
  assert.equal((await api('GET', '/api/schedules')).body.length, 0);
});

test('it refuses a stop date before the start date', async (t) => {
  // Arrange
  const { api, presetId } = await startWithPreset(t);

  // Act
  const response = await api('POST', '/api/schedules', {
    name: 'Daily',
    cron_expression: '0 20 * * *',
    preset_id: presetId,
    start_date: '2026-12-31',
    stop_date: '2026-12-01',
  });

  // Assert
  assert.equal(response.status, 400);
});

test('editing a schedule replaces its job instead of adding a second one', async (t) => {
  // Arrange
  const { api, presetId } = await startWithPreset(t);
  const schedule = await api('POST', '/api/schedules', {
    name: 'Daily',
    cron_expression: '0 20 * * *',
    preset_id: presetId,
  });

  // Act
  await api('PUT', `/api/schedules/${schedule.body.id}`, {
    name: 'Daily',
    cron_expression: '0 21 * * *',
    preset_id: presetId,
  });
  await api('PUT', `/api/schedules/${schedule.body.id}`, {
    name: 'Daily',
    cron_expression: '0 22 * * *',
    preset_id: presetId,
  });

  // Assert
  const jobs = scheduleJobs();
  assert.equal(jobs.length, 1);
  assert.equal(jobs[0]?.getPattern(), '0 22 * * *');
});

test('disabling a schedule stops its job', async (t) => {
  // Arrange
  const { api, presetId } = await startWithPreset(t);
  const schedule = await api('POST', '/api/schedules', {
    name: 'Daily',
    cron_expression: '0 20 * * *',
    preset_id: presetId,
  });

  // Act
  const response = await api('PUT', `/api/schedules/${schedule.body.id}`, {
    name: 'Daily',
    cron_expression: '0 20 * * *',
    preset_id: presetId,
    enabled: false,
  });

  // Assert
  assert.equal(response.body.enabled, false);
  assert.equal(scheduleJobs().length, 0);
});

test('deleting a schedule stops its job', async (t) => {
  // Arrange
  const { api, presetId } = await startWithPreset(t);
  const schedule = await api('POST', '/api/schedules', {
    name: 'Daily',
    cron_expression: '0 20 * * *',
    preset_id: presetId,
  });

  // Act
  const response = await api('DELETE', `/api/schedules/${schedule.body.id}`);

  // Assert
  assert.equal(response.status, 204);
  assert.equal(scheduleJobs().length, 0);
});

test('a running job applies the preset of its schedule', async (t) => {
  // Arrange
  const { api, addDevice } = await startApp(t);
  const device = await addDevice('192.168.1.20');
  const preset = await api('POST', '/api/presets', {
    name: 'Evening',
    instances: [{ instance_id: device.id, instance_preset: 5 }],
  });
  await api('POST', '/api/schedules', { name: 'Daily', cron_expression: '0 20 * * *', preset_id: preset.body.id });

  // Act
  await scheduleJobs()[0]?.execute();

  // Assert
  assert.deepEqual(device.received, [{ ps: 5 }]);
});

test('the start and stop dates are local days that are both included', () => {
  // Arrange
  const schedule = { start_date: '2026-12-01', stop_date: '2026-12-31' };

  // Act
  const active = [
    new Date(2026, 10, 30, 23, 59),
    new Date(2026, 11, 1, 0, 0),
    new Date(2026, 11, 31, 23, 59),
    new Date(2027, 0, 1, 0, 0),
  ].map((now) => isActiveOn(schedule, now));

  // Assert
  assert.deepEqual(active, [false, true, true, false]);
});

test('a stored invalid cron expression is skipped instead of stopping the other schedules', async (t) => {
  // Arrange
  const { api, db, scheduler, presetId } = await startWithPreset(t);
  await api('POST', '/api/schedules', { name: 'Valid', cron_expression: '0 20 * * *', preset_id: presetId });
  db.prepare("INSERT INTO schedules (name, cron_expression, preset_id) VALUES ('Broken', 'not cron', ?)").run(presetId);
  scheduler.stop();

  // Act
  scheduler.start();

  // Assert
  assert.equal(scheduleJobs().length, 1);
});
