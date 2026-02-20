# Resource Estimation (16 GB RAM Example)

Single-node cluster with 16 GB RAM. All numbers are approximate and conservative.

## System Components (Reserved)

| Component            | CPU Request | CPU Limit | Memory Request | Memory Limit | Notes        |
|---------------------|-------------|-----------|----------------|--------------|--------------|
| Traefik             | 50m         | 500m      | 64Mi           | 256Mi        |              |
| PowerDNS            | 50m         | 500m      | 128Mi          | 512Mi        |              |
| PowerDNS DB (Pg)    | 50m         | 500m      | 128Mi          | 512Mi        |              |
| Mail MySQL          | 100m        | 1000m     | 256Mi          | 2Gi          |              |
| Postfix             | 50m         | 500m      | 64Mi           | 512Mi        |              |
| Dovecot             | 50m         | 500m      | 64Mi           | 256Mi        |              |
| Rspamd              | 50m         | 500m      | 128Mi          | 512Mi        |              |
| Velero              | 100m        | 500m      | 128Mi          | 256Mi        |              |
| Longhorn manager    | 100m        | 500m      | 256Mi          | 512Mi        |              |
| Longhorn engine     | 100m        | 500m      | 128Mi          | 256Mi        | per volume   |
| Prometheus          | 100m        | 500m      | 256Mi          | 1Gi          |              |
| Grafana             | 50m         | 500m      | 128Mi          | 512Mi        |              |
| Node exporter       | 10m         | 200m      | 32Mi           | 128Mi        | per node     |
| Panel API           | 100m        | 500m      | 128Mi          | 512Mi        |              |
| Panel Frontend      | 50m         | 300m      | 128Mi          | 512Mi        |              |
| Panel PostgreSQL    | 100m        | 500m      | 256Mi          | 1Gi          |              |
| **Total (approx)**  | **~1.1**    | **~7**    | **~2.5 Gi**    | **~9 Gi**    |              |

## Kubernetes System (kubelet, kube-apiserver, etc.)

- Reserve ~2–3 GB for OS + kubelet + control plane (if colocated).
- On 16 GB node: **available for workloads ≈ 16 - 3 - 2.5 ≈ 10.5 GB** (request space) and less headroom for limits.

## Tenants

- Per tenant (default LimitRange): max 2 CPU, 2 Gi memory per container; default request 100m CPU, 128Mi memory.
- Example: **20 tenants** with 1 web pod each at 100m/128Mi request → **2 CPU, 2.56 Gi** requested.
- Total cluster request: system ~2.5 Gi + 2.56 Gi ≈ **5 Gi**; remaining for burst and more tenants.
- **Practical capacity (16 GB node)**: ~15–30 light tenants (1 small web app each), or fewer if tenants use DB + larger limits.

## Recommendations

- Set **kube-reserved** and **system-reserved** on the node so system + K8s have guaranteed memory.
- Use **ResourceQuota** per tenant (as in templates) to cap total tenant usage.
- For production, **32 GB+** single node or **multi-node** early to allow more tenants and HA.
