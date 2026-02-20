# Backup Design (Velero + Restic)

## Behaviour

- **Velero** runs in `backup-system`; uses an S3-compatible backend (e.g. MinIO, AWS S3) for backup metadata and optional volume snapshots.
- **Restic** (deployed with Velero when `deployRestic: true`) backs up PVC data by reading volume contents from the node and uploading to the same or dedicated S3 bucket. No CSI snapshot required.

## Label-Based Backup Selection

- **Include**: Use a Velero Schedule (or ad-hoc backup) with `labelSelector.matchLabels.tenant: "true"`. Only namespaces with that label are backed up. All tenant namespaces created by the Panel have `tenant=true` and `backup=true`.
- **Exclude shared core**: Do **not** add system namespaces (ingress-system, dns-system, mail-system, etc.) to the schedule’s included namespaces if you want tenant-only backups. Using only `labelSelector: tenant=true` achieves this.
- **Optional full backup**: A second schedule with no label selector (or a different selector) can back up all namespaces including system; store in a different prefix or bucket if desired.

## Backup Scope

- **Namespaces**: All objects in selected namespaces (Deployments, Services, Ingress, PVCs, Secrets, ConfigMaps, etc.).
- **PVCs**: Restic backs up volume data for PVCs in those namespaces; restore recreates PVC and restores data.

## Restore per Tenant

- **Restore one tenant**:  
  `velero restore create --from-backup <backup-name> --include-namespaces cust-1001`
- **Restore multiple tenants**:  
  `velero restore create --from-backup <backup-name> --include-namespaces cust-1001,cust-1002`
- **Restore to a new name**: Use Velero restore mapping (e.g. rename namespace) if required; see Velero docs.

## What Is Not Backed Up (Default)

- Cluster-scoped resources (unless explicitly included in Velero config).
- System namespaces, if excluded by label selector.
- In-cluster DB data (PowerDNS, Mail MySQL, Panel PostgreSQL) unless their namespaces are included in a separate schedule. For production, include them in a “system” schedule or use managed DB backups.

## Summary

- Velero selects namespaces via label `tenant=true`.
- PVCs are backed up via Restic.
- Restore per tenant with `--include-namespaces cust-<id>`.
- Optional toggle: tenant-only vs full cluster by using one or two schedules.
