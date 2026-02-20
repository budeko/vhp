# Install Instructions — SaaS Core Panel (Phase 1)

## Prerequisites

- Linux (or macOS) with Docker or Podman for building images
- kubectl
- k3s (install script can install it) or any Kubernetes cluster

**Note for k3s:** If you install k3s yourself and want to use only this project’s Traefik, disable the built-in one:  
`curl -sfL https://get.k3s.io | sh -s - --disable traefik`

## Step-by-step

### 1. Clone / enter project

```bash
cd /path/to/deko
```

### 2. Environment

```bash
cp .env.example .env
# Edit .env: set DATABASE_URL password and any overrides
```

### 3. Install

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

This will:

- Install k3s if not present (unless `SKIP_K3S_INSTALL=1`)
- Apply `ingress-system` (Traefik)
- Apply `panel-system` (PostgreSQL, backend, frontend)
- Build and deploy panel backend and frontend images
- Run DB migrations on first backend startup

### 4. Hosts and access

Add to `/etc/hosts`:

```
127.0.0.1 panel.example.local api.example.local
```

Get Traefik LoadBalancer IP (for direct access if needed):

```bash
kubectl get svc -n ingress-system traefik
```

Use that IP in hosts if you prefer, e.g.:

```
<LOADBALANCER_IP> panel.example.local api.example.local
```

- Panel UI: http://panel.example.local  
- API: http://api.example.local  

### 5. Create a tenant

**From UI:** Open http://panel.example.local, enter a tenant ID (e.g. `acme`) and click “Create tenant”.

**From CLI:**

```bash
curl -X POST http://api.example.local/api/tenant \
  -H "Content-Type: application/json" \
  -d '{"id": "acme"}'
```

Then add to `/etc/hosts`:

```
127.0.0.1 acme.example.local
```

Tenant site: http://acme.example.local (nginx default page).

### 6. List tenants

```bash
curl http://api.example.local/api/tenants
```

---

## Uninstall

```bash
./scripts/uninstall.sh
```

This removes `panel-system` and `ingress-system`. Tenant namespaces (`cust-*`) are listed but not deleted; remove them manually if needed.

---

## Troubleshooting

- **Backend can’t reach PostgreSQL:** Ensure `panel-db-secret` and `panel-backend-env` use the same password and that Postgres is running in `panel-system`.
- **Traefik not routing:** Ensure IngressClass `traefik` exists and that Ingress resources use `ingressClassName: traefik`.
- **Images not found:** Build with Docker/Podman and, on k3s, import into the k3s image store (install script attempts this).
