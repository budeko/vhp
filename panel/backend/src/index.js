const express = require('express');
const cors = require('cors');
const tenantRoutes = require('./routes/tenants');
const { getClient, runMigrations } = require('./db/client');
const { loadConfig } = require('./config');
const logger = require('./logger');

const config = loadConfig();
const app = express();
const PORT = config.port;

app.use(cors());
app.use(express.json());

app.use('/api', tenantRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

async function start() {
  const client = getClient();
  try {
    await runMigrations(client);
  } finally {
    await client.end();
  }
  app.listen(PORT, () => {
    logger.info('Panel API listening', { port: PORT, nodeEnv: config.nodeEnv });
  });
}

start().catch((err) => {
  logger.error('Startup failed', { error: err.message, stack: err.stack });
  process.exit(1);
});
