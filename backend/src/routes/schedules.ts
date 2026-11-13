import cron from 'node-cron';
import { Router } from 'express';
import type { Deps } from '../app.ts';
import { HttpError, date, id, notFound, text } from '../http.ts';
import type { ScheduleInput, Store } from '../store.ts';

export function scheduleRoutes({ store, scheduler }: Deps): Router {
  const router = Router();

  router.get('/schedules', (_req, res) => {
    res.json(store.schedules());
  });

  router.get('/schedules/:id', (req, res) => {
    res.json(store.schedule(id(req.params.id)) ?? notFound('Schedule'));
  });

  router.post('/schedules', (req, res) => {
    const scheduleId = store.createSchedule(scheduleInput(store, req.body));
    scheduler.sync(scheduleId);
    res.status(201).json(store.schedule(scheduleId));
  });

  router.put('/schedules/:id', (req, res) => {
    const scheduleId = id(req.params.id);
    if (!store.updateSchedule(scheduleId, scheduleInput(store, req.body))) notFound('Schedule');
    scheduler.sync(scheduleId);
    res.json(store.schedule(scheduleId));
  });

  router.delete('/schedules/:id', (req, res) => {
    const scheduleId = id(req.params.id);
    if (!store.deleteSchedule(scheduleId)) notFound('Schedule');
    scheduler.sync(scheduleId);
    res.status(204).end();
  });

  return router;
}

function scheduleInput(store: Store, body: Record<string, unknown> | undefined): ScheduleInput {
  const cronExpression = text(body?.cron_expression, 'cron_expression');
  if (!cron.validate(cronExpression)) throw new HttpError(400, 'cron_expression is not a valid cron expression');

  const presetId = id(body?.preset_id);
  if (!store.preset(presetId)) throw new HttpError(400, `Unknown preset ${presetId}`);

  const startDate = date(body?.start_date, 'start_date');
  const stopDate = date(body?.stop_date, 'stop_date');
  if (startDate && stopDate && stopDate < startDate) throw new HttpError(400, 'stop_date is before start_date');

  if (body?.enabled !== undefined && typeof body.enabled !== 'boolean')
    throw new HttpError(400, 'enabled must be a boolean');

  return {
    name: text(body?.name, 'name'),
    cron_expression: cronExpression,
    start_date: startDate,
    stop_date: stopDate,
    enabled: body?.enabled ?? true,
    preset_id: presetId,
  };
}
