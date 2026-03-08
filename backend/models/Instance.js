const Model = require('./Model');
const db = require('../config/database');

class Instance extends Model {
    static get table() { return 'instances'; }

    static cleanupOrphanedPresets() {
        db.prepare(`
            DELETE FROM presets 
            WHERE id IN (
              SELECT p.id 
              FROM presets p
              LEFT JOIN preset_instances pi ON p.id = pi.preset_id
              WHERE pi.preset_id IS NULL
            )
        `).run();
    }
}

module.exports = Instance;
