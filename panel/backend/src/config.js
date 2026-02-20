/**
 * Validates required environment variables on startup.
 * Use when running in-cluster; KUBECONFIG is only for local/out-of-cluster.
 */
function loadConfig() {
  const errors = [];
  if (!process.env.DATABASE_URL) {
    errors.push('DATABASE_URL is required');
  }
  const tenantDomain = (process.env.TENANT_DOMAIN || 'example.local').trim();
  if (process.env.TENANT_DOMAIN && !/^[a-z0-9.-]+$/i.test(tenantDomain)) {
    errors.push('TENANT_DOMAIN must be a valid domain (e.g. example.local)');
  }
  if (errors.length) {
    throw new Error(`Configuration invalid: ${errors.join('; ')}`);
  }
  return {
    databaseUrl: process.env.DATABASE_URL,
    tenantDomain: tenantDomain.trim(),
    nodeEnv: process.env.NODE_ENV || 'production',
    port: parseInt(process.env.PORT || '3000', 10),
  };
}

module.exports = { loadConfig };
