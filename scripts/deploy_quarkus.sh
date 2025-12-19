#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="quarkus"

echo "Validating namespace $NAMESPACE..."

# Create namespace only if missing
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "Namespace '$NAMESPACE' missing — provisioning..."
    kubectl create namespace "$NAMESPACE"
else
    echo "Namespace '$NAMESPACE' present — leveraging existing environment."
fi

echo "Rolling forward application assets..."

# Apply manifests (smart redeploy)
kubectl apply -f k8s/deployment.yaml -n "$NAMESPACE"
kubectl apply -f k8s/service.yaml    -n "$NAMESPACE" || true
sleep 10
echo "Surfacing runtime status..."
kubectl get pods -n "$NAMESPACE"
kubectl get svc  -n "$NAMESPACE"
