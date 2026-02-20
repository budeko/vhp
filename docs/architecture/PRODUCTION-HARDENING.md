# Production Hardening Checklist

## Before Go-Live

### Cluster

- [ ] Kubernetes version supported and patched (e.g. 1.28+).
- [ ] etcd backups enabled and tested.
- [ ] Control plane and nodes: OS hardened (minimal packages, no SSH root, key-based SSH).
- [ ] Node auto-repair/reboot policy if using managed node groups.

### Storage

- [ ] Longhorn: default StorageClass set; volume replica count and scheduling tested.
- [ ] Backup and restore of a sample PVC verified (Velero + Restic).
- [ ] Reclaim policy: Delete vs Retain documented; critical data consider Retain and explicit cleanup.

### DNS

- [ ] PowerDNS schema applied; API key rotated from default.
- [ ] Zone creation and record update tested from Panel API.
- [ ] Authoritative NS records point to your nameservers; glue records at registrar if required.

### Mail

- [ ] MySQL schema applied (mail.virtual_domains, virtual_users, virtual_aliases).
- [ ] Postfix/Dovecot config: passwords from Secrets (not ConfigMap).
- [ ] DKIM signing path and Rspamd config verified; at least one test domain sends and signs.
- [ ] SPF/DMARC/DKIM records created via Panel for test domain; deliverability checked.
- [ ] Shared auth socket between Postfix and Dovecot: use shared volume (RWX) or sidecar; test submission and IMAP.

### Ingress & TLS

- [ ] Traefik ACME: production Let's Encrypt; email and terms accepted.
- [ ] Wildcard vs per-domain certs decided; rate limits considered.
- [ ] Traefik dashboard disabled or protected (auth, network).

### Panel

- [ ] Panel API: database migrations run; env (DB URL, PowerDNS URL, Mail DSN, K8s) correct.
- [ ] Panel API RBAC: only required cluster resources; no cluster-admin.
- [ ] Frontend: API URL and auth (e.g. OIDC, API key) configured.
- [ ] Provisioning flow run end-to-end: namespace, quota, PVC, deployment, service, ingress, DNS zone, mail domain, DKIM secret, backup label.

### Monitoring & Ops

- [ ] Prometheus scraping; retention and storage sized.
- [ ] Grafana: datasource Prometheus; dashboards for node, pod, Traefik (if metrics exposed).
- [ ] Alerts: disk, pod OOMKilled, deployment not ready; route to PagerDuty/Slack/email.
- [ ] Log aggregation (e.g. Loki, Elasticsearch) optional but recommended.

### Backup & DR

- [ ] Velero schedule for tenant namespaces (label selector) enabled and one backup verified.
- [ ] Restore of one tenant namespace (including PVC) tested.
- [ ] Document RTO/RPO; runbook for restore.

### Security

- [ ] All items in SECURITY-CHECKLIST.md reviewed and implemented where applicable.
- [ ] No default passwords in checked-in manifests; use CI or sealed-secrets for sensitive values.
- [ ] Image scanning (e.g. Trivy) in pipeline; no critical/high in production images.
- [ ] NetworkPolicy applied to all tenant namespaces; default-deny egress where appropriate.

### Documentation & Runbooks

- [ ] Runbook: add tenant, remove tenant, restore tenant, rotate secrets, scale node.
- [ ] Architecture diagram and folder structure (this repo) up to date.
- [ ] Contact and escalation for incidents defined.

## Ongoing

- [ ] Regular dependency and CVE updates (K8s, Traefik, PowerDNS, Postfix, Dovecot, Rspamd, Panel).
- [ ] Quarterly restore drill.
- [ ] Review ResourceQuota and actual usage; adjust plans.
- [ ] Review Velero backup success and retention.
