# VHP Helm Chart

VHP platform altyapısını Kubernetes’e Helm ile kurar.

## Gereksinimler

- Kubernetes cluster (kubectl erişimi)
- [Helm 3](https://helm.sh/docs/intro/install/)
- (Opsiyonel) cert-manager, Kyverno — cluster’da ayrıca kurulabilir

## Hızlı kurulum (installer ile)

Installer, kurulum sırasında gerekli değerleri prompt ile sorar ve Helm’i çalıştırır:

```bash
# Repo kökünden
./scripts/install.sh
```

Ortam değişkenleri (isteğe bağlı):

- `VHP_RELEASE_NAME` — Helm release adı (varsayılan: `vhp`)
- `VHP_NAMESPACE` — Release’in yükleneceği namespace (varsayılan: `default`)

## Manuel kurulum

1. `values.yaml` içindeki placeholder’ları düzenleyin (özellikle `global.panelHost`, `global.letsEncryptEmail`, image’lar).
2. Opsiyonel zonları açın: `backup.enabled`, `data.enabled`, `dns.enabled`, `gitops.enabled`, `observability.enabled`.
3. Kurun:

```bash
helm upgrade --install vhp ./helm/vhp -f ./helm/vhp/values.yaml --create-namespace --namespace vhp
```

## Zonlar

| Zon        | values anahtarı | Varsayılan | Açıklama                    |
|-----------|------------------|------------|-----------------------------|
| Core      | `core.enabled`   | true       | Ingress, gateways, policies |
| Cert      | `cert.enabled`   | true       | Let’s Encrypt issuers, Certificate |
| Control   | `control.enabled`| true       | VHP controller              |
| Panel     | `panel.enabled`  | true       | Yönetim paneli              |
| Policy    | `policy.enabled` | true       | Kyverno policy’leri          |
| Backup    | `backup.enabled` | false      | MinIO                        |
| Data      | `data.enabled`   | false      | PostgreSQL                  |
| DNS       | `dns.enabled`    | false      | DNS manager                 |
| GitOps    | `gitops.enabled` | false      | Flux GitRepository/Kustomization |
| Observability | `observability.enabled` | false | Prometheus/Loki/Grafana config |
| Build (Kaniko) | `build.enabled` | false | Cluster içi image build, CronJob |
| Cron | `cron.enabled` | false | Backup cleanup, cert check, job temizlik CronJob'ları |

## Güncelleme

```bash
helm upgrade vhp ./helm/vhp -f ./helm/vhp/values.yaml -n vhp
```

## Kaldırma

```bash
helm uninstall vhp -n vhp
# Oluşan namespace’ler (vhp-core, vhp-panel, vb.) otomatik silinmez; gerekirse elle silin.
```
