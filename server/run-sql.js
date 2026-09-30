require('dotenv').config();
const fs = require('fs');
const path = require('path');
const sql = require('mssql');

for (const key of ['DB_SERVER', 'DB_USER', 'DB_PASSWORD']) {
  if (!process.env[key]) throw new Error(`Missing ${key} in environment (.env). Copy .env.example to .env and fill in credentials.`);
}

const config = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT || '1433', 10),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: 'master', // 每個 .sql 檔自己用 USE 切換到目標資料庫
  options: { encrypt: true, trustServerCertificate: true },
  connectionTimeout: 15000,
  requestTimeout: 30000,
};

const dbDir = path.join(__dirname, '..', 'db');
const files = fs.readdirSync(dbDir).filter(f => f.endsWith('.sql')).sort();

(async () => {
  const pool = await sql.connect(config);
  for (const file of files) {
    const text = fs.readFileSync(path.join(dbDir, file), 'utf8');
    const batches = text.split(/^\s*GO\s*$/im).map(b => b.trim()).filter(Boolean);
    console.log(`--- ${file} (${batches.length} batches) ---`);
    for (const batch of batches) {
      try {
        await pool.request().query(batch);
      } catch (err) {
        console.error(`ERROR in ${file}:`, err.message);
        console.error('Batch was:\n', batch.substring(0, 400));
        process.exitCode = 1;
      }
    }
  }
  await pool.close();
  console.log('ALL DONE');
})();
