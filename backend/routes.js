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

    db.run("INSERT INTO instances (ip, name) VALUES (?, ?)", [ip, name || `WLED-${ip}`], function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID, ip, name: name || `WLED-${ip}` });
    });
});

// Update instance
router.put("/instances/:id", (req, res) => {
    const { id } = req.params;
    const { ip, name } = req.body;

    db.run("UPDATE instances SET ip = ?, name = ? WHERE id = ?",
        [ip, name, id],
        function(err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id, ip, name });
        }
    );
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
