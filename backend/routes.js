const express = require("express");
const db = require("./db");

const router = express.Router();

// Get all instances
router.get("/instances", (req, res) => {
    db.all("SELECT * FROM instances", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Add new instance
router.post("/instances", (req, res) => {
    const { ip, name } = req.body;
    if (!ip) return res.status(400).json({ error: "IP is required" });

    db.run("INSERT INTO instances (ip, name) VALUES (?, ?)",
        [ip, name || ''],
        function (err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({
                id: this.lastID,
                ip,
                name: name || '',
            });
        }
    );
});

// Update instance (partial update support)
router.put("/instances/:id", (req, res) => {
    const { id } = req.params;
    const updateFields = [];
    const updateValues = [];

    // Dynamically build update query
    if (req.body.ip !== undefined) {
        updateFields.push("ip = ?");
        updateValues.push(req.body.ip);
    }
    if (req.body.name !== undefined) {
        updateFields.push("name = ?");
        updateValues.push(req.body.name);
    }

    // If no fields to update, return error
    if (updateFields.length === 0) {
        return res.status(400).json({ error: "No update fields provided" });
    }

    // Add id to the end of values for WHERE clause
    updateValues.push(id);

    // Construct dynamic update query
    const updateQuery = `UPDATE instances SET ${updateFields.join(", ")} WHERE id = ?`;

    db.run(updateQuery, updateValues, function(err) {
        if (err) return res.status(500).json({ error: err.message });

        // Fetch the updated instance to return full details
        db.get("SELECT * FROM instances WHERE id = ?", [id], (fetchErr, row) => {
            if (fetchErr) return res.status(500).json({ error: fetchErr.message });
            if (!row) return res.status(404).json({ error: "Instance not found" });

            res.json(row);
        });
    });
});

// Delete instance
router.delete("/instances/:id", (req, res) => {
    const { id } = req.params;
    db.run("DELETE FROM instances WHERE id = ?", id, function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ deleted: this.changes > 0 });
    });
});


// Get all presets with their instances
router.get("/presets", (req, res) => {
    db.all(`
        SELECT p.id, p.name, 
               json_group_array(
                   json_object(
                       'instance_id', pi.instance_id,
                       'preset_value', pi.preset_value
                   )
               ) as instances
        FROM presets p
        LEFT JOIN preset_instances pi ON p.id = pi.preset_id
        GROUP BY p.id, p.name
    `, [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });

        // Parse the JSON strings for instances
        const result = rows.map(row => ({
            id: row.id,
            name: row.name,
            instances: row.instances ? JSON.parse(row.instances) : []
        }));

        res.json(result);
    });
});

// Create a new preset with instances
router.post("/presets", (req, res) => {
    const { name, instances } = req.body;

    if (!name) return res.status(400).json({ error: "Preset name is required" });

    db.serialize(() => {
        db.run("INSERT INTO presets (name) VALUES (?)", [name], function(err) {
            if (err) return res.status(500).json({ error: err.message });

            const presetId = this.lastID;

            if (instances && instances.length > 0) {
                const stmt = db.prepare("INSERT INTO preset_instances (preset_id, instance_id, preset_value) VALUES (?, ?, ?)");

                instances.forEach(instance => {
                    stmt.run([presetId, instance.instance_id, instance.preset_value]);
                });

                stmt.finalize(err => {
                    if (err) return res.status(500).json({ error: err.message });

                    // Return the full preset with instances
                    getPresetWithInstances(presetId, res);
                });
            } else {
                // Return the preset without instances
                res.json({
                    id: presetId,
                    name,
                    instances: []
                });
            }
        });
    });
});

// Update a preset (name and/or instances)
router.put("/presets/:id", (req, res) => {
    const presetId = req.params.id;
    const { name, instances } = req.body;

    db.serialize(() => {
        // Update preset name if provided
        if (name) {
            db.run("UPDATE presets SET name = ? WHERE id = ?", [name, presetId], function(err) {
                if (err) return res.status(500).json({ error: err.message });
            });
        }

        // If instances are provided, replace all existing ones
        if (instances) {
            db.run("DELETE FROM preset_instances WHERE preset_id = ?", [presetId], function(err) {
                if (err) return res.status(500).json({ error: err.message });

                if (instances.length > 0) {
                    const stmt = db.prepare("INSERT INTO preset_instances (preset_id, instance_id, preset_value) VALUES (?, ?, ?)");

                    instances.forEach(instance => {
                        stmt.run([presetId, instance.instance_id, instance.preset_value]);
                    });

                    stmt.finalize(err => {
                        if (err) return res.status(500).json({ error: err.message });

                        // Return the full updated preset
                        getPresetWithInstances(presetId, res);
                    });
                } else {
                    // Return the preset with no instances
                    getPresetWithInstances(presetId, res);
                }
            });
        } else {
            // If only name was updated, return the full preset
            getPresetWithInstances(presetId, res);
        }
    });
});

// Delete a preset
router.delete("/presets/:id", (req, res) => {
    const presetId = req.params.id;

    db.serialize(() => {
        // First delete the preset instances
        db.run("DELETE FROM preset_instances WHERE preset_id = ?", [presetId], function(err) {
            if (err) return res.status(500).json({ error: err.message });

            // Then delete the preset itself
            db.run("DELETE FROM presets WHERE id = ?", [presetId], function(err) {
                if (err) return res.status(500).json({ error: err.message });

                res.json({ deleted: this.changes > 0 });
            });
        });
    });
});

// Helper function to get a preset with its instances
function getPresetWithInstances(presetId, res) {
    db.get(`
        SELECT p.id, p.name, 
               json_group_array(
                   json_object(
                       'instance_id', pi.instance_id,
                       'preset_value', pi.preset_value
                   )
               ) as instances
        FROM presets p
        LEFT JOIN preset_instances pi ON p.id = pi.preset_id
        WHERE p.id = ?
        GROUP BY p.id, p.name
    `, [presetId], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!row) return res.status(404).json({ error: "Preset not found" });

        const result = {
            id: row.id,
            name: row.name,
            instances: row.instances ? JSON.parse(row.instances) : []
        };

        res.json(result);
    });
}


module.exports = router;