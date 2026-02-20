const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

function getClient() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error('DATABASE_URL is required');
  return new Client({ connectionString: databaseUrl });
}

async function runMigrations(client) {
  await client.connect();
  const schemaPath = path.join(__dirname, 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');
  await client.query(sql);
}

module.exports = { getClient, runMigrations };
