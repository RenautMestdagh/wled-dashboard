import type { Db } from './database.ts';
import type { DeviceState } from './wled.ts';

export interface Instance {
  id: number;
  ip: string;
  name: string;
  display_order: number;
}

/** A WLED preset number on the device, or a full state to send to it. */
export type DeviceTarget = number | DeviceState;

export interface PresetInstance {
  instance_id: number;
  instance_preset: DeviceTarget;
}

export interface Preset {
  id: number;
  name: string;
  display_order: number;
  instance_count: number;
}

export interface PresetDetail extends Preset {
  instances: (PresetInstance & { instance_name: string; instance_ip: string })[];
}

export interface ScheduleInput {
  name: string;
  cron_expression: string;
  start_date: string | null;
  stop_date: string | null;
  enabled: boolean;
  preset_id: number;
}

export interface Schedule extends ScheduleInput {
  id: number;
  preset_name: string;
}

type ScheduleRow = Omit<Schedule, 'enabled'> & { enabled: number };

export type Store = ReturnType<typeof createStore>;

export function createStore(db: Db) {
  const nextOrder = (table: string) =>
    db.prepare(`SELECT COALESCE(MAX(display_order) + 1, 0) FROM ${table}`).pluck().get() as number;

  const reorder = (table: string, ids: number[]) =>
    db.transaction(() => {
      const update = db.prepare(`UPDATE ${table} SET display_order = ? WHERE id = ?`);
      ids.forEach((id, index) => update.run(index, id));
    })();

  const setPresetInstances = (presetId: number, instances: PresetInstance[]) => {
    db.prepare('DELETE FROM preset_instances WHERE preset_id = ?').run(presetId);
    const insert = db.prepare(
      'INSERT INTO preset_instances (preset_id, instance_id, instance_preset) VALUES (?, ?, ?)',
    );
    for (const instance of instances) {
      insert.run(presetId, instance.instance_id, JSON.stringify(instance.instance_preset));
    }
  };

  const toSchedule = ({ enabled, ...row }: ScheduleRow): Schedule => ({ ...row, enabled: enabled === 1 });

  const scheduleSelect = `
    SELECT s.id, s.name, s.cron_expression, s.start_date, s.stop_date, s.enabled, s.preset_id, p.name AS preset_name
    FROM schedules s JOIN presets p ON p.id = s.preset_id`;

  return {
    instances: (): Instance[] =>
      db.prepare('SELECT id, ip, name, display_order FROM instances ORDER BY display_order, id').all() as Instance[],

    instance: (id: number): Instance | undefined =>
      db.prepare('SELECT id, ip, name, display_order FROM instances WHERE id = ?').get(id) as Instance | undefined,

    createInstance(ip: string, name: string): number {
      return Number(
        db
          .prepare('INSERT INTO instances (ip, name, display_order) VALUES (?, ?, ?)')
          .run(ip, name, nextOrder('instances')).lastInsertRowid,
      );
    },

    updateInstance: (id: number, ip: string, name: string): boolean =>
      db.prepare('UPDATE instances SET ip = ?, name = ? WHERE id = ?').run(ip, name, id).changes > 0,

    /** Presets and schedules stay; the device just drops out of the presets it was in. */
    deleteInstance: (id: number): boolean => db.prepare('DELETE FROM instances WHERE id = ?').run(id).changes > 0,

    reorderInstances: (ids: number[]) => reorder('instances', ids),

    presets: (): Preset[] =>
      db
        .prepare(
          `SELECT p.id, p.name, p.display_order, COUNT(pi.instance_id) AS instance_count
           FROM presets p LEFT JOIN preset_instances pi ON pi.preset_id = p.id
           GROUP BY p.id ORDER BY p.display_order, p.id`,
        )
        .all() as Preset[],

    preset(id: number): PresetDetail | undefined {
      const preset = db
        .prepare(
          `SELECT p.id, p.name, p.display_order, COUNT(pi.instance_id) AS instance_count
           FROM presets p LEFT JOIN preset_instances pi ON pi.preset_id = p.id
           WHERE p.id = ? GROUP BY p.id`,
        )
        .get(id) as Preset | undefined;
      if (!preset) return undefined;

      const rows = db
        .prepare(
          `SELECT pi.instance_id, i.name AS instance_name, i.ip AS instance_ip, pi.instance_preset
           FROM preset_instances pi JOIN instances i ON i.id = pi.instance_id
           WHERE pi.preset_id = ? ORDER BY i.display_order, i.id`,
        )
        .all(id) as { instance_id: number; instance_name: string; instance_ip: string; instance_preset: string }[];

      return {
        ...preset,
        instances: rows.map((row) => ({ ...row, instance_preset: parseTarget(row.instance_preset) })),
      };
    },

    createPreset(name: string, instances: PresetInstance[]): number {
      return db.transaction(() => {
        const id = Number(
          db.prepare('INSERT INTO presets (name, display_order) VALUES (?, ?)').run(name, nextOrder('presets'))
            .lastInsertRowid,
        );
        setPresetInstances(id, instances);
        return id;
      })();
    },

    updatePreset(id: number, name: string, instances: PresetInstance[]): boolean {
      return db.transaction(() => {
        if (db.prepare('UPDATE presets SET name = ? WHERE id = ?').run(name, id).changes === 0) return false;
        setPresetInstances(id, instances);
        return true;
      })();
    },

    /** Also deletes the schedules that apply it. */
    deletePreset: (id: number): boolean => db.prepare('DELETE FROM presets WHERE id = ?').run(id).changes > 0,

    reorderPresets: (ids: number[]) => reorder('presets', ids),

    schedules: (): Schedule[] => (db.prepare(`${scheduleSelect} ORDER BY s.id`).all() as ScheduleRow[]).map(toSchedule),

    schedule(id: number): Schedule | undefined {
      const row = db.prepare(`${scheduleSelect} WHERE s.id = ?`).get(id) as ScheduleRow | undefined;
      return row && toSchedule(row);
    },

    createSchedule(input: ScheduleInput): number {
      return Number(
        db
          .prepare(
            `INSERT INTO schedules (name, cron_expression, start_date, stop_date, enabled, preset_id)
             VALUES (@name, @cron_expression, @start_date, @stop_date, @enabled, @preset_id)`,
          )
          .run({ ...input, enabled: input.enabled ? 1 : 0 }).lastInsertRowid,
      );
    },

    updateSchedule(id: number, input: ScheduleInput): boolean {
      return (
        db
          .prepare(
            `UPDATE schedules SET name = @name, cron_expression = @cron_expression, start_date = @start_date,
             stop_date = @stop_date, enabled = @enabled, preset_id = @preset_id WHERE id = @id`,
          )
          .run({ ...input, enabled: input.enabled ? 1 : 0, id }).changes > 0
      );
    },

    deleteSchedule: (id: number): boolean => db.prepare('DELETE FROM schedules WHERE id = ?').run(id).changes > 0,
  };
}

function parseTarget(json: string): DeviceTarget {
  const value: unknown = JSON.parse(json);
  return typeof value === 'object' && value !== null ? (value as DeviceState) : Number(value);
}
