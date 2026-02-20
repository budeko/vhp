-- Panel database schema (Phase 1)
-- Run via migrate.js or manually after DB exists

CREATE TABLE IF NOT EXISTS tenants (
  id          VARCHAR(64) PRIMARY KEY,
  namespace   VARCHAR(128) NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tenants_created_at ON tenants(created_at);
