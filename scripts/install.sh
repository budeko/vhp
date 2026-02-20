#!/usr/bin/env bash
# Idempotent install: safe to run multiple times. Applies manifests in correct order and waits for readiness.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

# Load env if present
if [ -f "$ROOT/.env" ]; then
  set -a
  source "$ROOT/.env"
  set +a
fi

echo "[1/7] Checking cluster access..."
if ! kubectl cluster-info &>/dev/null; then
  if [ -d /etc/rancher/k3s ]; then
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  fi
fi
if ! kubectl cluster-info &>/dev/null; then
  echo "kubectl cannot reach a cluster. Install k3s or set KUBECONFIG."
  exit 1
fi

echo "[2/7] k3s (optional)..."
if [ "${SKIP_K3S_INSTALL:-}" = "1" ]; then
  echo "Skipping k3s (SKIP_K3S_INSTALL=1)."
elif ! command -v k3s &>/dev/null; then
  echo "Installing k3s..."
  curl -sfL https://get.k3s.io | sh -
  export PATH="/usr/local/bin:$PATH"
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  echo "Waiting for k3s to be ready..."
  sleep 10
  kubectl wait --for=condition=Ready nodes --all --timeout=120s 2>/dev/null || true
else
  echo "k3s already present."
fi

echo "[3/7] Applying ingress (Traefik)..."
kubectl apply -f "$ROOT/k8s/ingress/namespace.yaml"
kubectl apply -f "$ROOT/k8s/ingress/traefik.yaml"
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: traefik
  annotations:
    ingressclass.kubernetes.io/is-default-class: "false"
spec:
  controller: traefik.io/ingress-controller
EOF
echo "Waiting for Traefik..."
kubectl wait --for=condition=available --timeout=120s deployment/traefik -n ingress-system || true

echo "[4/7] Applying panel-system..."
kubectl apply -f "$ROOT/k8s/panel/namespace.yaml"
kubectl apply -f "$ROOT/k8s/panel/panel-secrets.yaml"
kubectl apply -f "$ROOT/k8s/panel/panel-backend-rbac.yaml"
kubectl apply -f "$ROOT/k8s/panel/postgres.yaml"
echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=available --timeout=120s deployment/postgres -n panel-system || true

echo "[5/7] Building panel images..."
BACKEND_DIR="$ROOT/panel/backend"
FRONTEND_DIR="$ROOT/panel/frontend"
if command -v docker &>/dev/null; then
  docker build -t panel-backend:latest "$BACKEND_DIR"
  docker build -t panel-frontend:latest "$FRONTEND_DIR"
  if command -v k3s &>/dev/null; then
    docker save panel-backend:latest panel-frontend:latest | sudo k3s ctr images import - 2>/dev/null || true
  fi
elif command -v podman &>/dev/null; then
  podman build -t panel-backend:latest "$BACKEND_DIR"
  podman build -t panel-frontend:latest "$FRONTEND_DIR"
else
  echo "Docker/Podman not found; using existing images if present."
fi

kubectl apply -f "$ROOT/k8s/panel/panel-backend.yaml"
kubectl apply -f "$ROOT/k8s/panel/panel-frontend.yaml"
kubectl apply -f "$ROOT/k8s/panel/ingress.yaml"

echo "[6/7] Waiting for panel workloads..."
kubectl wait --for=condition=available --timeout=120s deployment/panel-backend -n panel-system || true
kubectl wait --for=condition=available --timeout=120s deployment/panel-frontend -n panel-system || true

echo "[7/7] Done."
echo ""
echo "Add to /etc/hosts:"
echo "  127.0.0.1 panel.example.local api.example.local"
echo ""
echo "Panel:  http://panel.example.local"
echo "API:    http://api.example.local"
echo "Create tenant: curl -X POST http://api.example.local/api/tenant -H 'Content-Type: application/json' -d '{\"id\":\"acme\"}'"
