#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="argocd"
DEPLOYMENT="argocd-repo-server"
SIDECAR="groupos-sops-cmp"

cd "$(dirname "$0")/.."

echo "Checking SOPS CMP prerequisites..."

kubectl get namespace "$NAMESPACE" >/dev/null
kubectl get secret groupos-sops-age-key -n "$NAMESPACE" >/dev/null

kubectl apply \
  -f kubernetes/argocd/sops-cmp-config.yaml

CURRENT_CONTAINERS="$(
  kubectl get deployment "$DEPLOYMENT" \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[*].name}'
)"

if [[ " $CURRENT_CONTAINERS " == *" $SIDECAR "* ]]; then
  echo "CMP sidecar already installed."
else
  echo "Installing CMP sidecar..."

  kubectl patch deployment "$DEPLOYMENT" \
    -n "$NAMESPACE" \
    --type=json \
    --patch-file kubernetes/argocd/sops-cmp-sidecar.patch.yaml
fi

kubectl rollout status \
  deployment/"$DEPLOYMENT" \
  -n "$NAMESPACE" \
  --timeout=180s

echo "CMP reconciliation completed."
