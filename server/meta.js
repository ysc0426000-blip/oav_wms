const { getPool } = require('./db');

let cache = null;
let cacheAt = 0;
const CACHE_MS = 60000;

async function loadMeta() {
  const pool = await getPool();

  const tablesRs = await pool.request().query(`
    SELECT t.name AS table_name, c.name AS column_name, ty.name AS data_type,
           c.max_length, c.is_nullable, c.is_identity, c.column_id
    FROM sys.tables t
    JOIN sys.columns c ON c.object_id = t.object_id
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE t.is_ms_shipped = 0
    ORDER BY t.name, c.column_id
  `);

  const sysMaintRs = await pool.request().query(`
    SELECT t.name AS table_name, c.name AS column_name
    FROM sys.extended_properties ep
    JOIN sys.tables t ON t.object_id = ep.major_id
    JOIN sys.columns c ON c.object_id = ep.major_id AND c.column_id = ep.minor_id
    WHERE ep.name = 'system_maintained'
  `);

  const pkRs = await pool.request().query(`
    SELECT t.name AS table_name, c.name AS column_name, ic.key_ordinal
    FROM sys.indexes i
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    JOIN sys.tables t ON t.object_id = i.object_id
    WHERE i.is_primary_key = 1
    ORDER BY t.name, ic.key_ordinal
  `);

  const fkRs = await pool.request().query(`
    SELECT fk.name AS fk_name,
           tp.name AS child_table, cp.name AS child_column,
           tr.name AS parent_table, cr.name AS parent_column
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
    JOIN sys.tables tp ON tp.object_id = fkc.parent_object_id
    JOIN sys.columns cp ON cp.object_id = fkc.parent_object_id AND cp.column_id = fkc.parent_column_id
    JOIN sys.tables tr ON tr.object_id = fkc.referenced_object_id
    JOIN sys.columns cr ON cr.object_id = fkc.referenced_object_id AND cr.column_id = fkc.referenced_column_id
    ORDER BY fk.name, fkc.constraint_column_id
  `);

  const viewsRs = await pool.request().query(`
    SELECT v.name AS view_name, c.name AS column_name, c.column_id
    FROM sys.views v
    JOIN sys.columns c ON c.object_id = v.object_id
    ORDER BY v.name, c.column_id
  `);

  // 只暴露有 'exposed_report' extended property標記的預存程序（樞紐分析等），
  // 避免任意 sp 透過通用 API 被呼叫。
  const procsRs = await pool.request().query(`
    SELECT p.name AS proc_name, pr.name AS param_name, ty.name AS data_type, pr.parameter_id
    FROM sys.procedures p
    JOIN sys.extended_properties ep ON ep.major_id = p.object_id AND ep.minor_id = 0 AND ep.name = 'exposed_report'
    LEFT JOIN sys.parameters pr ON pr.object_id = p.object_id
    LEFT JOIN sys.types ty ON ty.user_type_id = pr.user_type_id
    ORDER BY p.name, pr.parameter_id
  `);

  const tables = {};
  for (const row of tablesRs.recordset) {
    if (!tables[row.table_name]) tables[row.table_name] = { name: row.table_name, columns: [], primaryKey: [] };
    tables[row.table_name].columns.push({
      name: row.column_name,
      type: row.data_type,
      maxLength: row.max_length,
      nullable: !!row.is_nullable,
      identity: !!row.is_identity,
      systemMaintained: false,
    });
  }
  for (const row of pkRs.recordset) {
    if (tables[row.table_name]) tables[row.table_name].primaryKey.push(row.column_name);
  }
  for (const row of sysMaintRs.recordset) {
    const t = tables[row.table_name];
    if (!t) continue;
    const col = t.columns.find(c => c.name === row.column_name);
    if (col) col.systemMaintained = true;
  }

  const relations = [];
  const byFk = {};
  for (const row of fkRs.recordset) {
    if (!byFk[row.fk_name]) {
      byFk[row.fk_name] = { name: row.fk_name, childTable: row.child_table, parentTable: row.parent_table, columns: [] };
      relations.push(byFk[row.fk_name]);
    }
    byFk[row.fk_name].columns.push({ child: row.child_column, parent: row.parent_column });
  }

  const views = {};
  for (const row of viewsRs.recordset) {
    if (!views[row.view_name]) views[row.view_name] = { name: row.view_name, columns: [] };
    views[row.view_name].columns.push({ name: row.column_name });
  }

  const procs = {};
  for (const row of procsRs.recordset) {
    if (!procs[row.proc_name]) procs[row.proc_name] = { name: row.proc_name, params: [] };
    if (row.param_name) procs[row.proc_name].params.push({ name: row.param_name.replace(/^@/, ''), type: row.data_type });
  }

  cache = { tables, relations, views, procs };
  cacheAt = Date.now();
  return cache;
}

async function getMeta() {
  if (!cache || Date.now() - cacheAt > CACHE_MS) {
    await loadMeta();
  }
  return cache;
}

module.exports = { getMeta };
