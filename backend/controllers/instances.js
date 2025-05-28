const db = require('../config/database');
const { get } = require("axios");
const MulticastDNS = require('multicast-dns');

// Helper functions to reduce duplication
const dbQuery = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
};

const dbGet = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.get(sql, params, (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });
};

const dbRun = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function(err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
};

// Transaction helper functions
const beginTransaction = () => dbRun('BEGIN TRANSACTION');
const commitTransaction = () => dbRun('COMMIT');
const rollbackTransaction = () => dbRun('ROLLBACK').catch(() => {});

// Validation helpers
const validateIP = (ip) => {
    if (!ip) return { valid: false, message: "IP address is required" };
    const ipRegex = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/;
    return ipRegex.test(ip)
        ? { valid: true }
        : { valid: false, message: "Invalid IP address format" };
};

const checkWLEDConnection = async (ip) => {
    try {
        const infoUrl = `http://${ip}/json/info`;
        const response = await get(infoUrl, { timeout: 3000 });

        if (!response.data || !response.data.ver) {
            return { success: false, status: 400, message: "The device doesn't appear to be a WLED controller" };
        }

        return { success: true, data: response.data };
    } catch (error) {
        if (error.code === 'ECONNABORTED') {
            return { success: false, status: 408, message: "Connection to WLED device timed out" };
        } else if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
            return { success: false, status: 400, message: "Could not connect to WLED device at this IP" };
        } else {
            return { success: false, status: 500, message: error.message };
        }
    }
};

const addInstance = async (ip, name) => {
    try {
        // Get the next display order
        const maxOrderResult = await dbGet("SELECT MAX(display_order) as maxOrder FROM instances");
        const nextOrder = maxOrderResult.maxOrder !== null ? maxOrderResult.maxOrder + 1 : 0;

        // Create instance
        await dbRun(
            "INSERT INTO instances (ip, name, display_order) VALUES (?, ?, ?)",
            [ip, name, nextOrder]
        );

        return true;
    } catch (error) {
        console.error("Failed to add discovered instance:", error);
        return false;
    }
};


module.exports = {
    getAllInstances: async (req, res) => {
        try {
            const instances = await dbQuery("SELECT * FROM instances ORDER BY display_order");
            res.json(instances);
        } catch (error) {
            console.error('Failed to get instances:', error);
            res.status(500).json({ error: error.message });
        }
    },

    autoDiscoverInstances: async (req, res) => {
        try {
            // Array to store discovered WLED devices
            const wledDevices = [];

            // Create an mDNS instance
            const mdns = MulticastDNS();

            // Handle response packets
            mdns.on('response', async (packet) => {
                // Process answers and additionals for SRV and A records
                const records = [...(packet.answers || []), ...(packet.additionals || [])];

                for (const record of records) {
                    if (record.type === 'SRV') {
                        const port = record.data.port;
                        const target = record.data.target;

                        // Find corresponding A record for IP
                        const aRecord = records.find(
                            (r) => r.name === target && r.type === 'A'
                        );

                        if (aRecord && aRecord.data) {
                            const ip = aRecord.data;

                            // Verify if it's a WLED device by querying /json/info
                            try {
                                const response = await get(`http://${ip}:${port}/json/info`, {
                                    timeout: 2000, // 2-second timeout for API request
                                });

                                if (response.status === 200 && response.data.ver) {
                                    wledDevices.push({
                                        ip: ip,
                                    });
                                }
                            } catch (error) {
                                console.log(`Skipping ${ip}: Not a valid WLED device or unreachable`);
                            }
                        }
                    }
                }
            });

            // Query for _http._tcp.local services
            mdns.query({
                questions: [
                    {
                        name: '_http._tcp.local',
                        type: 'PTR',
                    },
                ],
            });

            // Stop discovery after 5 seconds and send response
            setTimeout(async () => {
                mdns.destroy();

                // Process each discovered device
                let newInstances = false;
                for (const device of wledDevices) {
                    try {
                        // Check if device already exists
                        const existingInstance = await dbGet("SELECT id FROM instances WHERE ip = ?", [device.ip]);

                        if (!existingInstance) {
                            // Add new device using our new helper function
                            await addInstance(device.ip, '');
                            newInstances = true;
                        }
                    } catch (error) {
                        console.error(`Error processing device ${device.ip}:`, error);
                    }
                }

                res.status(200).json({
                    message: 'WLED device discovery completed',
                    totalFound: wledDevices.length,
                    newInstances: newInstances,
                });

            }, 2500);

        } catch (error) {
            console.error('Discovery error:', error);
            res.status(500).json({ message: 'Error during autodiscovery', error: error.message });
        }
    },

    createInstance: async (req, res) => {
        const { ip, name } = req.body;

        // Validate IP
        const ipValidation = validateIP(ip);
        if (!ipValidation.valid) {
            return res.status(400).json({ error: ipValidation.message });
        }

        try {
            // Check if we can connect to the WLED device
            const connectionCheck = await checkWLEDConnection(ip);
            if (!connectionCheck.success) {
                return res.status(connectionCheck.status).json({ error: connectionCheck.message });
            }

            // Check for duplicate IP
            const existingInstance = await dbGet("SELECT id FROM instances WHERE ip = ?", [ip]);
            if (existingInstance) {
                return res.status(409).json({ error: "A WLED instance with this IP already exists" });
            }

            const success = await addInstance(ip, name);
            if (!success) {
                throw new Error("Failed to create instance");
            }

            // Get the newly created instance
            const newInstance = await dbGet("SELECT * FROM instances WHERE id = LAST_INSERT_ROWID()");
            newInstance.supportsRGB = [1, 3, 7].includes(connectionCheck.data.leds.lc);

            res.status(201).json(newInstance);
        } catch (error) {
            console.error("Failed to create instance:", error);

            if (error.message.includes('SQLITE_CONSTRAINT')) {
                res.status(409).json({ error: "A WLED instance with this IP already exists" });
            } else {
                res.status(500).json({ error: "Failed to create WLED instance", details: error.message });
            }
        }
    },

    updateInstance: async (req, res) => {
        const { id } = req.params;
        const { ip, name } = req.body;

        try {
            // Only validate and check connection if IP is provided
            if (ip) {
                // Validate IP format
                const ipValidation = validateIP(ip);
                if (!ipValidation.valid) {
                    return res.status(400).json({ error: ipValidation.message });
                }

                // Check for duplicate IP
                const existingInstance = await dbGet(
                    "SELECT id FROM instances WHERE ip = ? AND id != ?",
                    [ip, id]
                );

                if (existingInstance) {
                    return res.status(409).json({ error: "A WLED instance with this IP already exists" });
                }

                // Check if we can connect to the WLED device
                const connectionCheck = await checkWLEDConnection(ip);
                if (!connectionCheck.success) {
                    return res.status(connectionCheck.status).json({ error: connectionCheck.message });
                }
            }

            // Update instance
            const result = await dbRun(
                "UPDATE instances SET ip = COALESCE(?, ip), name = COALESCE(?, name) WHERE id = ?",
                [ip, name, id]
            );

            if (result.changes === 0) {
                return res.status(404).json({ error: "Instance not found" });
            }

            // Get updated instance
            let instance = await dbGet("SELECT * FROM instances WHERE id = ?", [id]);

            res.json(instance);
        } catch (error) {
            console.error('Failed to update instance:', error);
            res.status(500).json({ error: error.message });
        }
    },

    deleteInstance: async (req, res) => {
        const { id } = req.params;

        try {
            // Delete the instance
            const result = await dbRun("DELETE FROM instances WHERE id = ?", [id]);

            if (result.changes === 0) {
                return res.status(404).json({ error: "Instance not found" });
            }

            // Clean up orphaned presets
            await dbRun(`
        DELETE FROM presets 
        WHERE id IN (
          SELECT p.id 
          FROM presets p
          LEFT JOIN preset_instances pi ON p.id = pi.preset_id
          WHERE pi.preset_id IS NULL
        )
      `);

            res.json({ success: true });
        } catch (error) {
            console.error('Failed to delete instance:', error);
            res.status(500).json({ error: error.message });
        }
    },

    reorderInstances: async (req, res) => {
        const { orderedIds } = req.body;

        // Validate input
        if (!Array.isArray(orderedIds) || orderedIds.length === 0) {
            return res.status(400).json({ error: "orderedIds must be a non-empty array of instance IDs" });
        }

        try {
            await beginTransaction();

            // Update the order for each ID in the array
            for (let index = 0; index < orderedIds.length; index++) {
                const id = orderedIds[index];
                await dbRun("UPDATE instances SET display_order = ? WHERE id = ?", [index, id]);
            }

            await commitTransaction();

            // Return the reordered instances
            const instances = await dbQuery("SELECT * FROM instances ORDER BY display_order");
            res.json(instances);
        } catch (error) {
            await rollbackTransaction();
            console.error('Failed to reorder instances:', error);
            res.status(500).json({ error: error.message });
        }
    },
};