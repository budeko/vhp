#!/usr/bin/env bash
# Panel ve Controller image'larını lokal Docker ile build edip registry'e push eder.
# Kullanım:
#   export VHP_REGISTRY=ghcr.io/your-org
#   export VHP_PANEL_DIR=../vhp-panel    # panel kaynak kodu (Dockerfile bu dizinde)
#   export VHP_CONTROLLER_DIR=../vhp-controller
#   ./scripts/build-images.sh
# Çıktıda görünen image URL'lerini kurulumda (install.sh) kullanın.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Varsayılanlar: bu repo içindeki panel/ ve controller/ dizinleri
REGISTRY="${VHP_REGISTRY:-ghcr.io/vhp-platform}"
PANEL_DIR="${VHP_PANEL_DIR:-${REPO_ROOT}/panel}"
CONTROLLER_DIR="${VHP_CONTROLLER_DIR:-${REPO_ROOT}/controller}"
TAG="${VHP_IMAGE_TAG:-latest}"

green='\033[0;32m'
red='\033[0;31m'
yellow='\033[1;33m'
nc='\033[0m'
info() { echo -e "${green}[INFO]${nc} $*"; }
warn() { echo -e "${yellow}[WARN]${nc} $*"; }
err()  { echo -e "${red}[ERR]${nc} $*"; exit 1; }

if ! command -v docker &>/dev/null; then
  err "Docker yüklü değil. Image'ları lokal build etmek için Docker gerekir."
fi

info "Registry: $REGISTRY"
info "Tag: $TAG"
info "Panel kaynak: $PANEL_DIR"
info "Controller kaynak: $CONTROLLER_DIR"
echo ""

# Panel
if [[ -d "$PANEL_DIR" ]] && [[ -f "$PANEL_DIR/Dockerfile" ]]; then
  info "Panel image build ediliyor..."
  docker build -t "${REGISTRY}/vhp-panel:${TAG}" "$PANEL_DIR"
  info "Panel image push ediliyor..."
  docker push "${REGISTRY}/vhp-panel:${TAG}"
  PANEL_IMAGE="${REGISTRY}/vhp-panel:${TAG}"
else
  warn "Panel dizini veya Dockerfile yok: $PANEL_DIR — panel build atlanıyor."
  PANEL_IMAGE="${REGISTRY}/vhp-panel:${TAG}"
fi

# Controller
if [[ -d "$CONTROLLER_DIR" ]] && [[ -f "$CONTROLLER_DIR/Dockerfile" ]]; then
  info "Controller image build ediliyor..."
  docker build -t "${REGISTRY}/vhp-controller:${TAG}" "$CONTROLLER_DIR"
  info "Controller image push ediliyor..."
  docker push "${REGISTRY}/vhp-controller:${TAG}"
  CONTROLLER_IMAGE="${REGISTRY}/vhp-controller:${TAG}"
else
  warn "Controller dizini veya Dockerfile yok: $CONTROLLER_DIR — controller build atlanıyor."
  CONTROLLER_IMAGE="${REGISTRY}/vhp-controller:${TAG}"
fi

echo ""
info "Kurulumda kullanacağınız image'lar:"
echo "  Panel:      $PANEL_IMAGE"
echo "  Controller: $CONTROLLER_IMAGE"
echo ""
echo "Örnek: ./scripts/install.sh çalıştırırken bu URL'leri girin."
echo "  veya: export VHP_PANEL_IMAGE=$PANEL_IMAGE VHP_CONTROLLER_IMAGE=$CONTROLLER_IMAGE"
