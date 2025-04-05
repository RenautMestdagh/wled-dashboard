const express = require('express');
const router = express.Router();
const instancesController = require('../controllers/instances');
const presetsController = require('../controllers/presets');

// Instance routes
router.get('/instances', instancesController.getAllInstances);
router.post('/instances', instancesController.createInstance);
router.put('/instances/:id', instancesController.updateInstance);
router.delete('/instances/:id', instancesController.deleteInstance);
router.post('/instances/reorder', instancesController.reorderInstances);

// Preset routes
router.get('/presets', presetsController.getAllPresets);
router.get('/presets/:id', presetsController.getPresetDetails);
router.post('/presets', presetsController.createPreset);
router.put('/presets/:id', presetsController.updatePreset);
router.delete('/presets/:id', presetsController.deletePreset);
router.post('/presets/:id/apply', presetsController.applyPreset);
router.post('/presets/reorder', presetsController.reorderPresets);

module.exports = router;