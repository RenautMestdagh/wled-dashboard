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

module.exports = router;