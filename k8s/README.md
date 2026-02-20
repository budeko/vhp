# Kubernetes SaaS Platform Manifests

Production-ready single-node multi-tenant SaaS hosting platform.

## Folder Structure

```
k8s/
├── system/           # Shared core system namespaces
│   ├── ingress-system/
│   ├── dns-system/
│   ├── mail-system/
│   ├── backup-system/
│   ├── storage-system/
│   ├── monitoring-system/
│   └── panel-system/
├── tenants/          # Tenant namespace templates
│   └── templates/
├── storage/          # StorageClass, Longhorn configs
├── mail/             # Mail-related shared configs (scripts, schemas)
├── dns/              # DNS zone templates, API usage
├── ingress/          # Global ingress configs, TLS
└── backup/           # Velero schedules, restore procedures
```

## Deployment Order

1. `storage/` — Longhorn, default StorageClass
2. `system/dns-system/`
3. `system/mail-system/`
4. `system/ingress-system/`
5. `system/backup-system/`
6. `system/monitoring-system/`
7. `system/panel-system/`
8. Tenants via Panel API using `tenants/templates/`

## See Also

- `docs/architecture/` — Full architecture, scaling, security.
