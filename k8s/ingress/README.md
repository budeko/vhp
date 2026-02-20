# Ingress (Traefik)

- Traefik runs in `ingress-system` and watches Ingress resources in all namespaces (RBAC allows).
- Routes are based on **host** (and path). Each tenant Ingress sets `host: <domain>` and backend to the tenant’s Service.
- TLS: Traefik ACME (Let’s Encrypt) issues certs per host; store in Traefik’s persistent volume (`acme.json`). Ensure `acme.json` is backed up and not shared; consider file permissions (0600).
- Global config: entrypoints (80 → redirect to 443), certificates resolver, and optional middlewares are in Traefik static config or CRDs (IngressRoute, Middleware).
