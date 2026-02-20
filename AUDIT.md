# Phase 1 Audit — Problems Found and Fixes

## 1) Problems Found

| # | Area | Problem | Severity |
|---|------|---------|----------|
| 1 | Kubernetes auth | Backend used KUBECONFIG when set, even in-cluster; could use local kubeconfig instead of in-cluster | Critical |
| 2 | Kubernetes auth | No error handling when loading kubeconfig | Critical |
| 3 | RBAC | Backend ServiceAccount lacked `delete` on namespaces (required for rollback) | Critical |
| 4 | Tenant provisioning | No rollback on failure; partial state left in cluster | Critical |
| 5 | Tenant provisioning | No try/catch around provisioning with clear error propagation | Critical |
| 6 | YAML templates | Tenant ingress host hardcoded `example.local`; not configurable | Medium |
| 7 | Tenant nginx | No liveness or readiness probes | Medium |
| 8 | Install script | k3s install logic: installed only when both k3s and kubectl missing; should install when k3s missing | Medium |
| 9 | Install script | No explicit cluster check before proceeding; not fully idempotent | Medium |
| 10 | Install script | Did not wait for panel-frontend | Low |
| 11 | Environment | No startup validation of required env (DATABASE_URL); TENANT_DOMAIN not configurable | Medium |
| 12 | API | Errors returned as plain `{ error: string }`; no structured code for clients | Low |
| 13 | Logging | No structured logging; hard to parse in production | Low |

---

## 2) Why They Are Problematic

- **In-cluster auth:** When the backend runs inside the cluster, it must use the in-cluster service account. Relying on KUBECONFIG when set can pull in a local file that may be wrong or expired, breaking provisioning in production.

- **RBAC delete namespace:** Rollback on failed provisioning requires deleting the namespace and all resources. Without `delete` on namespaces, rollback leaves orphaned namespaces and wastes resources.

- **No rollback:** If creating the Ingress (or any step) fails after the namespace and other resources exist, the tenant is left in a broken state and the DB already has a row. Rollback keeps the system consistent and allows the user to retry.

- **Hardcoded domain:** Multi-environment or white-label setups need a configurable tenant domain; hardcoding blocks that.

- **No nginx probes:** Kubernetes cannot tell if the tenant nginx is alive or ready; rollout and recovery behavior are worse without probes.

- **Install script:** Idempotency and correct ordering (cluster check → k3s → ingress → panel → wait) avoid partial or repeated broken installs. Waiting for frontend ensures the full stack is ready.

- **Env validation:** Failing fast at startup with a clear error is better than failing on first DB or k8s call with a vague message.

- **Structured errors and logging:** Structured API errors and JSON logs make debugging and client handling predictable and scriptable.

---

## 3) Architectural Improvements (Summary)

- **Config module:** Centralized `loadConfig()` validates required env and optional TENANT_DOMAIN at startup.
- **Logger:** JSON structured logging (time, level, msg, meta) for production.
- **K8s client:** In-cluster detection via `KUBERNETES_SERVICE_HOST`; use in-cluster config when present, otherwise KUBECONFIG with clear error.
- **Provisioning:** Strict order (namespace → resourcequota → pvc → deployment → service → ingress) with a single try/catch and rollback that deletes in reverse order (ingress → service → deployment → pvc → resourcequota → namespace).
- **RBAC:** ClusterRole updated to include `delete` on namespaces and all tenant resources used in rollback.
- **Templates:** Tenant ingress host uses `PLACEHOLDER_TENANT_DOMAIN` replaced from `TENANT_DOMAIN` env so domain is configurable.
- **API:** Errors return `{ error: { message, code } }` with stable codes (e.g. INVALID_INPUT, TENANT_EXISTS, PROVISION_FAILED).
- **Install:** Cluster check first; k3s install only when k3s is missing (unless SKIP_K3S_INSTALL=1); apply order and wait for Traefik, Postgres, panel-backend, panel-frontend.

---

## 4) Instructions to Redeploy Cleanly

1. **Uninstall existing (if any)**  
   ```bash
   ./scripts/uninstall.sh
   ```
   Remove tenant namespaces if desired:
   ```bash
   kubectl get ns -l app.kubernetes.io/name=tenant
   kubectl delete ns cust-acme cust-foo   # example
   ```

2. **Set environment**  
   ```bash
   cp .env.example .env
   # Edit .env: set DATABASE_URL password, TENANT_DOMAIN if not example.local
   ```

3. **Install**  
   ```bash
   chmod +x scripts/install.sh
   ./scripts/install.sh
   ```

4. **Verify**  
   - `kubectl get pods -n ingress-system`
   - `kubectl get pods -n panel-system`
   - Add hosts: `127.0.0.1 panel.example.local api.example.local`
   - Open http://panel.example.local and create a tenant (e.g. `acme`)
   - Add `127.0.0.1 acme.example.local` and open http://acme.example.local

5. **Test rollback (optional)**  
   - Temporarily break a template (e.g. invalid YAML in tenant-ingress) and create a tenant; confirm API returns 500 and no namespace remains (or only a briefly created one that is deleted).
