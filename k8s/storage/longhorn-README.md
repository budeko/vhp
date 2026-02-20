# Longhorn — Default StorageClass

## Install

```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.0/deploy/longhorn.yaml
# Or Helm: helm repo add longhorn https://charts.longhorn.io && helm install longhorn longhorn/longhorn -n longhorn-system --create-namespace
```

After install, set as default:

```bash
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## PVC lifecycle (tenant)

1. **Create**: Panel creates PVC in `cust-{id}` with `storageClassName: longhorn`. Longhorn provisions a volume (single replica on single node).
2. **Use**: Pod mounts PVC; data is isolated per PVC (and thus per tenant).
3. **Delete namespace**: When `cust-*` namespace is deleted, PVCs are deleted. Longhorn removes the volume and frees disk (reclaimPolicy: Delete).
4. **Retain**: To keep data after namespace delete, set `reclaimPolicy: Retain` on the StorageClass or on each PV; then PV remains and can be bound to a new PVC or backed up before delete.

## Snapshots

- Longhorn supports Volume Snapshots (CSI). Create `VolumeSnapshot` in tenant namespace; Longhorn creates a snapshot.
- Velero + Restic can also snapshot PVCs during backup (restic backup of volume data).
- Recurring snapshots: Longhorn RecurringJob CRD can schedule snapshots per volume or by label.

## Multi-node later

- Add nodes; Longhorn will replicate volumes across nodes when replica count > 1.
- Set default number of replicas in Longhorn Manager UI or StorageClass parameters.
