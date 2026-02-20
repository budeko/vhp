# Panel Frontend (Next.js)

Placeholder for the Panel web UI (Next.js).

## Responsibilities

- Customer/login UI; list domains, add domain, view DNS/mail settings.
- Call Panel Backend API for provisioning and domain management.
- Optional: billing, support tickets, documentation.

## Suggested stack

- Next.js 14+ (App Router or Pages); Tailwind CSS; auth (e.g. NextAuth, OIDC).
- API base URL from env: `NEXT_PUBLIC_API_URL` (e.g. `https://api.platform.example.com`).

## Deployment

- Image built from this directory; deployed as `panel-frontend` in `panel-system` namespace (see `k8s/system/panel-system/panel-frontend-deployment.yaml`).
