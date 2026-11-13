import { Router } from 'express';
import { HttpError, id, ids, ipv4, notFound, text } from '../http.ts';
import type { Deps } from '../app.ts';

export function instanceRoutes({ store, wled, discover }: Deps): Router {
  const router = Router();

  const findInstance = (value: unknown) => store.instance(id(value)) ?? notFound('Device');

  const assertFreeIp = (ip: string, exceptId?: number) => {
    if (store.instances().some((instance) => instance.ip === ip && instance.id !== exceptId)) {
      throw new HttpError(409, 'A device with this IP address already exists');
    }
  };

  router.get('/instances', (_req, res) => {
    res.json(store.instances());
  });

  router.post('/instances', async (req, res) => {
    const ip = ipv4(req.body?.ip);
    const name = text(req.body?.name, 'name', { required: false });
    assertFreeIp(ip);
    const info = await wled.info(ip);
    res.status(201).json(store.instance(store.createInstance(ip, name || info.name)));
  });

  router.put('/instances/:id', async (req, res) => {
    const instance = findInstance(req.params.id);
    const ip = ipv4(req.body?.ip);
    const name = text(req.body?.name, 'name', { required: false });
    if (ip !== instance.ip) {
      assertFreeIp(ip, instance.id);
      await wled.info(ip);
    }
    store.updateInstance(instance.id, ip, name);
    res.json(store.instance(instance.id));
  });

  router.delete('/instances/:id', (req, res) => {
    if (!store.deleteInstance(id(req.params.id))) notFound('Device');
    res.status(204).end();
  });

  router.post('/instances/reorder', (req, res) => {
    store.reorderInstances(ids(req.body?.orderedIds));
    res.json(store.instances());
  });

  router.post('/instances/discover', async (_req, res) => {
    const known = new Set(store.instances().map((instance) => instance.ip));
    const candidates = (await discover()).filter((ip) => !known.has(ip));
    const found = await Promise.all(candidates.map((ip) => wled.info(ip).catch(() => null)));
    const added = candidates.flatMap((ip, index) => {
      const info = found[index];
      return info ? [store.instance(store.createInstance(ip, info.name))] : [];
    });
    res.json({ added });
  });

  router.get('/instances/:id/info', async (req, res) => {
    res.json(await wled.info(findInstance(req.params.id).ip));
  });

  router.get('/instances/:id/state', async (req, res) => {
    res.json(await wled.state(findInstance(req.params.id).ip));
  });

  router.post('/instances/:id/state', async (req, res) => {
    const { ip } = findInstance(req.params.id);
    if (typeof req.body !== 'object' || req.body === null || Array.isArray(req.body)) {
      throw new HttpError(400, 'The state must be a JSON object');
    }
    res.json(await wled.setState(ip, req.body));
  });

  router.get('/instances/:id/presets', async (req, res) => {
    res.json(await wled.presets(findInstance(req.params.id).ip));
  });

  return router;
}
