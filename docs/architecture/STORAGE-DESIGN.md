# Storage Design (Longhorn + PVC)

## How PVC Lifecycle Works

1. **Creation**: Panel API (or user) creates a PVC in tenant namespace with `storageClassName: longhorn`. Longhorn provisioner creates a PV and binds it to the PVC. A Longhorn volume (replica(s)) is created on node(s).
2. **Use**: Pods in the same namespace mount the PVC; only that namespace’s pods can use it (unless shared via RBAC and explicit mount in another namespace, which we do not do). Data is isolated per PVC.
3. **Deletion**: When the namespace is deleted, PVCs in that namespace are deleted. With default `reclaimPolicy: Delete` on the StorageClass, the PV is deleted and Longhorn removes the volume and frees disk.

## When Namespace Is Deleted

- All PVCs in the namespace are removed.
- Longhorn deletes the backing volumes (reclaimPolicy: Delete).
- To **retain** data: either set `reclaimPolicy: Retain` on the StorageClass (then PVs remain after PVC delete and must be cleaned up manually) or use a separate StorageClass with Retain for critical tenants and manually reclaim after backup/export.

## Snapshots

- **Longhorn VolumeSnapshot**: Create a `VolumeSnapshot` (CSI) in the tenant namespace; Longhorn creates a snapshot of the volume. Restore by creating a new PVC from the snapshot (VolumeSnapshotContent → new PVC).
- **Velero + Restic**: Backs up volume data to S3; restore creates new PVC and restores data. No Longhorn-native snapshot required.
- **Recurring snapshots**: Longhorn RecurringJob CRD can schedule snapshots (e.g. daily) per volume or by label; useful for point-in-time recovery in addition to Velero.

## Summary

- Tenant data is isolated by PVC per namespace.
- Longhorn is the default StorageClass; dynamic provisioning.
- Namespace delete → PVC delete → volume delete (unless Retain).
- Snapshots: CSI VolumeSnapshot and/or Velero/Restic.
