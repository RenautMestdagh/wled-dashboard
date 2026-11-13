import { Router } from 'express';
import { applyPreset } from '../apply-preset.ts';
import type { Deps } from '../app.ts';
import { HttpError, id, ids, notFound, text } from '../http.ts';
import type { PresetInstance, Store } from '../store.ts';

export function presetRoutes({ store, wled }: Deps): Router {
  const router = Router();

  const findPreset = (value: unknown) => store.preset(id(value)) ?? notFound('Preset');

  router.get('/presets', (_req, res) => {
    res.json(store.presets());
  });

  router.get('/presets/:id', (req, res) => {
    res.json(findPreset(req.params.id));
  });

  router.post('/presets', (req, res) => {
    const name = text(req.body?.name, 'name');
    const instances = presetInstances(store, req.body?.instances);
    res.status(201).json(store.preset(store.createPreset(name, instances)));
  });

  router.put('/presets/:id', (req, res) => {
    const presetId = id(req.params.id);
    const name = text(req.body?.name, 'name');
    const instances = presetInstances(store, req.body?.instances);
    if (!store.updatePreset(presetId, name, instances)) notFound('Preset');
    res.json(store.preset(presetId));
  });

  router.delete('/presets/:id', (req, res) => {
    if (!store.deletePreset(id(req.params.id))) notFound('Preset');
    res.status(204).end();
  });

  router.post('/presets/reorder', (req, res) => {
    store.reorderPresets(ids(req.body?.orderedIds));
    res.json(store.presets());
  });

  router.post('/presets/:id/apply', async (req, res) => {
    res.json({ results: await applyPreset(wled, findPreset(req.params.id)) });
  });

  return router;
}

function presetInstances(store: Store, value: unknown): PresetInstance[] {
  if (!Array.isArray(value)) throw new HttpError(400, 'instances must be an array');

  const known = new Set(store.instances().map((instance) => instance.id));
  const seen = new Set<number>();
  return value.map((item) => {
    const instanceId = id(item?.instance_id);
    const target: unknown = item?.instance_preset;
    if (!known.has(instanceId) || seen.has(instanceId))
      throw new HttpError(400, `Unknown or repeated device ${instanceId}`);
    const isPresetNumber = Number.isInteger(target) && (target as number) >= 0;
    const isState = typeof target === 'object' && target !== null && !Array.isArray(target);
    if (!isPresetNumber && !isState)
      throw new HttpError(400, 'instance_preset must be a preset number or a state object');
    seen.add(instanceId);
    return { instance_id: instanceId, instance_preset: target as PresetInstance['instance_preset'] };
  });
}
