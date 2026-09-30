const express = require('express');
const { getPool, sql } = require('./db');
const { getMeta } = require('./meta');

const router = express.Router();

function q(name) {
  return '[' + String(name).replace(/]/g, ']]') + ']';
}

function sqlTypeFor(col) {
  const t = col.type.toLowerCase();
  if (t === 'int') return sql.Int;
  if (t === 'date') return sql.Date;
  if (t === 'nvarchar') return sql.NVarChar(col.maxLength > 0 ? col.maxLength / 2 : sql.MAX);
  if (t === 'varchar') return sql.VarChar(col.maxLength);
  return sql.NVarChar(sql.MAX);
}

async function resolveTable(name) {
  const meta = await getMeta();
  const table = meta.tables[name];
  if (!table) return null;
  return table;
}

async function resolveView(name) {
  const meta = await getMeta();
  return meta.views[name] || null;
}

// GET metadata bundle for the whole app (tables, relations, views, menu)
router.get('/meta', async (req, res) => {
  try {
    const meta = await getMeta();
    const menu = require('./menu.json');
    res.json({ tables: meta.tables, relations: meta.relations, views: meta.views, procs: meta.procs, menu });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

function sqlTypeForParamType(typeName) {
  const t = typeName.toLowerCase();
  if (t === 'int') return sql.Int;
  if (t === 'date') return sql.Date;
  return sql.NVarChar(200);
}

// 執行已標記 exposed_report 的預存程序（例如樞紐分析），參數名稱/型別皆由 sys.parameters 驗證
router.get('/proc/:name', async (req, res) => {
  try {
    const meta = await getMeta();
    const proc = meta.procs[req.params.name];
    if (!proc) return res.status(404).json({ error: 'unknown or unexposed procedure: ' + req.params.name });

    const pool = await getPool();
    const request = pool.request();
    for (const p of proc.params) {
      const val = req.query[p.name];
      if (val === undefined || val === '') return res.status(400).json({ error: 'missing parameter: ' + p.name });
      request.input(p.name, sqlTypeForParamType(p.type), val);
    }
    const result = await request.execute(proc.name);
    res.json({ rows: result.recordset });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/health', async (req, res) => {
  try {
    const pool = await getPool();
    await pool.request().query('SELECT 1 AS ok');
    res.json({ ok: true, time: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// GET rows from a table or view, optional equality filters via query string, optional top
router.get('/data/:name', async (req, res) => {
  try {
    const { name } = req.params;
    const table = await resolveTable(name);
    const view = !table && (await resolveView(name));
    if (!table && !view) return res.status(404).json({ error: 'unknown table/view: ' + name });

    const columnNames = table ? table.columns.map(c => c.name) : view.columns.map(c => c.name);
    const pool = await getPool();
    const request = pool.request();
    const whereClauses = [];
    for (const [key, value] of Object.entries(req.query)) {
      if (key === 'top') continue;
      if (!columnNames.includes(key)) continue;
      const paramName = 'f_' + key;
      request.input(paramName, sql.NVarChar(200), value);
      whereClauses.push(`${q(key)} = @${paramName}`);
    }
    const top = Math.min(parseInt(req.query.top, 10) || 500, 2000);
    const where = whereClauses.length ? 'WHERE ' + whereClauses.join(' AND ') : '';
    const orderCol = table && table.primaryKey.length ? table.primaryKey.map(q).join(', ') : null;
    const orderBy = orderCol ? `ORDER BY ${orderCol}` : '';
    const result = await request.query(`SELECT TOP (${top}) * FROM ${q(name)} ${where} ${orderBy}`);
    res.json({ rows: result.recordset, primaryKey: table ? table.primaryKey : [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST insert a row into a table
router.post('/data/:name', async (req, res) => {
  try {
    const { name } = req.params;
    const table = await resolveTable(name);
    if (!table) return res.status(404).json({ error: 'unknown table: ' + name });
    const values = req.body.values || {};

    const cols = table.columns.filter(c => !c.identity && !c.systemMaintained && Object.prototype.hasOwnProperty.call(values, c.name));
    if (!cols.length) return res.status(400).json({ error: 'no values supplied' });

    const pool = await getPool();
    const request = pool.request();
    cols.forEach(c => request.input(c.name, sqlTypeFor(c), values[c.name] === '' ? null : values[c.name]));
    const colList = cols.map(c => q(c.name)).join(', ');
    const paramList = cols.map(c => '@' + c.name).join(', ');
    await request.query(`INSERT INTO ${q(name)} (${colList}) VALUES (${paramList})`);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT update a row: body { keys: {pkCol: val}, values: {col: val} }
router.put('/data/:name', async (req, res) => {
  try {
    const { name } = req.params;
    const table = await resolveTable(name);
    if (!table) return res.status(404).json({ error: 'unknown table: ' + name });
    const { keys = {}, values = {} } = req.body;
    if (!table.primaryKey.every(k => Object.prototype.hasOwnProperty.call(keys, k))) {
      return res.status(400).json({ error: 'missing primary key value(s)' });
    }
    const updCols = table.columns.filter(c => !table.primaryKey.includes(c.name) && !c.identity && !c.systemMaintained && Object.prototype.hasOwnProperty.call(values, c.name));
    if (!updCols.length) return res.status(400).json({ error: 'no updatable values supplied' });

    const pool = await getPool();
    const request = pool.request();
    updCols.forEach(c => request.input('v_' + c.name, sqlTypeFor(c), values[c.name] === '' ? null : values[c.name]));
    table.primaryKey.forEach(k => {
      const col = table.columns.find(c => c.name === k);
      request.input('k_' + k, sqlTypeFor(col), keys[k]);
    });
    const setList = updCols.map(c => `${q(c.name)} = @v_${c.name}`).join(', ');
    const whereList = table.primaryKey.map(k => `${q(k)} = @k_${k}`).join(' AND ');
    await request.query(`UPDATE ${q(name)} SET ${setList} WHERE ${whereList}`);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE a row: body { keys: {pkCol: val} }
router.delete('/data/:name', async (req, res) => {
  try {
    const { name } = req.params;
    const table = await resolveTable(name);
    if (!table) return res.status(404).json({ error: 'unknown table: ' + name });
    const { keys = {} } = req.body;
    if (!table.primaryKey.every(k => Object.prototype.hasOwnProperty.call(keys, k))) {
      return res.status(400).json({ error: 'missing primary key value(s)' });
    }
    const pool = await getPool();
    const request = pool.request();
    table.primaryKey.forEach(k => {
      const col = table.columns.find(c => c.name === k);
      request.input('k_' + k, sqlTypeFor(col), keys[k]);
    });
    const whereList = table.primaryKey.map(k => `${q(k)} = @k_${k}`).join(' AND ');
    await request.query(`DELETE FROM ${q(name)} WHERE ${whereList}`);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
