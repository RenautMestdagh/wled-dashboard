const Preset = require('../models/Preset');

module.exports = {
    getAllPresets: async (req, res) => {
        try {
            const presets = Preset.all('display_order');
            res.json(presets.map(p => p.toSummaryJSON()));
        } catch (error) {
            console.error('Failed to get presets:', error);
            res.status(500).json({ error: 'Failed to retrieve presets' });
        }
    },

    getPresetDetails: async (req, res) => {
        try {
            const { id } = req.params;
            const preset = Preset.find(id);

            if (!preset) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            res.json(preset.toDetailJSON());
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

            let presetId;
            Preset.transaction(() => {
                const maxOrder = Preset.max('display_order');
                const nextOrder = maxOrder !== -1 ? maxOrder + 1 : 0;

                // Insert preset
                presetId = Preset.create({ name: name.trim(), display_order: nextOrder });

                // Associate instances
                const preset = Preset.find(presetId);
                preset.associateInstances(instances);
            })();

            // Return the created preset
            const newPreset = Preset.find(presetId);
            res.status(201).json(newPreset.toDetailJSON());
        } catch (error) {
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

            Preset.transaction(() => {
                // Update preset name if provided
                if (name) {
                    const result = Preset.update(id, { name: name.trim() });
                    if (result.changes === 0) {
                        throw new Error('Preset not found');
                    }
                }

                // Update instances if provided
                if (instances !== undefined) {
                    const preset = Preset.find(id);
                    if (preset) {
                        preset.clearInstances();
                        preset.associateInstances(instances);
                    }
                }
            })();

            // Return the updated preset
            const updatedPreset = Preset.find(id);
            res.json(updatedPreset.toDetailJSON());
        } catch (error) {
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
            const presetExists = Preset.exists(id);

            if (!presetExists) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            // Delete preset (preset_instances will be deleted due to CASCADE)
            const result = Preset.delete(id);

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
            const preset = Preset.find(id);

            if (!preset) {
                return res.status(404).json({ error: 'Preset not found' });
            }

            // Apply to each instance using the wledController
            const wledController = require('./wled');
            const results = await Promise.all(
                preset.instances.map(async instance => {
                    try {
                        // Check if instance_preset is a number or an object
                        const stateToApply = !isNaN(instance.instance_preset)
                            ? { ps: Number(instance.instance_preset) }
                            : typeof instance.instance_preset === 'string' ? JSON.parse(instance.instance_preset) : instance.instance_preset;

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
    },

    reorderPresets: async (req, res) => {
        const { orderedIds } = req.body;

        // Validate input
        if (!Array.isArray(orderedIds) || orderedIds.length === 0) {
            return res.status(400).json({ error: "orderedIds must be a non-empty array of preset IDs" });
        }

        try {
            Preset.transaction(() => {
                // Update the order for each ID in the array
                for (let index = 0; index < orderedIds.length; index++) {
                    const id = orderedIds[index];
                    Preset.update(id, { display_order: index });
                }
            })();

            // Return the reordered presets
            const presets = Preset.all('display_order');
            res.json(presets.map(p => p.toSummaryJSON()));
        } catch (error) {
            console.error('Failed to reorder presets:', error);
            res.status(500).json({ error: error.message });
        }
    },
};