#!/usr/bin/env node
const { getClient, runMigrations } = require('./client');

async function main() {
  const client = getClient();
  await runMigrations(client);
  await client.end();
  console.log('Migrations done.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
