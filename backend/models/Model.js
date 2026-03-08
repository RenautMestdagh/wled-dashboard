const db = require('../config/database');

class Model {
    static get table() { throw new Error('Not implemented'); }

    constructor(data = {}) {
        Object.assign(this, data);
    }

    static all(orderBy = null) {
        let sql = `SELECT * FROM ${this.table}`;
        if (orderBy) sql += ` ORDER BY ${orderBy}`;
        return db.prepare(sql).all().map(data => new this(data));
    }

    static find(id) {
        const data = db.prepare(`SELECT * FROM ${this.table} WHERE id = ?`).get(id);
        return data ? new this(data) : null;
    }

    static findBy(column, value, excludeId = null) {
        let sql = `SELECT * FROM ${this.table} WHERE ${column} = ?`;
        const params = [value];
        if (excludeId !== null) {
             sql += ` AND id != ?`;
             params.push(excludeId);
        }
        const data = db.prepare(sql).get(...params);
        return data ? new this(data) : null;
    }

    static where(column, value) {
        const data = db.prepare(`SELECT * FROM ${this.table} WHERE ${column} = ?`).all(value);
        return data.map(d => new this(d));
    }

    static create(data) {
        // filter out undefined
        const cleanData = Object.fromEntries(Object.entries(data).filter(([_, v]) => v !== undefined));
        
        const columns = Object.keys(cleanData).join(', ');
        const placeholders = Object.keys(cleanData).map(() => '?').join(', ');
        const values = Object.values(cleanData);
        
        const info = db.prepare(`INSERT INTO ${this.table} (${columns}) VALUES (${placeholders})`).run(...values);
        return info.lastInsertRowid;
    }

    static update(id, data) {
        // filter out undefined
        const cleanData = Object.fromEntries(Object.entries(data).filter(([_, v]) => v !== undefined));
        
        if (Object.keys(cleanData).length === 0) return { changes: 0 };
        const setClause = Object.keys(cleanData).map(key => `${key} = ?`).join(', ');
        const values = [...Object.values(cleanData), id];
        
        return db.prepare(`UPDATE ${this.table} SET ${setClause} WHERE id = ?`).run(...values);
    }

    static delete(id) {
        return db.prepare(`DELETE FROM ${this.table} WHERE id = ?`).run(id);
    }

    static exists(id) {
        return !!db.prepare(`SELECT 1 FROM ${this.table} WHERE id = ?`).get(id);
    }

    static max(column) {
        const result = db.prepare(`SELECT MAX(${column}) as maxVal FROM ${this.table}`).get();
        return result.maxVal !== null ? result.maxVal : -1;
    }
    
    static transaction(fn) {
        return db.transaction(fn);
    }

    update(data) {
        this.constructor.update(this.id, data);
        Object.assign(this, data);
        return this;
    }

    delete() {
        return this.constructor.delete(this.id);
    }
}

module.exports = Model;
