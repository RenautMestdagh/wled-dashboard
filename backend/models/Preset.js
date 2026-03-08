const Model = require('./Model');
const db = require('../config/database');

class Preset extends Model {
    static get table() { return 'presets'; }

    get instances() {
        if (!this._instances) {
            const rows = db.prepare(`
                SELECT i.*, pi.instance_preset 
                FROM instances i
                JOIN preset_instances pi ON i.id = pi.instance_id
                WHERE pi.preset_id = ?
            `).all(this.id);
            
            this._instances = rows.map(r => ({
                instance_id: r.id,
                instance_name: r.name,
                instance_ip: r.ip,
                instance_preset: r.instance_preset ? JSON.parse(r.instance_preset) : {}
            }));
        }
        return this._instances;
    }

    get instance_count() {
        return db.prepare(`SELECT COUNT(*) as count FROM preset_instances WHERE preset_id = ?`).get(this.id).count;
    }

    toSummaryJSON() {
        return {
            id: this.id,
            name: this.name,
            display_order: this.display_order,
            instance_count: this.instance_count
        };
    }

    toDetailJSON() {
        return {
            ...this.toSummaryJSON(),
            instances: this.instances
        };
    }

    associateInstances(instancesData) {
        if (!instancesData || instancesData.length === 0) return;
        const stmt = db.prepare(`INSERT INTO preset_instances (preset_id, instance_id, instance_preset) VALUES (?, ?, ?)`);
        for (const instance of instancesData) {
            stmt.run(this.id, instance.instance_id, JSON.stringify(instance.instance_preset || {}));
        }
        this._instances = null;
    }

    clearInstances() {
        db.prepare('DELETE FROM preset_instances WHERE preset_id = ?').run(this.id);
        this._instances = null;
    }
}

module.exports = Preset;
