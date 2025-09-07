const cron = require('node-cron');
const db = require('../config/database');
const presetsController = require('./presets');

// Store active cron jobs
const activeCrons = new Map();

// Database helper functions
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

// Validate cron expression
const isValidCronExpression = (expression) => {
    try {
        return cron.validate(expression);
    } catch (error) {
        return false;
    }
};

// Check if schedule should execute now
const shouldExecuteSchedule = (schedule) => {
    const now = new Date();

    // Check if schedule is enabled
    if (!schedule.enabled) {
        return false;
    }

    // Check start date
    if (schedule.start_date && new Date(schedule.start_date) > now) {
        return false;
    }

    // Check stop date
    if (schedule.stop_date && new Date(schedule.stop_date) < now) {
        return false;
    }

    return true;
};

// Wrapper to use the existing applyPreset function
const applyPresetById = async (presetId) => {
    try {
        const mockReq = { params: { id: presetId } };
        const mockRes = {
            json: (data) => {
                console.log(`Successfully applied preset ${presetId}:`, data.message);
                return data;
            },
            status: (code) => ({
                json: (data) => {
                    console.error(`Failed to apply preset ${presetId} (status ${code}):`, data.error);
                    return data;
                }
            })
        };

        await presetsController.applyPreset(mockReq, mockRes);
    } catch (error) {
        console.error(`Error applying preset ${presetId}:`, error);
    }
};

// Schedule a single cron job
const scheduleCronJob = async (schedule) => {
    if (!isValidCronExpression(schedule.cron_expression)) {
        console.error(`Invalid cron expression for schedule ${schedule.id}: ${schedule.cron_expression}`);
        return;
    }

    try {
        const job = cron.schedule(schedule.cron_expression, async () => {
            console.log(`Cron triggered for schedule ${schedule.id} (${schedule.name}) at ${new Date().toISOString()}`);

            // Get fresh schedule data from database to check current status
            try {
                const currentSchedule = await dbGet(`
                    SELECT id, name, cron_expression, start_date, stop_date, enabled, preset_id
                    FROM preset_schedules WHERE id = ?
                `, [schedule.id]);

                if (!currentSchedule) {
                    console.log(`Schedule ${schedule.id} no longer exists, stopping cron job`);
                    stopCronJob(schedule.id);
                    return;
                }

                // Check if we should execute now
                if (shouldExecuteSchedule(currentSchedule)) {
                    console.log(`Executing schedule ${schedule.id} (${schedule.name})`);
                    await applyPresetById(currentSchedule.preset_id);
                } else {
                    console.log(`Schedule ${schedule.id} is not active (enabled: ${currentSchedule.enabled}, start: ${currentSchedule.start_date}, stop: ${currentSchedule.stop_date})`);

                    // Auto-stop if schedule is disabled or permanently expired
                    if (!currentSchedule.enabled || (currentSchedule.stop_date && new Date(currentSchedule.stop_date) < new Date())) {
                        console.log(`Auto-stopping cron job for schedule ${schedule.id}`);
                        stopCronJob(schedule.id);
                    }
                }
            } catch (error) {
                console.error(`Error checking schedule status ${schedule.id}:`, error);
            }
        });

        activeCrons.set(schedule.id, job);
        console.log(`Scheduled job for schedule ${schedule.id}: ${schedule.cron_expression}`);
    } catch (error) {
        console.error(`Failed to schedule job for schedule ${schedule.id}:`, error);
    }
};

// Stop and remove a cron job
const stopCronJob = (scheduleId) => {
    const job = activeCrons.get(scheduleId);
    if (job) {
        job.stop();
        activeCrons.delete(scheduleId);
        console.log(`Stopped cron job for schedule ${scheduleId}`);
    }
};

// Initialize all cron jobs at server start
const initializeCronJobs = async () => {
    try {
        const schedules = await dbQuery(`
            SELECT id, name, cron_expression, start_date, stop_date, enabled, preset_id
            FROM preset_schedules
            WHERE enabled = 1
        `);

        console.log(`Initializing ${schedules.length} cron jobs...`);

        for (const schedule of schedules) {
            await scheduleCronJob(schedule);
        }

        console.log(`Cron jobs initialized. Active jobs: ${activeCrons.size}`);
    } catch (error) {
        console.error('Failed to initialize cron jobs:', error);
    }
};

// Update a cron job (stop old, start new if enabled)
const updateCronJob = async (scheduleId) => {
    // Stop existing job
    stopCronJob(scheduleId);

    // Get updated schedule
    try {
        const schedule = await dbGet(`
            SELECT id, name, cron_expression, start_date, stop_date, enabled, preset_id
            FROM preset_schedules
            WHERE id = ?
        `, [scheduleId]);

        if (schedule && schedule.enabled) {
            await scheduleCronJob(schedule);
        }
    } catch (error) {
        console.error(`Failed to update cron job for schedule ${scheduleId}:`, error);
    }
};

// Get all active cron jobs
const getActiveCronJobs = () => {
    const jobs = [];
    for (const [scheduleId, job] of activeCrons.entries()) {
        jobs.push({
            scheduleId,
            expression: job.options.cron,
            running: job.task.isRunning()
        });
    }
    return jobs;
};

module.exports = {
    initializeCronJobs,
    scheduleCronJob,
    stopCronJob,
    updateCronJob,
    getActiveCronJobs,
    isValidCronExpression,
    activeCrons
};