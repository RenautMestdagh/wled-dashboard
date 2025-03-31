const db = require('../config/database');
const {get} = require("axios");
const {getInstanceInfo} = require("../services/wled");

module.exports = {
    getAllInstances: async (req, res) => {
        try {
            // First get all instances from the database
            const instances = await new Promise((resolve, reject) => {
                db.all("SELECT * FROM instances ORDER BY name", [], (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                });
            });

            // Process each instance to check for empty names
            const processedInstances = await Promise.all(
                instances.map(async (instance) => {
                    // If name is not empty, return as-is
                    if (instance.name && instance.name.trim() !== '') {
                        return instance;
                    }

                    try {
                        const info = await getInstanceInfo(instance.id);
                        if (info && info.name) {
                            // Return the instance with updated name (only in response)
                            return { ...instance, name: info.name.trim() };
                        }
                    } catch (error) {
                        console.error(`Failed to fetch info for instance ${instance.id}:`, error);
                    }

                    return instance;
                })
            );

            res.json(processedInstances);
        } catch (error) {
            console.error('Failed to get instances:', error);
            res.status(500).json({ error: error.message });
        }
    },

    createInstance: async (req, res) => {
        const { ip, name } = req.body;

        // Validate input
        if (!ip) return res.status(400).json({ error: "IP address is required" });

        // Validate IP format (basic check)
        const ipRegex = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/;
        if (!ipRegex.test(ip)) {
            return res.status(400).json({ error: "Invalid IP address format" });
        }

        try {
            // 1. First verify the WLED instance is reachable
            const infoUrl = `http://${ip}/json/info`;
            const response = await get(infoUrl, {
                timeout: 3000 // 3 second timeout
            });

            // 2. Check if it's actually a WLED device
            if (!response.data || !response.data.ver) {
                return res.status(400).json({ error: "The device doesn't appear to be a WLED controller" });
            }

            // 3. Check for duplicate IP in database
            const existingInstance = await new Promise((resolve, reject) => {
                db.get("SELECT id FROM instances WHERE ip = ?", [ip], (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                });
            });

            if (existingInstance) {
                return res.status(409).json({ error: "A WLED instance with this IP already exists" });
            }

            // 4. Create the instance record
            const result = await new Promise((resolve, reject) => {
                db.run(
                    "INSERT INTO instances (ip, name) VALUES (?, ?)",
                    [
                        ip,
                        name
                    ],
                    function(err) {
                        if (err) reject(err);
                        else resolve(this);
                    }
                );
            });

            // 5. Return the created instance
            const newInstance = await new Promise((resolve, reject) => {
                db.get("SELECT * FROM instances WHERE id = ?", [result.lastID], (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                });
            });

            res.status(201).json(newInstance);
        } catch (error) {
            console.error("Failed to create instance:", error);

            if (error.code === 'ECONNABORTED') {
                res.status(408).json({ error: "Connection to WLED device timed out" });
            } else if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
                res.status(400).json({ error: "Could not connect to WLED device at this IP" });
            } else if (error.message.includes('SQLITE_CONSTRAINT')) {
                res.status(409).json({ error: "A WLED instance with this IP already exists" });
            } else {
                res.status(500).json({ error: "Failed to create WLED instance", details: error.message });
            }
        }
    },

    updateInstance: (req, res) => {
        const { id } = req.params;
        const { ip, name } = req.body;

        db.run(
            "UPDATE instances SET ip = COALESCE(?, ip), name = COALESCE(?, name) WHERE id = ?",
            [ip, name, id],
            function(err) {
                if (err) return res.status(500).json({ error: err.message });
                if (this.changes === 0) return res.status(404).json({ error: "Instance not found" });

                db.get("SELECT * FROM instances WHERE id = ?", [id], (err, row) => {
                    if (err) return res.status(500).json({ error: err.message });
                    res.json(row);
                });
            }
        );
    },

    deleteInstance: (req, res) => {
        const { id } = req.params;

        db.run("DELETE FROM instances WHERE id = ?", [id], function(err) {
            if (err) return res.status(500).json({ error: err.message });
            if (this.changes === 0) return res.status(404).json({ error: "Instance not found" });
            res.json({ success: true });
        });
    }
};