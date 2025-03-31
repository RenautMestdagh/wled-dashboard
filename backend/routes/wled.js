const express = require('express');
const router = express.Router();
const wledController = require('../controllers/wled');

// WLED Control Endpoints
router.post('/:instanceId/state', wledController.setState);
router.get('/:instanceId/state', wledController.getState);

// Endpoint for wled presets
router.get('/:instanceId/presets.json', wledController.getWledPresets);

module.exports = router;