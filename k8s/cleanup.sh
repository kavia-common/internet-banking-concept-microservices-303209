#!/bin/bash

# Internet Banking Microservices - Kubernetes Cleanup Script
# This script removes all deployed resources

set -e

NAMESPACE="internet-banking"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Internet Banking Kubernetes Cleanup"
echo "=========================================="
echo ""

read -p "Are you sure you want to delete all resources in namespace '$NAMESPACE'? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Deleting resources in the following order:"
echo "1. Ingress"
echo "2. Services and Deployments"
echo "3. ConfigMap and Secrets"
echo "4. Namespace"
echo ""

echo "Step 1: Deleting Ingress..."
kubectl delete -f "$SCRIPT_DIR/ingress.yaml" --ignore-not-found=true
echo "✓ Ingress deleted"
echo ""

echo "Step 2: Deleting Services and Deployments..."

echo "Deleting API Gateway..."
kubectl delete -f "$SCRIPT_DIR/services/api-gateway-service.yaml" --ignore-not-found=true
kubectl delete -f "$SCRIPT_DIR/deployments/api-gateway-deployment.yaml" --ignore-not-found=true

echo "Deleting Business Services..."
kubectl delete -f "$SCRIPT_DIR/services/utility-payment-service-service.yaml" --ignore-not-found=true
kubectl delete -f "$SCRIPT_DIR/deployments/utility-payment-service-deployment.yaml" --ignore-not-found=true

kubectl delete -f "$SCRIPT_DIR/services/fund-transfer-service-service.yaml" --ignore-not-found=true
kubectl delete -f "$SCRIPT_DIR/deployments/fund-transfer-service-deployment.yaml" --ignore-not-found=true

kubectl delete -f "$SCRIPT_DIR/services/user-service-service.yaml" --ignore-not-found=true
kubectl delete -f "$SCRIPT_DIR/deployments/user-service-deployment.yaml" --ignore-not-found=true

kubectl delete -f "$SCRIPT_DIR/services/core-banking-service-service.yaml" --ignore-not-found=true
kubectl delete -f "$SCRIPT_DIR/deployments/core-banking-service-deployment.yaml" --ignore-not-found=true

echo "Deleting Infrastructure Services..."
kubectl delete -f "$SCRIPT_DIR/services/config-server-service.yaml" --ignore-not-found=true
kubectl delete -f "$SCRIPT_DIR/deployments/config-server-deployment.yaml" --ignore-not-found=true

kubectl delete -f "$SCRIPT_DIR/services/service-registry-service.yaml" --ignore-not-found=true
kubectl delete -f "$SCRIPT_DIR/deployments/service-registry-deployment.yaml" --ignore-not-found=true

echo "Deleting Supporting Services..."
kubectl delete -f "$SCRIPT_DIR/supporting/" --ignore-not-found=true

echo "✓ All services and deployments deleted"
echo ""

echo "Step 3: Deleting ConfigMap and Secrets..."
kubectl delete -f "$SCRIPT_DIR/configmap.yaml" --ignore-not-found=true
kubectl delete -f "$SCRIPT_DIR/secrets.yaml" --ignore-not-found=true
echo "✓ ConfigMap and Secrets deleted"
echo ""

echo "Step 4: Deleting Namespace..."
kubectl delete -f "$SCRIPT_DIR/namespace.yaml" --ignore-not-found=true
echo "✓ Namespace deleted"
echo ""

echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""
echo "All resources have been removed."
echo ""
