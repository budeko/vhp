# Production Kubernetes SaaS Hosting Platform — Documentation Index

## Architecture

| Document | Description |
|----------|-------------|
| [ARCHITECTURE-DIAGRAM.md](./ARCHITECTURE-DIAGRAM.md) | Text-tree architecture diagram, data flows, bootstrap order |
| [PROVISIONING-FLOW.md](./PROVISIONING-FLOW.md) | Pseudo-code for new domain provisioning (namespace, quota, PVC, deploy, ingress, DNS, mail, DKIM, backup label) |
| [RESOURCE-MANAGEMENT.md](./RESOURCE-MANAGEMENT.md) | Per-tenant CPU/memory/PVC limits; example ResourceQuota YAML |
| [STORAGE-DESIGN.md](./STORAGE-DESIGN.md) | PVC lifecycle, namespace delete behaviour, Longhorn snapshots |
| [SCALING-PLAN.md](./SCALING-PLAN.md) | Single node → multi-node and HA |
| [RESOURCE-ESTIMATION.md](./RESOURCE-ESTIMATION.md) | 16 GB RAM example; system + tenant capacity |
| [SECURITY-CHECKLIST.md](./SECURITY-CHECKLIST.md) | Cluster, network, secrets, tenant isolation, compliance |
| [PRODUCTION-HARDENING.md](./PRODUCTION-HARDENING.md) | Pre go-live and ongoing hardening checklist |
| [BACKUP-DESIGN.md](./BACKUP-DESIGN.md) | Velero label-based selection, PVC backup, restore per tenant |

## Folder Structure (Generated)

```
k8s/
├── system/
│   ├── ingress-system/    # Traefik, IngressClass, ConfigMap, Service, PVC
│   ├── dns-system/        # PowerDNS, PostgreSQL, schema Job, ConfigMap
│   ├── mail-system/       # MySQL, Postfix, Dovecot, Rspamd, ConfigMaps
│   ├── backup-system/     # Namespace; Velero via Helm (see backup/)
│   ├── storage-system/    # Namespace only; Longhorn in longhorn-system
│   ├── monitoring-system/ # Prometheus, Grafana, Node Exporter
│   └── panel-system/     # Panel API, Frontend, PostgreSQL
├── tenants/
│   └── templates/         # Namespace, ResourceQuota, LimitRange, NetworkPolicy, PVC, Deployment, Service, Ingress
├── storage/               # Longhorn StorageClass, README
├── mail/                  # Mail schema, architecture (multi-tenant, DNS, DKIM)
├── dns/                   # PowerDNS schema SQL, README (API usage)
├── ingress/               # README (Traefik, TLS, host-based routing)
└── backup/                # Velero values example, install notes, label-based selection

panel/
├── backend/               # Panel API (Node.js or Go) — provisioning logic
└── frontend/              # Next.js frontend
```

## Example YAML Locations

- **Ingress**: `k8s/system/ingress-system/` (Traefik deployment, config, IngressClass), `k8s/tenants/templates/ingress.yaml`
- **DNS**: `k8s/system/dns-system/` (PowerDNS, DB, schema job), `k8s/dns/powerdns-schema.pgsql.sql`
- **Mail**: `k8s/system/mail-system/` (MySQL, Postfix, Dovecot, Rspamd), `k8s/mail/mysql-schema.sql`
- **Backup**: `k8s/backup/velero-values-example.md`, `k8s/system/backup-system/namespace.yaml`
- **Storage**: `k8s/storage/storageclass-longhorn.yaml`, `k8s/storage/longhorn-README.md`
- **Monitoring**: `k8s/system/monitoring-system/` (Prometheus, Grafana, Node Exporter)
- **Panel**: `k8s/system/panel-system/` (API, Frontend, PostgreSQL)
- **Tenant**: `k8s/tenants/templates/` (all tenant resources; substitute CUSTOMER_ID and DOMAIN)

## Quick Start

1. Install Longhorn (or other CSI); apply `k8s/storage/storageclass-longhorn.yaml`.
2. Create PowerDNS schema ConfigMap and run schema Job (see `k8s/dns/README.md`).
3. Apply namespaces and system components in order: dns-system → mail-system → ingress-system → backup-system → monitoring-system → panel-system.
4. Deploy Panel API and Frontend; configure DB, PowerDNS API key, Mail DSN.
5. Provision tenants via Panel API using the flow in PROVISIONING-FLOW.md and templates in `k8s/tenants/templates/`.
