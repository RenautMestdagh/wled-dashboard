const Model = require('./Model');
const Preset = require('./Preset');

class Schedule extends Model {
    static get table() { return 'schedules'; }

    get preset() {
        if (!this._preset && this.preset_id) {
            this._preset = Preset.find(this.preset_id);
        }
        return this._preset;
    }

    toJSON() {
        return {
            ...this, // copies standard columns
            preset_name: this.preset ? this.preset.name : null,
            _preset: undefined // don't serialize the cached object
        };
    }
}

module.exports = Schedule;
