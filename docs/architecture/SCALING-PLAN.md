# Scaling Plan: Single Node → Multi-Node

## Current State (Single Node)

- One control-plane + one worker (or single node running both).
- Longhorn: single replica per volume.
- Traefik: one replica; DaemonSet optional for multi-node.
- All system and tenant workloads on the same node.

## Phase 1: Add Worker Nodes (Still Single Control Plane)

1. **Join additional nodes** to the cluster (`kubeadm join` or managed Kubernetes).
2. **Longhorn**: Install on all nodes; set `numberOfReplicas: 2` (or 3) for new PVCs so volumes are replicated across nodes. Existing PVCs can be expanded/replicated via Longhorn UI or StorageClass update.
3. **Traefik**: Switch to DaemonSet so each node has an ingress pod; use HostPort 80/443 or keep LoadBalancer and let cloud LB distribute. Alternatively increase replicas and use anti-affinity to spread.
4. **System components**: Spread Deployments across nodes using PodAntiAffinity (e.g. prefer different nodes for postgres, powerdns, mail-mysql).
5. **Tenants**: New tenant Pods will be scheduled on any node; PVCs will follow Longhorn replication.

## Phase 2: High Availability (Optional)

- **Control plane**: Add 2 more control-plane nodes (3 total) for etcd quorum.
- **Core DNS**: Deploy CoreDNS with multiple replicas.
- **Ingress**: DaemonSet or 2+ replicas with anti-affinity.
- **PowerDNS**: 2 replicas + read replica for DB, or active/passive.
- **Mail**: Postfix/Dovecot can run 1 replica each with persistent storage on one node; for HA, use shared storage (NFS/RWX) for maildir and consider active/passive or queue-based delivery.
- **Panel API**: 2+ replicas; PostgreSQL with streaming replication or managed DB.
- **Velero**: Single replica is fine; ensure S3 backend is durable.

## Phase 3: Tenant Affinity (Optional)

- Use node affinity or topology spread to pin heavy tenants to specific nodes.
- Use ResourceQuota and LimitRange (already in place) to avoid noisy neighbours.

## Phase 4: Multi-Region / Federation (Future)

- Separate clusters per region; Panel API could manage multiple clusters via kubeconfigs.
- DNS and mail can stay central or be replicated per region.

## Checklist for Multi-Node

- [ ] Longhorn: add nodes, enable replication.
- [ ] StorageClass: update default replica count if desired.
- [ ] Traefik: DaemonSet or multiple replicas + LB.
- [ ] System namespaces: add PodAntiAffinity for critical StatefulSets/Deployments.
- [ ] Network: ensure CNI supports multi-node (Calico, Cilium, etc.).
- [ ] Backup: Velero and Restic work across nodes (PVCs are backed up by volume ID).
- [ ] Monitoring: Prometheus scrapes all nodes/pods; Grafana unchanged.
