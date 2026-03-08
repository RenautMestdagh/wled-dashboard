const axios = require('axios');
const Instance = require('../models/Instance');

class WLEDService {
    constructor() {
        this.timeout = 3000; // 3 second timeout
        this.getInstanceIp = this.getInstanceIp.bind(this);
        this.getInstanceInfo = this.getInstanceInfo.bind(this);
    }

    async getInstanceIp(instanceId) {
        const instance = Instance.find(instanceId);
        if (!instance) {
            throw new Error('Instance not found');
        }
        return instance.ip;
    }

    async sendCommand(instanceId, command) {
        const ip = await this.getInstanceIp(instanceId);
        const url = `http://${ip}/json/state`;

        const response = await axios.post(url, command, {
            timeout: this.timeout
        });

        // Update last_seen timestamp
        Instance.update(instanceId, { last_seen: new Date().toISOString() });

        return response.data;
    }

    async getState(instanceId) {
        const ip = await this.getInstanceIp(instanceId);
        const url = `http://${ip}/json/state`;

        const response = await axios.get(url, {
            timeout: this.timeout
        });

        // Update last_seen timestamp
        Instance.update(instanceId, { last_seen: new Date().toISOString() });

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
            Instance.update(instanceId, { last_seen: new Date().toISOString() });

            return response.data;
        } catch (error) {
            console.error(`Failed to fetch presets from WLED instance ${instanceId}`);
            throw new Error('Failed to retrieve WLED presets');
        }
    }

    async getInstanceInfo(instanceId) {
        const ip = await this.getInstanceIp(instanceId);
        const url = `http://${ip}/json/info`;

        try {
            const response = await axios.get(url, {
                timeout: this.timeout
            });

            // Update last_seen timestamp
            Instance.update(instanceId, { last_seen: new Date().toISOString() });

            return response.data;
        } catch (error) {
            console.error(`Failed to fetch info from WLED instance ${instanceId}`);
            throw new Error('Failed to retrieve WLED info');
        }
    }
}

module.exports = new WLEDService();