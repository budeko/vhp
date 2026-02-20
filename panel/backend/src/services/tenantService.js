const { getClient } = require('../db/client');
const { provisionTenant } = require('./k8s');
const logger = require('../logger');

const NS_PREFIX = 'cust-';

async function getTenants() {
  const client = getClient();
  await client.connect();
  try {
    const r = await client.query(
      'SELECT id, namespace, created_at FROM tenants ORDER BY created_at DESC'
    );
    return r.rows.map((row) => ({
      id: row.id,
      namespace: row.namespace,
      created_at: row.created_at,
    }));
  } finally {
    await client.end();
  }
}

async function createTenant(id) {
  const namespace = `${NS_PREFIX}${id}`;
  const tenantDomain = process.env.TENANT_DOMAIN || 'example.local';

  const client = getClient();
  await client.connect();
  try {
    await client.query('INSERT INTO tenants (id, namespace) VALUES ($1, $2)', [
      id,
      namespace,
    ]);
  } catch (e) {
    if (e.code === '23505') {
      const err = new Error('Tenant already exists');
      err.code = 'DUPLICATE';
      throw err;
    }
    throw e;
  } finally {
    await client.end();
  }

  await provisionTenant(id, namespace);
  return {
    id,
    namespace,
    message: `Tenant ${id} provisioned. Site: http://${id}.${tenantDomain}`,
  };
}

module.exports = { getTenants, createTenant };
