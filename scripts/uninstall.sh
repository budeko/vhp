#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Removing panel-system..."
kubectl delete -f "$ROOT/k8s/panel/ingress.yaml" --ignore-not-found
kubectl delete -f "$ROOT/k8s/panel/panel-frontend.yaml" --ignore-not-found
kubectl delete -f "$ROOT/k8s/panel/panel-backend.yaml" --ignore-not-found
kubectl delete -f "$ROOT/k8s/panel/postgres.yaml" --ignore-not-found
kubectl delete -f "$ROOT/k8s/panel/panel-backend-rbac.yaml" --ignore-not-found
kubectl delete -f "$ROOT/k8s/panel/panel-secrets.yaml" --ignore-not-found
kubectl delete -f "$ROOT/k8s/panel/namespace.yaml" --ignore-not-found

echo "Removing ingress-system..."
kubectl delete -f "$ROOT/k8s/ingress/traefik.yaml" --ignore-not-found
kubectl delete -f "$ROOT/k8s/ingress/namespace.yaml" --ignore-not-found

echo "Listing tenant namespaces (delete manually if desired)..."
kubectl get namespaces -l app.kubernetes.io/name=tenant 2>/dev/null || true

echo "Uninstall complete."
