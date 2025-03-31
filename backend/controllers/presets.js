const db = require('../config/database');

// Helper function to get preset details - outside the exported object
const getPresetDetailsHelper = async (id) => {
    const preset = await new Promise((resolve, reject) => {
        db.get(`
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
        `, [id], (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });

    if (!preset) {
        return null;
    }

    return {
        id: preset.id,
        name: preset.name,
        created_at: preset.created_at,
        instances: preset.instances ? JSON.parse(preset.instances) : []
    };
};

module.exports = {
    getAllPresets: async (req, res) => {
        try {
            const presets = await new Promise((resolve, reject) => {
                db.all(`
                    SELECT
                        p.id,
                        p.name,
                        p.created_at,
                        (SELECT COUNT(*) FROM preset_instances WHERE preset_id = p.id) as instance_count
                    FROM presets p
                    ORDER BY p.name
                `, [], (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                });
            });
            res.json(presets);
        } catch (error) {
            console.error('Failed to get presets:', error);
            res.status(500).json({ error: 'Failed to retrieve presets' });
        }
    },

    getPresetDetails: async (req, res) => {
        try {
            const { id } = req.params;
            const result = await getPresetDetailsHelper(id);

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

            // Start transaction
            await new Promise((resolve, reject) => {
                db.run('BEGIN TRANSACTION', [], (err) => {
                    if (err) reject(err);
                    else resolve();
                });
            });

            // Insert preset
            const { lastID: presetId } = await new Promise((resolve, reject) => {
                db.run(
                    'INSERT INTO presets (name) VALUES (?)',
                    [name.trim()],
                    function(err) {
                        if (err) reject(err);
                        else resolve(this);
                    }
                );
            });

            // Insert associated instances if provided
            if (instances && instances.length > 0) {
                await Promise.all(
                    instances.map(instance => (
                        new Promise((resolve, reject) => {
                            db.run(
                                `INSERT INTO preset_instances
                                     (preset_id, instance_id, instance_preset)
                                 VALUES (?, ?, ?)`,
                                [
                                    presetId,
                                    instance.instance_id,
                                    JSON.stringify(instance.instance_preset || {})
                                ],
                                (err) => {
                                    if (err) reject(err);
                                    else resolve();
                                }
                            );
                        })
                    ))
                );
            }

            // Commit transaction
            await new Promise((resolve, reject) => {
                db.run('COMMIT', [], (err) => {
                    if (err) reject(err);
                    else resolve();
                });
            });

            // Return the created preset
            const newPreset = await getPresetDetailsHelper(presetId);

            res.status(201).json(newPreset);
        } catch (error) {
            // Rollback on error
            await new Promise((resolve) => {
                db.run('ROLLBACK', [], () => resolve());
            });

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

            // Start transaction
            await new Promise((resolve, reject) => {
                db.run('BEGIN TRANSACTION', [], (err) => {
                    if (err) reject(err);
                    else resolve();
                });
            });

            // Update preset name if provided
            if (name) {
                await new Promise((resolve, reject) => {
                    db.run(
                        'UPDATE presets SET name = ? WHERE id = ?',
                        [name.trim(), id],
                        function(err) {
                            if (err) reject(err);
                            else if (this.changes === 0) reject(new Error('Preset not found'));
                            else resolve();
                        }
                    );
                });
            }

            // Update instances if provided
            if (instances) {
                // First delete existing instances
                await new Promise((resolve, reject) => {
                    db.run(
                        'DELETE FROM preset_instances WHERE preset_id = ?',
                        [id],
                        (err) => {
                            if (err) reject(err);
                            else resolve();
                        }
                    );
                });

                // Then insert new instances
                if (instances.length > 0) {
                    await Promise.all(
                        instances.map(instance => (
                            new Promise((resolve, reject) => {
                                db.run(
                                    `INSERT INTO preset_instances
                                         (preset_id, instance_id, instance_preset)
                                     VALUES (?, ?, ?)`,
                                    [
                                        id,
                                        instance.instance_id,
                                        JSON.stringify(instance.instance_preset || {})
                                    ],
                                    (err) => {
                                        if (err) reject(err);
                                        else resolve();
                                    }
                                );
                            })
                        ))
                    );
                }
            }

            // Commit transaction
            await new Promise((resolve, reject) => {
                db.run('COMMIT', [], (err) => {
                    if (err) reject(err);
                    else resolve();
                });
            });

            // Return the updated preset
            const updatedPreset = await getPresetDetailsHelper(id);

            res.json(updatedPreset);
        } catch (error) {
            // Rollback on error
            await new Promise((resolve) => {
                db.run('ROLLBACK', [], () => resolve());
            });

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

            // First check if preset exists
            const presetExists = await new Promise((resolve, reject) => {
                db.get(
                    'SELECT 1 FROM presets WHERE id = ?',
                    [id],
                    (err, row) => {
                        if (err) reject(err);
                        else resolve(!!row);
                    }
                );
            });

            if (!presetExists) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            // Delete preset (preset_instances will be deleted automatically due to ON DELETE CASCADE)
            const { changes } = await new Promise((resolve, reject) => {
                db.run(
                    'DELETE FROM presets WHERE id = ?',
                    [id],
                    function(err) {
                        if (err) reject(err);
                        else resolve(this);
                    }
                );
            });

            if (changes === 0) {
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
            const preset = await getPresetDetailsHelper(id);

            if (!preset) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            // Apply to each instance using the wledController
            const wledController = require('./wled');
            const results = await Promise.all(
                preset.instances.map(async instance => {
                    try {
                        // Check if instance_preset is a number or an object
                        const stateToApply = typeof instance.instance_preset === 'number' ?
                            { ps: instance.instance_preset } :
                            instance.instance_preset;

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