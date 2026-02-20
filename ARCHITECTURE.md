# SaaS Core Panel — Architecture (Phase 1)

## Text Tree Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SINGLE-NODE K3S CLUSTER                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ ingress-system (namespace)                                            │   │
│  │   └── Traefik (Deployment + Service + IngressRoute)                   │   │
│  │       • Wildcard: *.example.local                                      │   │
│  │       • Routes to panel-system + tenant namespaces                     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                    ┌─────────────────┼─────────────────┐                     │
│                    ▼                 ▼                 ▼                     │
│  ┌─────────────────────────┐ ┌─────────────────────────────────────────┐   │
│  │ panel-system (namespace)│ │ tenant namespaces: cust-{id}             │   │
│  │                         │ │   • cust-1, cust-2, ...                  │   │
│  │  • panel-backend        │ │   • ResourceQuota                        │   │
│  │  • panel-frontend       │ │   • PVC (local-path)                     │   │
│  │  • PostgreSQL           │ │   • nginx Deployment + Service           │   │
│  │  • panel-db (PVC)       │ │   • Ingress: {id}.example.local          │   │
│  └─────────────────────────┘ └─────────────────────────────────────────┘   │
│                                                                              │
│  Storage: default StorageClass (local-path)                                   │
└─────────────────────────────────────────────────────────────────────────────┘

Request flow:
  Browser → *.example.local → Traefik → panel.example.local (panel) or {id}.example.local (tenant nginx)
```

## Namespaces

| Namespace      | Purpose                                      |
|----------------|----------------------------------------------|
| `ingress-system` | Traefik ingress controller                  |
| `panel-system`   | Panel backend, frontend, PostgreSQL         |
| `cust-{id}`      | Per-tenant: nginx site + PVC + Ingress      |

## APIs (Phase 1)

- `POST /api/tenant` — Create tenant (namespace, quota, PVC, nginx, Service, Ingress)
- `GET /api/tenants` — List tenants (from DB)

No authentication in Phase 1.
