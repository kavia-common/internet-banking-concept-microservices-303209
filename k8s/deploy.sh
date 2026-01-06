#!/bin/bash

# Internet Banking Microservices - Kubernetes Deployment Script
# This script deploys all services in the correct order

set -e

NAMESPACE="internet-banking"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Internet Banking Kubernetes Deployment"
echo "=========================================="
echo ""

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment=$1
    local timeout=${2:-300}
    
    echo "Waiting for deployment/$deployment to be ready (timeout: ${timeout}s)..."
    kubectl wait --for=condition=available deployment/$deployment \
        -n $NAMESPACE --timeout=${timeout}s || {
        echo "ERROR: Deployment $deployment failed to become ready"
        kubectl get pods -n $NAMESPACE -l app=$deployment
        kubectl logs -n $NAMESPACE -l app=$deployment --tail=50
        return 1
    }
    echo "✓ Deployment $deployment is ready"
}

# Function to wait for pods to be ready
wait_for_pods() {
    local label=$1
    local timeout=${2:-300}
    
    echo "Waiting for pods with label $label to be ready (timeout: ${timeout}s)..."
    kubectl wait --for=condition=ready pod -l $label \
        -n $NAMESPACE --timeout=${timeout}s || {
        echo "ERROR: Pods with label $label failed to become ready"
        return 1
    }
    echo "✓ Pods with label $label are ready"
}

echo "Step 1: Creating namespace and base resources..."
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"
kubectl apply -f "$SCRIPT_DIR/configmap.yaml"
kubectl apply -f "$SCRIPT_DIR/secrets.yaml"
echo "✓ Namespace and base resources created"
echo ""

echo "Step 2: Deploying supporting services..."
echo "Deploying MySQL..."
kubectl apply -f "$SCRIPT_DIR/supporting/mysql-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/supporting/mysql-service.yaml"
wait_for_deployment "mysql" 300

echo ""
echo "Deploying RabbitMQ..."
kubectl apply -f "$SCRIPT_DIR/supporting/rabbitmq-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/supporting/rabbitmq-service.yaml"
wait_for_deployment "rabbitmq" 300

echo ""
echo "Deploying Zipkin..."
kubectl apply -f "$SCRIPT_DIR/supporting/zipkin-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/supporting/zipkin-service.yaml"
wait_for_deployment "zipkin" 300

echo ""
echo "Deploying Keycloak..."
kubectl apply -f "$SCRIPT_DIR/supporting/keycloak-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/supporting/keycloak-service.yaml"
wait_for_deployment "keycloak" 300

echo ""
echo "✓ All supporting services deployed"
echo ""

echo "Step 3: Deploying infrastructure services..."
echo "Deploying Service Registry (Eureka)..."
kubectl apply -f "$SCRIPT_DIR/deployments/service-registry-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/services/service-registry-service.yaml"
wait_for_deployment "service-registry" 300

echo ""
echo "Deploying Config Server..."
kubectl apply -f "$SCRIPT_DIR/deployments/config-server-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/services/config-server-service.yaml"
wait_for_deployment "config-server" 300

echo ""
echo "✓ Infrastructure services deployed"
echo ""

# Give services time to register with Eureka
echo "Waiting 30 seconds for service discovery to stabilize..."
sleep 30

echo "Step 4: Deploying business services..."
echo "Deploying Core Banking Service..."
kubectl apply -f "$SCRIPT_DIR/deployments/core-banking-service-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/services/core-banking-service-service.yaml"

echo ""
echo "Deploying User Service..."
kubectl apply -f "$SCRIPT_DIR/deployments/user-service-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/services/user-service-service.yaml"

echo ""
echo "Deploying Fund Transfer Service..."
kubectl apply -f "$SCRIPT_DIR/deployments/fund-transfer-service-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/services/fund-transfer-service-service.yaml"

echo ""
echo "Deploying Utility Payment Service..."
kubectl apply -f "$SCRIPT_DIR/deployments/utility-payment-service-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/services/utility-payment-service-service.yaml"

echo ""
echo "Waiting for all business services to be ready..."
wait_for_deployment "core-banking-service" 300
wait_for_deployment "user-service" 300
wait_for_deployment "fund-transfer-service" 300
wait_for_deployment "utility-payment-service" 300

echo ""
echo "✓ All business services deployed"
echo ""

echo "Step 5: Deploying API Gateway..."
kubectl apply -f "$SCRIPT_DIR/deployments/api-gateway-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/services/api-gateway-service.yaml"
wait_for_deployment "api-gateway" 300

echo ""
echo "✓ API Gateway deployed"
echo ""

echo "Step 6: Deploying Ingress..."
kubectl apply -f "$SCRIPT_DIR/ingress.yaml"
echo "✓ Ingress deployed"
echo ""

echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo ""
kubectl get all -n $NAMESPACE
echo ""

echo "=========================================="
echo "Service Endpoints"
echo "=========================================="
echo ""
kubectl get svc -n $NAMESPACE
echo ""

echo "=========================================="
echo "Ingress Information"
echo "=========================================="
echo ""
kubectl get ingress -n $NAMESPACE
echo ""

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "To access services:"
echo "  - API Gateway: kubectl port-forward -n $NAMESPACE svc/api-gateway 8080:8080"
echo "  - Eureka Dashboard: kubectl port-forward -n $NAMESPACE svc/service-registry 8081:8081"
echo "  - RabbitMQ Management: kubectl port-forward -n $NAMESPACE svc/rabbitmq 15672:15672"
echo "  - Zipkin UI: kubectl port-forward -n $NAMESPACE svc/zipkin 9411:9411"
echo "  - Keycloak Admin: kubectl port-forward -n $NAMESPACE svc/keycloak 8080:8080"
echo ""
echo "Check pod status: kubectl get pods -n $NAMESPACE"
echo "View logs: kubectl logs -n $NAMESPACE deployment/<service-name> -f"
echo ""
