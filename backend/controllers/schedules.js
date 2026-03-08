const Schedule = require('../models/Schedule');
const cronManager = require('./cronManager');

module.exports = {
    // GET /schedules
    getAllSchedules: async (req, res) => {
        try {
            const schedules = Schedule.all('id');
            res.json(schedules);
        } catch (error) {
            console.error('Failed to get schedules:', error);
            res.status(500).json({ error: 'Failed to retrieve schedules' });
        }
    },

    // GET /schedules/:id
    getScheduleDetails: async (req, res) => {
        try {
            const { id } = req.params;

            const schedule = Schedule.find(id);

            if (!schedule) {
                return res.status(404).json({ error: 'Schedule not found' });
            }

            res.json(schedule);
        } catch (error) {
            console.error(`Failed to get schedule ${req.params.id}:`, error);
            res.status(500).json({ error: 'Failed to retrieve schedule details' });
        }
    },

    // POST /schedules
    createSchedule: async (req, res) => {
        try {
            const { name, cron_expression, start_date, stop_date, enabled, preset_id } = req.body;

            if (!name || typeof name !== 'string' || !cron_expression || typeof cron_expression !== 'string' || !preset_id) {
                return res.status(400).json({ error: 'Missing or invalid required fields' });
            }

            const scheduleId = Schedule.create({
                name: name.trim(),
                cron_expression: cron_expression.trim(),
                start_date: start_date || null,
                stop_date: stop_date || null,
                enabled: enabled ? 1 : 0,
                preset_id
            });

            // Get the complete schedule with preset_name
            const newSchedule = Schedule.find(scheduleId);

            if (newSchedule.enabled) {
                cronManager.scheduleCronJob(newSchedule);
            }

            res.status(201).json(newSchedule);
        } catch (error) {
            console.error('Failed to create schedule:', error);
            if (error.message && error.message.includes('UNIQUE constraint failed')) {
                res.status(409).json({ error: 'Schedule with this name already exists' });
            } else {
                res.status(500).json({ error: 'Failed to create schedule' });
            }
        }
    },

    // PUT /schedules/:id
    updateSchedule: async (req, res) => {
        try {
            const { id } = req.params;
            const { name, cron_expression, start_date, stop_date, enabled, preset_id } = req.body;

            // Check if schedule exists
            const existing = Schedule.exists(id);
            if (!existing) {
                return res.status(404).json({ error: 'Schedule not found' });
            }

            // Update schedule dynamically covering partial updates from frontend
            const dataToUpdate = {};
            if (name !== undefined && name !== null) dataToUpdate.name = name;
            if (cron_expression !== undefined && cron_expression !== null) dataToUpdate.cron_expression = cron_expression;
            if (start_date !== undefined) dataToUpdate.start_date = start_date === 'CLEAR' ? null : start_date;
            if (stop_date !== undefined) dataToUpdate.stop_date = stop_date === 'CLEAR' ? null : stop_date;
            if (enabled !== undefined && enabled !== null) dataToUpdate.enabled = enabled ? 1 : 0;
            if (preset_id !== undefined && preset_id !== null) dataToUpdate.preset_id = preset_id;

            Schedule.update(id, dataToUpdate);

            // Get the complete updated schedule with preset_name
            const updated = Schedule.find(id);

            cronManager.updateCronJob(id);

            res.json(updated);
        } catch (error) {
            console.error(`Failed to update schedule ${req.params.id}:`, error);
            if (error.message && error.message.includes('UNIQUE constraint failed')) {
                res.status(409).json({ error: 'Schedule with this name already exists' });
            } else {
                res.status(500).json({ error: 'Failed to update schedule' });
            }
        }
    },

    // DELETE /schedules/:id
    deleteSchedule: async (req, res) => {
        try {
            const { id } = req.params;

            const existing = Schedule.exists(id);
            if (!existing) {
                return res.status(404).json({ error: 'Schedule not found' });
            }

            cronManager.stopCronJob(id);

            const result = Schedule.delete(id);

            if (result.changes === 0) {
                return res.status(404).json({ error: 'Schedule not found' });
            }

            res.json({ success: true });
        } catch (error) {
            console.error(`Failed to delete schedule ${req.params.id}:`, error);
            res.status(500).json({ error: 'Failed to delete schedule' });
        }
    },
};
