const express = require('express');
const router = express.Router();
const { getTenants, createTenant } = require('../services/tenantService');
const logger = require('../logger');

function structuredError(res, code, message, errorCode = 'ERROR') {
  return res.status(code).json({
    error: {
      message,
      code: errorCode,
    },
  });
}

router.get('/tenants', async (req, res) => {
  try {
    const tenants = await getTenants();
    res.json({ tenants });
  } catch (err) {
    logger.error('GET /api/tenants failed', { error: err.message, stack: err.stack });
    structuredError(res, 500, err.message, 'LIST_TENANTS_FAILED');
  }
});

router.post('/tenant', express.json(), async (req, res) => {
  const id = req.body?.id;
  if (!id || typeof id !== 'string') {
    return structuredError(res, 400, 'Missing or invalid body.id', 'INVALID_INPUT');
  }
  const sanitized = id.replace(/[^a-z0-9-]/gi, '').toLowerCase();
  if (!sanitized) {
    return structuredError(res, 400, 'id must contain at least one alphanumeric character', 'INVALID_INPUT');
  }
  try {
    const tenant = await createTenant(sanitized);
    logger.info('Tenant created', { id: tenant.id, namespace: tenant.namespace });
    res.status(201).json(tenant);
  } catch (err) {
    logger.error('POST /api/tenant failed', {
      id: sanitized,
      error: err.message,
      code: err.code,
    });
    const code = err.code === 'DUPLICATE' ? 409 : 500;
    const errorCode = err.code === 'DUPLICATE' ? 'TENANT_EXISTS' : 'PROVISION_FAILED';
    structuredError(res, code, err.message, errorCode);
  }
});

module.exports = router;
