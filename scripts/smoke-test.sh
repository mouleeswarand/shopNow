#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="shopnow"

echo "=== Checking application deployments ==="

for deployment in mongodb backend frontend admin; do
  echo "Checking deployment: $deployment"
  kubectl rollout status "deployment/$deployment" \
    -n "$NAMESPACE" \
    --timeout=120s
done

echo
echo "=== Checking MongoDB persistent storage ==="

PVC_STATUS=$(kubectl get pvc mongodb-data -n "$NAMESPACE" \
  -o jsonpath='{.status.phase}')

if [ "$PVC_STATUS" != "Bound" ]; then
  echo "FAIL: MongoDB PVC status is $PVC_STATUS; expected Bound"
  exit 1
fi

echo "PASS: MongoDB PVC is Bound"

echo
echo "=== Checking frontend API route ==="

kubectl exec -n "$NAMESPACE" deployment/frontend -- \
  wget -qO- http://127.0.0.1/mouli/api/products |
  grep -q '"products"'

echo "PASS: Frontend can reach the products API"

echo
echo "=== Checking admin API route ==="

kubectl exec -n "$NAMESPACE" deployment/admin -- \
  wget -qO- http://127.0.0.1/mouli-admin/api/health |
  grep -q '"status":"OK"'

echo "PASS: Admin can reach the backend health endpoint"

echo
echo "All ShopNow smoke tests passed."
