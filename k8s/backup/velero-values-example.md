# Velero + Restic — S3-Compatible Backend

## Install (Helm)

```bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero -n backup-system -f velero-values.yaml
```

## velero-values.yaml (example)

```yaml
configuration:
  provider: aws
  backupStorageLocation:
    name: default
    bucket: your-velero-bucket
    config:
      region: us-east-1
      s3Url: https://s3.amazonaws.com  # or MinIO endpoint
      s3ForcePathStyle: "true"
      publicUrl: https://minio.example.com  # if MinIO
  volumeSnapshotLocation:
    name: default
    config:
      region: us-east-1

credentials:
  useSecret: true
  secretContents:
    cloud: |
      [default]
      aws_access_key_id=MINIO_ACCESS_KEY
      aws_secret_access_key=MINIO_SECRET_KEY

initContainers:
  - name: velero-plugin-for-aws
    image: velero/velero-plugin-for-aws:v1.11.0
    imagePullPolicy: IfNotPresent
    volumeMounts:
      - mountPath: /target
        name: plugins

# Restic for PVC backup
deployRestic: true
restic:
  podVolumePath: /var/lib/kubelet/pods
  privileged: true

# Schedule: backup tenant namespaces daily
schedules:
  daily-tenants:
    schedule: "0 2 * * *"
    template:
      includeNamespaceResources: true
      includedNamespaces: []
      labelSelector:
        matchLabels:
          tenant: "true"
      storageLocation: default
      volumeSnapshotLocations: []
      ttl: 720h
```

## Label-based backup selection

- Only namespaces with `tenant=true` are included when using `labelSelector.matchLabels.tenant: "true"`.
- To exclude core system: do not add `system: "true"` to the schedule's included namespaces; only tenant namespaces have `tenant=true`.
- Optional: second schedule with no label selector for full cluster backup.

## Restore per tenant

```bash
velero restore create --from-backup daily-tenants-20250220020000 --include-namespaces cust-1001
```
