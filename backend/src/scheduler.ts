import cron, { type ScheduledTask } from 'node-cron';
import { applyPreset } from './apply-preset.ts';
import type { Schedule, Store } from './store.ts';
import type { Wled } from './wled.ts';

export class Scheduler {
  #tasks = new Map<number, ScheduledTask>();
  #store: Store;
  #wled: Wled;

  constructor(store: Store, wled: Wled) {
    this.#store = store;
    this.#wled = wled;
  }

  start(): void {
    for (const schedule of this.#store.schedules()) this.sync(schedule.id);
  }

  /** Brings the job of a schedule in line with the database, after it was created, changed or deleted. */
  sync(id: number): void {
    void this.#tasks.get(id)?.destroy();
    this.#tasks.delete(id);

    const schedule = this.#store.schedule(id);
    if (!schedule?.enabled) return;
    // Earlier versions stored cron expressions without checking them
    if (!cron.validate(schedule.cron_expression)) {
      console.error(`Schedule "${schedule.name}" has an invalid cron expression: ${schedule.cron_expression}`);
      return;
    }
    this.#tasks.set(
      id,
      cron.schedule(schedule.cron_expression, () => this.#run(id), { name: `schedule-${id}` }),
    );
  }

  stop(): void {
    for (const task of this.#tasks.values()) void task.destroy();
    this.#tasks.clear();
  }

  async #run(id: number): Promise<void> {
    const schedule = this.#store.schedule(id);
    if (!schedule || !isActiveOn(schedule, new Date())) return;

    const preset = this.#store.preset(schedule.preset_id);
    if (!preset) return;
    for (const result of await applyPreset(this.#wled, preset)) {
      if (!result.ok)
        console.error(`Schedule "${schedule.name}": ${result.instance_name || result.instance_id}: ${result.error}`);
    }
  }
}

/** Start and stop dates are local calendar days, both included. */
export function isActiveOn(schedule: Pick<Schedule, 'start_date' | 'stop_date'>, now: Date): boolean {
  const pad = (n: number) => String(n).padStart(2, '0');
  const today = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
  return (!schedule.start_date || schedule.start_date <= today) && (!schedule.stop_date || today <= schedule.stop_date);
}
