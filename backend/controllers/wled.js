const wledService = require('../services/wled');

module.exports = {
    setState: async (req, res) => {
        try {
            const { instanceId } = req.params;
            const state = req.body;

            if (!state || typeof state !== 'object') {
                return res.status(400).json({ error: 'Invalid state payload' });
            }

            const result = await wledService.sendCommand(instanceId, state);
            res.json(result);
        } catch (error) {
            res.status(502).json({
                error: 'Failed to communicate with WLED instance',
                details: error.message
            });
        }
    },

    getState: async (req, res) => {
        try {
            const { instanceId } = req.params;
            const state = await wledService.getState(instanceId);
            res.json(state);
        } catch (error) {
            res.status(502).json({
                error: 'Failed to get WLED state',
                details: error.message
            });
        }
    },

    getWledPresets: async (req, res) => {
        try {
            const { instanceId } = req.params;

            // Validate instance ID
            if (!instanceId || isNaN(instanceId)) {
                return res.status(400).json({ error: 'Valid instance ID required' });
            }

            const presets = await wledService.getDevicePresets(instanceId);
            res.json(presets);
        } catch (error) {
            console.error('Failed to fetch WLED presets:', error);
            res.status(502).json({
                error: 'Failed to communicate with WLED device',
                details: error.message
            });
        }
    }
};