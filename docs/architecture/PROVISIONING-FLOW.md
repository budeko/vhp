# Provisioning Flow — New Domain / Tenant

When a new domain (and optionally new customer) is added, the Panel API performs the following steps. This is pseudo-code for the provisioning flow.

## Inputs

- `customerId` (string, e.g. "1001")
- `domain` (string, e.g. "example.com")
- Optional: `createNamespace` (bool), `plan` (resource limits), `mailUsers` (list)

## Pseudo-Code

```text
FUNCTION provisionDomain(customerId, domain, options):
  ns := "cust-" + customerId

  // 1) Create namespace (if not exists)
  IF NOT namespaceExists(ns):
    CREATE Namespace
      metadata.name = ns
      metadata.labels = { tenant: "true", customer-id: customerId, backup: "true" }

  // 2) Apply ResourceQuota (from plan or default)
  APPLY ResourceQuota in ns
    hard.requests.cpu, limits.cpu, requests.memory, limits.memory
    hard.persistentvolumeclaims, requests.storage
    (from options.plan or default tenant-quota template)

  // 3) Apply LimitRange
  APPLY LimitRange in ns (tenant-limits template)

  // 4) Create PVCs
  CREATE PVC "web-data" in ns
    storageClassName: longhorn
    size from options.plan or default (e.g. 5Gi)
  IF options.includeDatabase:
    CREATE PVC "db-data" in ns

  // 5) Deploy web app
  CREATE Deployment "web" in ns
    image from options.image or default (e.g. nginx:alpine)
    volumeMount: web-data -> /usr/share/nginx/html (or app docroot)
    resources from LimitRange defaults or plan
  CREATE Service "web" (ClusterIP) in ns
    selector: app=web, port 80

  // 6) Create Ingress
  CREATE Ingress in ns
    host: domain
    backend: service web:80
    TLS: let Traefik ACME handle (or secretName tls-{customerId})
    annotations: ingress.class=traefik

  // 7) Add DNS zone via PowerDNS API
  zoneName := domain + "."
  POST PowerDNS API: POST /api/v1/servers/localhost/zones
    Body: {
      name: zoneName,
      kind: "Native",
      nameservers: ["ns1.platform.example.com.", "ns2.platform.example.com."]
    }
  // Add A/AAAA for domain -> Traefik LB or external IP
  PATCH PowerDNS API: PATCH /api/v1/servers/localhost/zones/{zoneName}
    Body: { rrsets: [
      { name: domain+".", type: "A", ttl: 300, records: [{ content: "<ingress-ip>", disabled: false }] },
      { name: "www."+domain+".", type: "CNAME", ttl: 300, records: [{ content: domain+".", disabled: false }] }
    ]}

  // 8) Insert domain into mail-system database
  INSERT INTO mail.virtual_domains (name, customer_id) VALUES (domain, customerId)
  domainId := LAST_INSERT_ID()
  IF options.mailUsers:
    FOR each user in options.mailUsers:
      maildir := "vhosts/" + domain + "/" + user.localPart + "/"
      INSERT INTO mail.virtual_users (domain_id, email, password, maildir) VALUES (domainId, user.email, hash(user.password), maildir)
  IF options.aliases:
    FOR each alias in options.aliases:
      INSERT INTO mail.virtual_aliases (domain_id, source, destination) VALUES (domainId, alias.source, alias.destination)

  // 9) Generate DKIM key and store as Kubernetes Secret
  selector := "default"  // or "selector1"
  (privateKey, publicKey) := generateDKIMKey()   // e.g. openssl genrsa 2048; export public for DNS
  CREATE Secret in namespace mail-system
    metadata.name = "dkim-" + sanitize(domain)   // e.g. dkim-example-com
    data["selector.txt"] = selector
    data["private.key"] = privateKey
  // Add DKIM TXT record to PowerDNS for domain
  dkimTxt := "v=DKIM1; k=rsa; p=" + base64(publicKey)
  PATCH PowerDNS API: add TXT record for selector._domainkey.{domain} -> dkimTxt
  INSERT INTO mail.dkim_selectors (domain_id, selector, secret_name) VALUES (domainId, selector, "dkim-"+sanitize(domain))

  // 10) SPF & DMARC records (auto-generated)
  PATCH PowerDNS API: add TXT for domain -> "v=spf1 mx a include:_spf.platform.example.com -all"
  PATCH PowerDNS API: add TXT for _dmarc.{domain} -> "v=DMARC1; p=quarantine; rua=mailto:dmarc@platform.example.com"

  // 11) Label namespace for backup (already set in step 1: backup="true")
  PATCH Namespace ns: ensure labels backup="true", tenant="true"

  // 12) Optional: register in Panel DB for billing/UI
  INSERT INTO panel.domains (customer_id, domain, namespace, created_at) VALUES (customerId, domain, ns, NOW())

  RETURN { namespace: ns, domain: domain, zone: zoneName }
```

## Idempotency

- Check if namespace exists before creating.
- For PowerDNS, check if zone exists (GET zone) before POST; if exists, only update records.
- For mail DB, use INSERT IGNORE or ON CONFLICT to avoid duplicate domain/user.

## Error Handling

- On failure at any step: either rollback (delete namespace, remove zone, remove DB rows) or mark provisioning as "failed" and retry later.
- Store provisioning state in Panel DB (e.g. status: pending | dns_created | namespace_created | completed | failed).

## Automation

- Panel API exposes REST: `POST /api/v1/domains` with body `{ customerId, domain, plan?, mailUsers?, image? }`.
- Optionally trigger from Panel Frontend (Next.js) or from a queue (e.g. Redis + worker) for async provisioning.
