# SaaS Core Panel — Phase 1

Minimal production-structured single-node Kubernetes (k3s) SaaS core: panel + tenant provisioning.

## Tech Stack

- **Cluster**: k3s (single node)
- **Ingress**: Traefik (wildcard `*.example.local`)
- **Backend**: Node.js (Express)
- **Frontend**: Next.js (minimal dashboard)
- **Database**: PostgreSQL
- **Storage**: default local-path

## Quick Start

```bash
# 1. Ensure kubectl and k3s (or any k8s) available
# 2. Add to /etc/hosts:
#    127.0.0.1 panel.example.local api.example.local

./scripts/install.sh
```

Then open https://panel.example.local (or http if no TLS).

## Create Tenant (example)

```bash
curl -X POST http://api.example.local/api/tenant \
  -H "Content-Type: application/json" \
  -d '{"id": "acme"}'
```

Tenant site: http://acme.example.local

## Project Structure

See [ARCHITECTURE.md](./ARCHITECTURE.md) for the diagram and namespace layout.

```
project-root/
  ARCHITECTURE.md
  README.md
  INSTALL.md
  .env.example
  k8s/
    ingress/
      namespace.yaml
      traefik.yaml
    panel/
      namespace.yaml
      panel-secrets.yaml
      postgres.yaml
      panel-backend-rbac.yaml
      panel-backend.yaml
      panel-frontend.yaml
      ingress.yaml
    tenant-templates/
      tenant-namespace.yaml
      tenant-resource-quota.yaml
      tenant-pvc.yaml
      tenant-nginx.yaml
      tenant-ingress.yaml
  panel/
    backend/
      package.json
      Dockerfile
      src/
        index.js
        db/
          client.js
          migrate.js
          schema.sql
        routes/
          tenants.js
        services/
          tenantService.js
          k8s.js
    frontend/
      package.json
      next.config.js
      tsconfig.json
      Dockerfile
      app/
        layout.tsx
        page.tsx
        globals.css
      public/
        .gitkeep
  scripts/
    install.sh
    uninstall.sh
```

## Phase 1 Scope

- Core panel infrastructure
- Tenant namespace + nginx + ingress provisioning
- No: mail, backup, MinIO, DNS automation, monitoring, advanced storage
