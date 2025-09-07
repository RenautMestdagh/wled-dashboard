const db = require('../config/database');
const cronManager = require('./cronManager');

// Helper functions
const dbQuery = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
};

const dbGet = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.get(sql, params, (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });
};

const dbRun = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function (err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
};

module.exports = {
    // GET /schedules
    getAllSchedules: async (req, res) => {
        try {
            const schedules = await dbQuery(`
                SELECT
                    ps.id,
                    ps.name,
                    ps.cron_expression,
                    ps.start_date,
                    ps.stop_date,
                    ps.enabled,
                    ps.preset_id,
                    p.name as preset_name
                FROM preset_schedules ps
                         JOIN presets p ON ps.preset_id = p.id
                ORDER BY ps.id
            `);

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

            const schedule = await dbGet(`
                SELECT
                    ps.id,
                    ps.name,
                    ps.cron_expression,
                    ps.start_date,
                    ps.stop_date,
                    ps.enabled,
                    ps.preset_id,
                    p.name as preset_name
                FROM preset_schedules ps
                         JOIN presets p ON ps.preset_id = p.id
                WHERE ps.id = ?
            `, [id]);

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

            const result = await dbRun(`
                INSERT INTO preset_schedules (name, cron_expression, start_date, stop_date, enabled, preset_id)
                VALUES (?, ?, ?, ?, ?, ?)
            `, [
                name.trim(),
                cron_expression.trim(),
                start_date || null,
                stop_date || null,
                enabled ? 1 : 0,
                preset_id
            ]);

            // Get the complete schedule with preset_name
            const newSchedule = await dbGet(`
                SELECT
                    ps.id,
                    ps.name,
                    ps.cron_expression,
                    ps.start_date,
                    ps.stop_date,
                    ps.enabled,
                    ps.preset_id,
                    p.name as preset_name
                FROM preset_schedules ps
                         JOIN presets p ON ps.preset_id = p.id
                WHERE ps.id = ?
            `, [result.lastID]);

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
            const existing = await dbGet(`SELECT * FROM preset_schedules WHERE id = ?`, [id]);
            if (!existing) {
                return res.status(404).json({ error: 'Schedule not found' });
            }

            // Handle special 'CLEAR' values for dates
            const processedStartDate = start_date === 'CLEAR' ? null : start_date;
            const processedStopDate = stop_date === 'CLEAR' ? null : stop_date;

            await dbRun(`
                UPDATE preset_schedules
                SET name = COALESCE(?, name),
                    cron_expression = COALESCE(?, cron_expression),
                    start_date = ?,
                    stop_date = ?,
                    enabled = COALESCE(?, enabled),
                    preset_id = COALESCE(?, preset_id)
                WHERE id = ?
            `, [
                name,
                cron_expression,
                processedStartDate,
                processedStopDate,
                enabled !== undefined ? (enabled ? 1 : 0) : null,
                preset_id,
                id
            ]);

            // Get the complete updated schedule with preset_name
            const updated = await dbGet(`
                SELECT
                    ps.id,
                    ps.name,
                    ps.cron_expression,
                    ps.start_date,
                    ps.stop_date,
                    ps.enabled,
                    ps.preset_id,
                    p.name as preset_name
                FROM preset_schedules ps
                         JOIN presets p ON ps.preset_id = p.id
                WHERE ps.id = ?
            `, [id]);

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

            const existing = await dbGet(`SELECT 1 FROM preset_schedules WHERE id = ?`, [id]);
            if (!existing) {
                return res.status(404).json({ error: 'Schedule not found' });
            }

            cronManager.stopCronJob(id);

            const result = await dbRun(`DELETE FROM preset_schedules WHERE id = ?`, [id]);

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
