# Security Checklist

## Cluster & API

- [ ] Restrict Kubernetes API (e.g. private endpoint, VPN, or allowlisted IPs).
- [ ] Enable RBAC; minimal roles for Panel API (only required resources and verbs).
- [ ] Use dedicated ServiceAccounts per namespace; no default SA for sensitive workloads.
- [ ] Rotate service account tokens; use short-lived tokens where supported.
- [ ] Audit logging: enable and ship to SIEM or log store.
- [ ] Admission: consider PodSecurityStandard (restricted/baseline) and OPA/Gatekeeper.

## Network

- [ ] NetworkPolicy: default-deny in tenant namespaces (only allow ingress from ingress-system, egress DNS + allowed egress).
- [ ] Tenant cannot reach mail-system MySQL, dns-system DB, or other tenants (verified by policy).
- [ ] Encrypt in-transit: TLS for Traefik, mail (SMTP TLS, IMAPS), Panel API, Grafana.
- [ ] Restrict NodePort/LoadBalancer exposure; use internal LB where possible.

## Secrets & Config

- [ ] No plaintext passwords in ConfigMaps; use Secrets for DB, API keys, ACME.
- [ ] PowerDNS API key, Panel DB URL, Mail MySQL DSN in Secrets; consider external secret manager (Vault, provider secrets).
- [ ] DKIM private keys only in Secrets in mail-system; restrict access via RBAC.
- [ ] Image pull secrets for private registries; use least-privilege registry credentials.

## Ingress & TLS

- [ ] HTTPS only (redirect HTTP→HTTPS); HSTS header.
- [ ] ACME (Let's Encrypt) with rate limits in mind; use staging for testing.
- [ ] Ingress host validation: only allow domains that belong to the customer (Panel enforces).

## Mail

- [ ] Postfix/Dovecot: strong auth (e.g. SHA512-CRYPT); no plaintext.
- [ ] Rspamd: keep rules updated; optional ClamAV for AV.
- [ ] Restrict SMTP relay to avoid abuse (only authenticated + known domains).

## Backup

- [ ] Velero/S3: encrypt backup storage (S3 SSE or client-side).
- [ ] Backup credentials stored in Secrets; restrict access to backup-system namespace.
- [ ] Test restore periodically.

## Panel & Provisioning

- [ ] Panel API: authenticate (JWT, API key); authorize by customerId (tenant cannot provision in another tenant namespace).
- [ ] Validate domain ownership (e.g. DNS TXT or HTTP challenge) before provisioning.
- [ ] Rate limit provisioning API to avoid abuse.
- [ ] Audit log all provisioning and deprovisioning actions.

## Tenant Isolation

- [ ] ResourceQuota and LimitRange applied to every tenant namespace.
- [ ] No hostPath or privileged pods in tenant namespaces unless explicitly required and controlled.
- [ ] Pod Security: restrict runAsRoot, readOnlyRootFilesystem where possible (LimitRange does not enforce this; use PSA or Gatekeeper).

## Compliance

- [ ] Document data residency (where PVC and backup data live).
- [ ] Retention policy for backups and logs.
- [ ] Process for handling tenant data deletion (GDPR etc.): delete namespace, purge backup references, purge mail DB and DNS zone.
