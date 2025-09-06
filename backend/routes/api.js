const express = require('express');
const router = express.Router();
const instancesController = require('../controllers/instances');
const presetsController = require('../controllers/presets');
const schedulesController = require('../controllers/schedules');

// Instance routes
router.get('/instances', instancesController.getAllInstances);
// router.post('/instances/autodiscover', instancesController.autoDiscoverInstances);
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

// Preset_schedules routes
router.get('/schedules', schedulesController.getAllSchedules);
router.get('/schedules/:id', schedulesController.getScheduleDetails);
router.post('/schedules', schedulesController.createSchedule);
router.put('/schedules/:id', schedulesController.updateSchedule);
router.delete('/schedules/:id', schedulesController.deleteSchedule);

module.exports = router;