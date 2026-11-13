import { HttpError } from './http.ts';
import type { PresetDetail } from './store.ts';
import type { Wled } from './wled.ts';

export interface ApplyResult {
  instance_id: number;
  instance_name: string;
  ok: boolean;
  error?: string;
}

export function applyPreset(wled: Wled, preset: PresetDetail): Promise<ApplyResult[]> {
  return Promise.all(
    preset.instances.map(async ({ instance_id, instance_name, instance_ip, instance_preset }) => {
      const state = typeof instance_preset === 'number' ? { ps: instance_preset } : instance_preset;
      try {
        await wled.setState(instance_ip, state);
        return { instance_id, instance_name, ok: true };
      } catch (error) {
        if (!(error instanceof HttpError)) throw error;
        return { instance_id, instance_name, ok: false, error: error.message };
      }
    }),
  );
}
