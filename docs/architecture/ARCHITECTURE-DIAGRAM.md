# Production Kubernetes SaaS Hosting Platform — Architecture Diagram

## 1) Text-Tree Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────
│                        SINGLE-NODE KUBERNETES CLUSTER (SaaS Platform)                         │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                               │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         SHARED CORE SYSTEM (Cluster-Scoped)                            │   │
│  └───────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐     │
│  │ NAMESPACE: ingress-system                                                            │     │
│  │ ┌─────────────────────────────────────────────────────────────────────────────────┐ │     │
│  │ │ Traefik (DaemonSet / Deployment)                                                 │ │     │
│  │ │   - HTTP/HTTPS termination                                                       │ │     │
│  │ │   - ACME (Let's Encrypt) automatic TLS                                           │ │     │
│  │ │   - Host-based routing → Ingress resources (all namespaces)                      │ │     │
│  │ │   - TLSStore / IngressRoute CRDs                                                 │ │     │
│  │ └─────────────────────────────────────────────────────────────────────────────────┘ │     │
│  └─────────────────────────────────────────────────────────────────────────────────────┘     │
│                                          │                                                     │
│                                          ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐     │
│  │ NAMESPACE: dns-system                                                                │     │
│  │ ┌─────────────────────────────────────────────────────────────────────────────────┐ │     │
│  │ │ PowerDNS (StatefulSet)                                                           │ │     │
│  │ │   - API enabled (auth by API key)                                                 │ │     │
│  │ │   - Database-backed zones (MySQL/PostgreSQL)                                     │ │     │
│  │ │   - Automated zone creation via Panel API                                       │ │     │
│  │ │   - Recursor / Authoritative                                                     │ │     │
│  │ └─────────────────────────────────────────────────────────────────────────────────┘ │     │
│  └─────────────────────────────────────────────────────────────────────────────────────┘     │
│                                          │                                                     │
│  ┌──────────────────────────────────────┼──────────────────────────────────────────────────┐ │
│  │ NAMESPACE: mail-system                │                                                    │ │
│  │ ┌────────────────────────────────────┴──────────────────────────────────────────────┐   │ │
│  │ │ Postfix (Deployment)     Dovecot (Deployment)     Rspamd (Deployment)              │   │ │
│  │ │   - Virtual domains         - IMAP/POP3              - Spam/AV                     │   │ │
│  │ │   - MySQL virtual maps      - MySQL userdb          - DKIM verification            │   │ │
│  │ │   - Relay/Submission        - Maildir per domain    - Per-domain DKIM keys (K8s)    │   │ │
│  │ │                                                                                     │   │ │
│  │ │ MySQL (StatefulSet) — virtual_domains, virtual_users, virtual_aliases              │   │ │
│  │ │ SPF/DMARC/DKIM records → DNS (PowerDNS API)                                        │   │ │
│  │ └──────────────────────────────────────────────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘     │
│                                          │                                                     │
│  ┌──────────────────────────────────────┼──────────────────────────────────────────────────┐ │
│  │ NAMESPACE: backup-system              │                                                    │ │
│  │ ┌────────────────────────────────────┴──────────────────────────────────────────────┐   │ │
│  │ │ Velero (Deployment) + Restic                                                       │   │ │
│  │ │   - Label selector: tenant=true                                                    │   │ │
│  │ │   - S3-compatible backend                                                          │   │ │
│  │ │   - PVC backup (Restic)                                                            │   │ │
│  │ │   - Optional: exclude system namespaces                                            │   │ │
│  │ └──────────────────────────────────────────────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘     │
│                                          │                                                     │
│  ┌──────────────────────────────────────┼──────────────────────────────────────────────────┐ │
│  │ NAMESPACE: storage-system (optional) │ Longhorn (cluster-scoped operator)                │ │
│  │ ┌────────────────────────────────────┴──────────────────────────────────────────────┐   │ │
│  │ │ Longhorn Manager + Engine                                                          │   │ │
│  │ │   - Default StorageClass                                                           │   │ │
│  │ │   - Dynamic PVC provisioning                                                       │   │ │
│  │ │   - Snapshots / Recurring backups                                                 │   │ │
│  │ └──────────────────────────────────────────────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘     │
│                                          │                                                     │
│  ┌──────────────────────────────────────┼──────────────────────────────────────────────────┐ │
│  │ NAMESPACE: monitoring-system         │                                                     │ │
│  │ ┌────────────────────────────────────┴──────────────────────────────────────────────┐   │ │
│  │ │ Prometheus │ Grafana │ Node Exporter │ kube-state-metrics │ Pod metrics            │   │ │
│  │ └──────────────────────────────────────────────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘     │
│                                          │                                                     │
│  ┌──────────────────────────────────────┼──────────────────────────────────────────────────┐ │
│  │ NAMESPACE: panel-system              │                                                     │ │
│  │ ┌────────────────────────────────────┴──────────────────────────────────────────────┐   │ │
│  │ │ Panel API (Node.js/Go)  │  Panel Frontend (Next.js)  │  PostgreSQL                 │   │ │
│  │ │   - Provisioning logic (namespace, PVC, Ingress, DNS, Mail, DKIM, Backup labels)   │   │ │
│  │ │   - K8s API + PowerDNS API + Mail DB                                               │   │ │
│  │ └──────────────────────────────────────────────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                               │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                         TENANT NAMESPACES (cust-{customerId})                                 │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                               │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐  ┌─────────────────────┐   │
│  │ cust-1001                   │  │ cust-1002                   │  │ cust-100N           │   │
│  │ ┌─────────────────────────┐ │  │ ┌─────────────────────────┐ │  │ ...                 │   │
│  │ │ Deployment (web)        │ │  │ │ Deployment (web)        │ │  │                     │   │
│  │ │ Service (ClusterIP)     │ │  │ │ Service (ClusterIP)     │ │  │                     │   │
│  │ │ Ingress                 │ │  │ │ Ingress                 │ │  │                     │   │
│  │ │ PVC (web data)          │ │  │ │ PVC (web data)          │ │  │                     │   │
│  │ │ PVC (db, optional)      │ │  │ │ PVC (db, optional)     │  │  │                     │   │
│  │ │ ResourceQuota           │ │  │ │ ResourceQuota          │ │  │                     │   │
│  │ │ LimitRange              │ │  │ │ LimitRange             │ │  │                     │   │
│  │ │ NetworkPolicy           │ │  │ │ NetworkPolicy          │ │  │                     │   │
│  │ │ Labels: tenant=true     │ │  │ │ Labels: tenant=true    │ │  │                     │   │
│  │ │         customer-id=1001│ │  │ │         customer-id=1002│ │  │                     │   │
│  │ └─────────────────────────┘ │  │ └─────────────────────────┘ │  │                     │   │
│  │ NO mail containers          │  │ NO mail containers          │  │                     │   │
│  └─────────────────────────────┘  └─────────────────────────────┘  └─────────────────────┘   │
│                                                                                               │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  TRAFFIC FLOW:                                                                                │
│  Internet → Traefik (ingress-system) → Ingress (cust-*) → Service → Pod (web)                │
│  DNS: Panel API → PowerDNS API → zones. Mail: Panel API → mail-system MySQL + DKIM Secret    │
│  Backup: Velero selects namespaces with tenant=true → S3                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

## 2) Data Flow Summary

| Flow | Path |
|------|------|
| **HTTP/HTTPS** | Client → Traefik (host) → Ingress (tenant ns) → Service → Web Pod |
| **DNS** | Panel API → PowerDNS API → Zone created/updated |
| **Mail** | Internet → Traefik/mail ingress → Postfix → Dovecot (MySQL virtual) |
| **Mail config** | Panel API → MySQL (mail-system) + DKIM Secret (mail-system or tenant) |
| **Backup** | Velero → label selector (tenant=true) → Restic → S3 |
| **Storage** | PVC (tenant) → Longhorn → node disk |

## 3) Namespace Dependency Order (Bootstrap)

```
1. storage-system (Longhorn) — first, default StorageClass
2. dns-system (PowerDNS + DB)
3. mail-system (Postfix, Dovecot, Rspamd, MySQL)
4. ingress-system (Traefik)
5. backup-system (Velero)
6. monitoring-system (Prometheus, Grafana)
7. panel-system (API, Frontend, PostgreSQL)
8. cust-* (tenants, created by Panel)
```
