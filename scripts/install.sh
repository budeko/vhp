#!/usr/bin/env bash
# VHP Platform - İnteraktif Helm kurulum script'i
# Kullanım: ./scripts/install.sh  veya  bash scripts/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHART_PATH="${REPO_ROOT}/helm/vhp"
RELEASE_NAME="${VHP_RELEASE_NAME:-vhp}"
NAMESPACE="${VHP_NAMESPACE:-default}"

# Renkli çıktı
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
nc='\033[0m'

info()  { echo -e "${green}[INFO]${nc} $*"; }
warn()  { echo -e "${yellow}[WARN]${nc} $*"; }
err()   { echo -e "${red}[ERR]${nc} $*"; exit 1; }

# Helm kontrolü
check_helm() {
  if ! command -v helm &>/dev/null; then
    err "Helm yüklü değil. https://helm.sh/docs/intro/install/ adresinden kurun."
  fi
  info "Helm: $(helm version --short)"
}

# Değer oku; varsayılan verilirse boş Enter ile geçilebilir
prompt() {
  local var="$1"
  local msg="$2"
  local default="${3:-}"
  if [[ -n "$default" ]]; then
    read -r -p "$msg [$default]: " input
    export "$var=${input:-$default}"
  else
    read -r -p "$msg: " input
    export "$var=$input"
  fi
}

# Evet/Hayır sorusu; default y
confirm() {
  local msg="$1"
  local default="${2:-y}"
  read -r -p "$msg (Y/n): " input
  case "${input:-$default}" in
    [yY]|[eE]|[vV]|"") return 0 ;;
    *) return 1 ;;
  esac
}

# Şifre sor (gizli); iki kez sor, eşleşene kadar tekrarla
prompt_password_twice() {
  local var="$1"
  local msg="$2"
  local pass1 pass2
  while true; do
    read -r -s -p "$msg: " pass1
    echo ""
    read -r -s -p "Şifreyi tekrar girin (teyit): " pass2
    echo ""
    if [[ "$pass1" != "$pass2" ]]; then
      warn "Şifreler eşleşmedi. Tekrar girin."
      continue
    fi
    if [[ -z "$pass1" ]]; then
      warn "Şifre boş olamaz."
      continue
    fi
    export "$var=$pass1"
    return 0
  done
}

# --- Ana kurulum ---
main() {
  echo ""
  echo "=============================================="
  echo "  VHP Platform - Helm Kurulum"
  echo "=============================================="
  echo ""
  echo "Kurulum sırasında: panel adresi, mail, admin kullanıcı adı ve şifresi istenecek."
  echo "Panel ve controller için bu repodaki resmi image'lar kullanılacak."
  echo ""

  check_helm

  if [[ ! -d "$CHART_PATH" ]]; then
    err "Chart bulunamadı: $CHART_PATH"
  fi

  # --- 1) Panel domain ---
  info "1/3 — Panel adresi ve mail"
  echo ""
  prompt PANEL_HOST "Panel domain (örn. panel.sirket.com)" "panel.vhp-platform.com"
  prompt ADMIN_EMAIL "Admin e-posta (bildirimler ve iletişim)" "admin@example.com"

  # --- 2) Admin kullanıcı ve şifre ---
  echo ""
  info "2/3 — Panel admin kullanıcısı (ilk giriş bu hesapla yapılacak)"
  echo ""
  prompt ADMIN_USERNAME "Admin kullanıcı adı" "admin"
  prompt_password_twice ADMIN_PASSWORD "Admin şifre"

  # Panel ve controller: sadece bu repodaki resmi image'lar
  IMAGE_REGISTRY="ghcr.io"
  PANEL_IMAGE_PATH="vhp-platform/vhp-panel:latest"
  CONTROLLER_IMAGE_PATH="vhp-platform/vhp-controller:latest"

  # --- 3) Opsiyonel zonlar ---
  echo ""
  info "3/3 — Hangi servisleri kullanacaksınız? (Opsiyonel — sadece ihtiyacınız olanları seçin)"
  echo ""

  BACKUP_ENABLED="false"
  if confirm "Backup (MinIO) zonu kurulsun mu?"; then
    BACKUP_ENABLED="true"
    prompt MINIO_USER "MinIO root kullanıcı" "admin"
    prompt MINIO_PASSWORD "MinIO root şifre" ""
    prompt MINIO_STORAGE "MinIO PVC boyutu" "50Gi"
  fi

  DATA_ENABLED="false"
  if confirm "Data (PostgreSQL) zonu kurulsun mu?"; then
    DATA_ENABLED="true"
    prompt DB_PASSWORD "PostgreSQL şifre (vhp kullanıcısı)" ""
    prompt DB_STORAGE "DB PVC boyutu" "10Gi"
  fi

  DNS_ENABLED="false"
  if confirm "DNS zonu kurulsun mu?"; then
    DNS_ENABLED="true"
  fi

  GITOPS_ENABLED="false"
  if confirm "GitOps (Flux) zonu kurulsun mu?"; then
    GITOPS_ENABLED="true"
    prompt FLUX_REPO "Flux Git repo URL" "https://github.com/your-org/vhp"
    prompt FLUX_BRANCH "Flux branch" "main"
  fi

  OBSERVABILITY_ENABLED="false"
  if confirm "Observability (Prometheus/Loki/Grafana) zonu kurulsun mu?"; then
    OBSERVABILITY_ENABLED="true"
  fi

  # --- values dosyası ve şifre dosyası oluştur ---
  VALUES_FILE="${REPO_ROOT}/.vhp-install-values.yaml"
  PASSWORD_FILE="${REPO_ROOT}/.vhp-admin-password"
  printf '%s' "$ADMIN_PASSWORD" > "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
  trap "rm -f '$VALUES_FILE' '$PASSWORD_FILE'" EXIT

  cat > "$VALUES_FILE" << EOF
# VHP - Installer tarafından oluşturuldu
# Kurulum sonrası bu dosyayı silebilirsiniz (şifre --set ile verildiği için dosyada yok).

global:
  panelHost: "$PANEL_HOST"
  letsEncryptEmail: "$ADMIN_EMAIL"
  adminUsername: "$ADMIN_USERNAME"
  imageRegistry: "$IMAGE_REGISTRY"
  panelImage: "$PANEL_IMAGE_PATH"
  controllerImage: "$CONTROLLER_IMAGE_PATH"

core:
  enabled: true
  ingress:
    replicas: 2
    image: "registry.k8s.io/ingress-nginx/controller:v1.11.0"

cert:
  enabled: true

control:
  enabled: true

panel:
  enabled: true

policy:
  enabled: true

backup:
  enabled: $BACKUP_ENABLED
  minio:
    storage: ${MINIO_STORAGE:-50Gi}
    rootUser: "${MINIO_USER:-admin}"
    rootPassword: "${MINIO_PASSWORD:-}"

data:
  enabled: $DATA_ENABLED
  db:
    storage: ${DB_STORAGE:-10Gi}
    password: "${DB_PASSWORD:-}"

dns:
  enabled: $DNS_ENABLED

gitops:
  enabled: $GITOPS_ENABLED
  flux:
    repoUrl: "${FLUX_REPO:-https://github.com/your-org/vhp}"
    branch: "${FLUX_BRANCH:-main}"

observability:
  enabled: $OBSERVABILITY_ENABLED
  prometheus: true
  loki: true
  grafana: true
EOF

  info "Oluşturulan values: $VALUES_FILE"
  echo ""

  # --- Helm install (şifre dosyada yok, --set ile veriliyor) ---
  info "Kurulum başlıyor: release=$RELEASE_NAME, chart=$CHART_PATH"
  echo ""

  if helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    -f "$VALUES_FILE" \
    --set-file "global.adminPassword=$PASSWORD_FILE" \
    --wait \
    --timeout 10m; then
    info "Kurulum tamamlandı."
    echo ""
    helm status "$RELEASE_NAME" -n "$NAMESPACE" || true
  else
    err "Helm install başarısız."
  fi
}

main "$@"
