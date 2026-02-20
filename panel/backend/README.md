# Panel Backend (API)

Placeholder for the Panel API service (Node.js or Go).

## Responsibilities

- **Provisioning**: Implement the flow in `docs/architecture/PROVISIONING-FLOW.md` (namespace, ResourceQuota, LimitRange, PVC, Deployment, Service, Ingress, PowerDNS zone/records, mail DB rows, DKIM Secret, backup labels).
- **Kubernetes**: Use in-cluster config or kubeconfig; ServiceAccount `panel-api` has ClusterRole `panel-api-provisioner`.
- **PowerDNS**: HTTP API at `http://powerdns.dns-system.svc.cluster.local:8081`; header `X-API-Key`.
- **Mail**: MySQL at `mail-mysql.mail-system.svc.cluster.local:3306`; database `mail`, tables `virtual_domains`, `virtual_users`, `virtual_aliases`, `dkim_selectors`.
- **Database**: PostgreSQL for Panel state (customers, domains, plans); connection from Secret `panel-api-secrets`, key `database-url`.

## Suggested stack

- **Node.js**: Express/Fastify; `@kubernetes/client-node`, `axios` for PowerDNS, `mysql2` and `pg` for DBs.
- **Go**: `client-go`, `net/http` for PowerDNS, `database/sql` with `pg` and MySQL drivers.

## Environment

- `DATABASE_URL`, `POWERDNS_API_URL`, `POWERDNS_API_KEY`, `MAIL_MYSQL_DSN` (see `k8s/system/panel-system/panel-api-deployment.yaml`).
