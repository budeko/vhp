# VHP Helm Chart — Dosya ve Bileşen Rehberi

Bu belge, chart içindeki her şablon dosyasının ne işe yaradığını ve nasıl gruplandığını açıklar.

---

## Katmanlar (Layers)

| Katman | Açıklama | Namespace(ler) |
|--------|----------|----------------|
| **Sistem (system)** | Çekirdek altyapı: ingress, sertifika, güvenlik politikaları | vhp-core, vhp-cert, vhp-policy |
| **Yönetim (management)** | Platform yönetimi: controller, panel arayüzü | vhp-control, vhp-panel |
| **Zonlar (zones)** | Opsiyonel servisler: yedekleme, veri, DNS, GitOps, izleme, build (Kaniko), cron | vhp-backup, vhp-data, vhp-dns, vhp-gitops, vhp-observability, vhp-build, vhp-cron |

---

## Şablon Dosyaları (templates/)

### Sistem servisleri (her zaman açık)

| Dosya | Ne işe yarar | İçerdiği kaynaklar |
|-------|----------------|---------------------|
| **system-core.yaml** | Çekirdek altyapı. Trafiği cluster’a alır, gateways yapılandırır. İsteğe bağlı **mail-sender** Deployment. | Namespace `vhp-core`, PriorityClass, ResourceQuota, LimitRange, NetworkPolicy, **IngressClass** `vhp-traefik`, Traefik (ClusterIP), Nginx edge (LoadBalancer), **DNS gateway** ConfigMap, **Mail gateway** ConfigMap, **platform-config** ConfigMap, opsiyonel mail-sender Deployment/Service (`core.mail.deploySender`). |
| **system-cert.yaml** | TLS sertifikaları. Let’s Encrypt ile otomatik sertifika. | Namespace `vhp-cert`, ClusterIssuer (staging + prod), ResourceQuota, LimitRange, NetworkPolicy. |
| **system-policy.yaml** | Güvenlik kuralları. Kullanıcı namespace’lerinde izin/kısıt. | Namespace `vhp-policy`, Kyverno ConfigMap, ClusterPolicy (ingress class zorunlu, LoadBalancer/NodePort yasak), ResourceQuota, LimitRange, NetworkPolicy. |

### Yönetim servisleri (controller + panel)

| Dosya | Ne işe yarar | İçerdiği kaynaklar |
|-------|----------------|---------------------|
| **management-control.yaml** | VHP Controller. Kullanıcı namespace’leri ve zonları yönetir. | Namespace `vhp-control`, ServiceAccount, Role/RoleBinding, ClusterRole/ClusterRoleBinding, Controller Deployment/Service/PDB, ResourceQuota, LimitRange, NetworkPolicy. |
| **management-panel.yaml** | Yönetim paneli. Web arayüzü ve TLS. | Namespace `vhp-panel`, Certificate (panel TLS), Panel Deployment/Service/Ingress, ResourceQuota, LimitRange, NetworkPolicy. |

### Opsiyonel zonlar (kurulumda seçilir)

| Dosya | Ne işe yarar | values anahtarı | İçerdiği kaynaklar |
|-------|----------------|------------------|---------------------|
| **zone-backup.yaml** | Yedekleme alanı (S3 uyumlu). | `backup.enabled` | Namespace `vhp-backup`, MinIO Secret/PVC/Deployment/Service/PDB, ResourceQuota, LimitRange, NetworkPolicy. |
| **zone-data.yaml** | Merkezi veritabanı. | `data.enabled` | Namespace `vhp-data`, PostgreSQL Secret/Service/StatefulSet, ResourceQuota, LimitRange, NetworkPolicy. |
| **zone-dns.yaml** | DNS yönetimi. | `dns.enabled` | Namespace `vhp-dns`, DNS manager ServiceAccount/Deployment/Service, ResourceQuota, LimitRange, NetworkPolicy. |
| **zone-gitops.yaml** | GitOps (Flux). Repo’dan sürekli senkron. | `gitops.enabled` | Namespace `vhp-gitops`, flux-system namespace, GitRepository, Kustomization, ResourceQuota, LimitRange, NetworkPolicy. |
| **zone-observability.yaml** | İzleme (metrik/log). | `observability.enabled` | Namespace `vhp-observability`, Prometheus/Loki/Grafana ConfigMap ve Service, ResourceQuota, LimitRange, NetworkPolicy. |
| **zone-build.yaml** | Image build (Kaniko). Flux ile tetiklenebilir. | `build.enabled` | Namespace `vhp-build`, ServiceAccount, Kaniko registry Secret, **CronJob** (Kaniko build), ResourceQuota, LimitRange. |
| **zone-cron.yaml** | Zamanlanmış görevler. | `cron.enabled` | Namespace `vhp-cron`, **CronJob** backup-cleanup (MinIO, `backup.enabled` gerekir), **CronJob** cert-expiry-check, **CronJob** cleanup-failed-jobs (vhp-build job temizlik, `build.enabled` gerekir), ServiceAccount/RBAC, ResourceQuota, LimitRange. |

### Kullanıcı şablonları (controller tarafından kullanılır)

| Dosya | Ne işe yarar | İçerdiği kaynaklar |
|-------|----------------|---------------------|
| **templates-user-namespaces.yaml** | Kullanıcı namespace’i şablonları. Controller bunları okuyup `user-<ad>` namespace’leri oluştururken kullanır. | ConfigMap’ler (vhp-control): `vhp-user-namespace-template`, `vhp-user-rbac-template`, `vhp-user-policies-template` (namespace, RBAC, quota/limit/networkpolicy ve notes şablonları). |

### Diğer

| Dosya | Ne işe yarar |
|-------|----------------|
| **_helpers.tpl** | Helm yardımcı tanımları (namespace adları, label’lar). |
| **NOTES.txt** | Kurulum sonrası kubectl/helm çıktısında gösterilen notlar. |

---

## Adlandırma kuralları

- **Namespace:** `vhp-<bileşen>` (örn. vhp-core, vhp-panel).
- **Label’lar:** `vhp-layer` (infrastructure / management), `vhp-type` (static-core, controller, panel, storage, …).
- **Ingress class:** Tüm ingress’ler `vhp-traefik` kullanır (policy ile zorunlu). Dışarıya sadece Nginx (80/443) açılır; içeride Traefik ingress yapar.

---

## values.yaml yapısı (kısa)

- **global:** panelHost, letsEncryptEmail, panelImage, controllerImage.
- **core:** enabled, ingress (replicas, edgeImage), traefik (replicas, image), mail (smtp, webhook).
- **cert, control, panel, policy:** enabled.
- **backup, data, dns, gitops, observability:** enabled + zona özel ayarlar (minio, db, flux, prometheus/loki/grafana).
- **build:** enabled + kaniko (schedule, context, dockerfilePath, imageDestination). Kaniko registry secret kurulumda oluşturulur.
- **cron:** enabled + backupCleanup, certCheck, backupSchedule, certCheckSchedule, cleanupSchedule.
- **core.mail:** deploySender, senderImage (opsiyonel mail relay Deployment).

Detay için `values.yaml` ve `helm/README.md` dosyalarına bakın.
