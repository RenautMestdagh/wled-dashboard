const axios = require('axios');
const db = require('../config/database');

class WLEDService {
    constructor() {
        this.timeout = 3000; // 3 second timeout
    }

    async getInstanceIp(instanceId) {
        return new Promise((resolve, reject) => {
            db.get(
                'SELECT ip FROM instances WHERE id = ?',
                [instanceId],
                (err, row) => {
                    if (err) return reject(err);
                    if (!row) return reject(new Error('Instance not found'));
                    resolve(row.ip);
                }
            );
        });
    }

    async sendCommand(instanceId, command) {
        const ip = await this.getInstanceIp(instanceId);
        const url = `http://${ip}/json/state`;

        const response = await axios.post(url, command, {
            timeout: this.timeout
        });

        // Update last_seen timestamp
        db.run(
            'UPDATE instances SET last_seen = CURRENT_TIMESTAMP WHERE id = ?',
            [instanceId]
        );

        return response.data;
    }

    async getState(instanceId) {
        const ip = await this.getInstanceIp(instanceId);
        const url = `http://${ip}/json/state`;

        const response = await axios.get(url, {
            timeout: this.timeout
        });

        // Update last_seen timestamp
        db.run(
            'UPDATE instances SET last_seen = CURRENT_TIMESTAMP WHERE id = ?',
            [instanceId]
        );

        return response.data;
    }

    async getDevicePresets(instanceId) {
        const ip = await this.getInstanceIp(instanceId);
        const url = `http://${ip}/presets.json`;

        try {
            const response = await axios.get(url, {
                timeout: this.timeout
            });

            // Update last_seen timestamp
            db.run(
                'UPDATE instances SET last_seen = CURRENT_TIMESTAMP WHERE id = ?',
                [instanceId]
            );

            return response.data;
        } catch (error) {
            console.error(`Failed to fetch presets from WLED instance ${instanceId}:`, error);
            throw new Error('Failed to retrieve WLED presets');
        }
    }
}

module.exports = new WLEDService();