# Resource Management (Per Tenant)

## Limits

- **CPU limit**: per container and aggregate per namespace (ResourceQuota).
- **Memory limit**: per container and aggregate per namespace.
- **PVC size limit**: via ResourceQuota `requests.storage` and optional LimitRange for PVC (max storage per claim).

## Example ResourceQuota YAML

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: cust-1001
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
    requests.storage: 50Gi
    count/deployments.apps: "5"
    count/services: "5"
    count/ingresses.networking.k8s.io: "5"
```

## LimitRange (Default and Max per Container)

See `k8s/tenants/templates/limit-range.yaml`: default request/limit and max CPU/memory per container, plus max/min storage per PVC.

## Plans

- **Small**: 0.5 CPU / 512Mi memory namespace quota; 2 PVCs, 10Gi storage.
- **Medium**: 2 CPU / 4Gi (as in example above); 5 PVCs, 50Gi.
- **Large**: 4 CPU / 8Gi; 10 PVCs, 100Gi.

Panel API can select a ResourceQuota template by plan name when creating the namespace.
