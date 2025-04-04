const db = require('../config/database');

// Database operation helper functions
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
        db.run(sql, params, function(err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
};

// Transaction helper functions
const beginTransaction = () => dbRun('BEGIN TRANSACTION');
const commitTransaction = () => dbRun('COMMIT');
const rollbackTransaction = () => dbRun('ROLLBACK').catch(() => {});

// Helper function to get preset details
const getPresetDetails = async (id) => {
    const preset = await dbGet(`
    SELECT 
      p.*,
      json_group_array(
        json_object(
          'instance_id', pi.instance_id,
          'instance_name', i.name,
          'instance_ip', i.ip,
          'instance_preset', pi.instance_preset
        )
      ) as instances
    FROM presets p
    LEFT JOIN preset_instances pi ON p.id = pi.preset_id
    LEFT JOIN instances i ON pi.instance_id = i.id
    WHERE p.id = ?
    GROUP BY p.id
  `, [id]);

    if (!preset) return null;

    return {
        id: preset.id,
        name: preset.name,
        created_at: preset.created_at,
        instances: preset.instances ? JSON.parse(preset.instances) : []
    };
};

// Helper to handle preset instance associations
const associateInstances = async (presetId, instances) => {
    if (!instances || instances.length === 0) return;

    const insertPromises = instances.map(instance =>
        dbRun(
            `INSERT INTO preset_instances (preset_id, instance_id, instance_preset) VALUES (?, ?, ?)`,
            [
                presetId,
                instance.instance_id,
                JSON.stringify(instance.instance_preset || {})
            ]
        )
    );

    await Promise.all(insertPromises);
};

module.exports = {
    getAllPresets: async (req, res) => {
        try {
            const presets = await dbQuery(`
        SELECT
          p.id,
          p.name,
          p.created_at,
          (SELECT COUNT(*) FROM preset_instances WHERE preset_id = p.id) as instance_count
        FROM presets p
        ORDER BY p.name
      `);

            res.json(presets);
        } catch (error) {
            console.error('Failed to get presets:', error);
            res.status(500).json({ error: 'Failed to retrieve presets' });
        }
    },

    getPresetDetails: async (req, res) => {
        try {
            const { id } = req.params;
            const result = await getPresetDetails(id);

            if (!result) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            res.json(result);
        } catch (error) {
            console.error(`Failed to get preset ${req.params.id}:`, error);
            res.status(500).json({ error: 'Failed to retrieve preset details' });
        }
    },

    createPreset: async (req, res) => {
        try {
            const { name, instances } = req.body;

            if (!name || typeof name !== 'string') {
                return res.status(400).json({ error: 'Valid preset name is required' });
            }

            await beginTransaction();

            // Insert preset
            const result = await dbRun('INSERT INTO presets (name) VALUES (?)', [name.trim()]);
            const presetId = result.lastID;

            // Associate instances
            await associateInstances(presetId, instances);

            await commitTransaction();

            // Return the created preset
            const newPreset = await getPresetDetails(presetId);
            res.status(201).json(newPreset);
        } catch (error) {
            await rollbackTransaction();
            console.error('Failed to create preset:', error);

            if (error.message && error.message.includes('UNIQUE constraint failed')) {
                res.status(409).json({ error: 'Preset with this name already exists' });
            } else {
                res.status(500).json({ error: 'Failed to create preset' });
            }
        }
    },

    updatePreset: async (req, res) => {
        try {
            const { id } = req.params;
            const { name, instances } = req.body;

            await beginTransaction();

            // Update preset name if provided
            if (name) {
                const result = await dbRun(
                    'UPDATE presets SET name = ? WHERE id = ?',
                    [name.trim(), id]
                );

                if (result.changes === 0) {
                    throw new Error('Preset not found');
                }
            }

            // Update instances if provided
            if (instances !== undefined) {
                // Delete existing instances
                await dbRun('DELETE FROM preset_instances WHERE preset_id = ?', [id]);

                // Add new instances
                await associateInstances(id, instances);
            }

            await commitTransaction();

            // Return the updated preset
            const updatedPreset = await getPresetDetails(id);
            res.json(updatedPreset);
        } catch (error) {
            await rollbackTransaction();
            console.error(`Failed to update preset ${req.params.id}:`, error);

            if (error.message === 'Preset not found') {
                res.status(404).json({ error: error.message });
            } else if (error.message && error.message.includes('UNIQUE constraint failed')) {
                res.status(409).json({ error: 'Preset with this name already exists' });
            } else {
                res.status(500).json({ error: 'Failed to update preset' });
            }
        }
    },

    deletePreset: async (req, res) => {
        try {
            const { id } = req.params;

            // Check if preset exists
            const presetExists = await dbGet('SELECT 1 FROM presets WHERE id = ?', [id]);

            if (!presetExists) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            // Delete preset (preset_instances will be deleted due to CASCADE)
            const result = await dbRun('DELETE FROM presets WHERE id = ?', [id]);

            if (result.changes === 0) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            res.json({ success: true });
        } catch (error) {
            console.error(`Failed to delete preset ${req.params.id}:`, error);
            res.status(500).json({ error: 'Failed to delete preset' });
        }
    },

    applyPreset: async (req, res) => {
        try {
            const { id } = req.params;

            // Get preset details
            const preset = await getPresetDetails(id);

            if (!preset) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            // Apply to each instance using the wledController
            const wledController = require('./wled');
            const results = await Promise.all(
                preset.instances.map(async instance => {
                    try {
                        // Check if instance_preset is a number or an object
                        const stateToApply = typeof instance.instance_preset === 'number'
                            ? { ps: instance.instance_preset }
                            : JSON.parse(instance.instance_preset);

                        // Call setState with the appropriate body
                        const result = await wledController.setState(
                            { params: { instanceId: instance.instance_id }, body: stateToApply },
                            { json: (data) => data, status: () => ({ json: (data) => data }) }
                        );

                        return {
                            instance_id: instance.instance_id,
                            instance_name: instance.instance_name,
                            success: true,
                            result
                        };
                    } catch (error) {
                        return {
                            instance_id: instance.instance_id,
                            instance_name: instance.instance_name,
                            success: false,
                            error: error.message
                        };
                    }
                })
            );

            res.json({
                success: true,
                message: `Preset "${preset.name}" applied to ${preset.instances.length} instances`,
                results
            });
        } catch (error) {
            console.error(`Failed to apply preset ${req.params.id}:`, error);
            res.status(500).json({ error: 'Failed to apply preset' });
        }
    }
};