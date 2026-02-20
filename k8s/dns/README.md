# DNS (PowerDNS) Configuration

## Schema initialization

Create the PowerDNS schema ConfigMap and run the init job once:

```bash
kubectl create configmap powerdns-schema -n dns-system \
  --from-file=schema.pgsql.sql="$(pwd)/k8s/dns/powerdns-schema.pgsql.sql"
kubectl apply -f k8s/system/dns-system/powerdns-schema-job.yaml
```

## PowerDNS API usage (Panel)

- **Base URL**: `http://powerdns.dns-system.svc.cluster.local:8081`
- **Header**: `X-API-Key: <api-key>` (from Secret `powerdns-api`, key `api-key`)
- **Create zone**: `POST /api/v1/servers/localhost/zones` with JSON body (name, kind: Native, nameservers, etc.)
- **Add records**: `PATCH /api/v1/servers/localhost/zones/<zone>` with rrsets (A, AAAA, MX, TXT for SPF/DKIM/DMARC)

See PowerDNS HTTP API documentation for full spec.
