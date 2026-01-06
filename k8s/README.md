# Kubernetes Manifests for Internet Banking Microservices

This directory contains Kubernetes manifests for deploying the Internet Banking microservices application with one-to-one microservice-to-container mapping.

## Architecture Overview

The application consists of:

### Infrastructure Services
- **service-registry** (Eureka): Service discovery on port 8081
- **config-server**: Centralized configuration on port 8090
- **api-gateway**: API Gateway on port 8080

### Business Services
- **core-banking-service**: Core banking operations on port 8083
- **user-service**: User management on port 8082
- **fund-transfer-service**: Fund transfers on port 8084
- **utility-payment-service**: Utility payments on port 8085

### Supporting Services
- **mysql**: Database on port 3306
- **rabbitmq**: Message broker on ports 5672 (AMQP) and 15672 (Management UI)
- **zipkin**: Distributed tracing on port 9411
- **keycloak**: Authentication/Authorization on port 8080

## Directory Structure

```
k8s/
├── namespace.yaml              # Namespace definition
├── configmap.yaml              # Shared configuration
├── secrets.yaml                # Placeholder for secrets (TODO: populate)
├── ingress.yaml                # Ingress to expose API Gateway
├── deployments/                # Service deployments
│   ├── service-registry-deployment.yaml
│   ├── config-server-deployment.yaml
│   ├── api-gateway-deployment.yaml
│   ├── core-banking-service-deployment.yaml
│   ├── user-service-deployment.yaml
│   ├── fund-transfer-service-deployment.yaml
│   └── utility-payment-service-deployment.yaml
├── services/                   # Service definitions
│   ├── service-registry-service.yaml
│   ├── config-server-service.yaml
│   ├── api-gateway-service.yaml
│   ├── core-banking-service-service.yaml
│   ├── user-service-service.yaml
│   ├── fund-transfer-service-service.yaml
│   └── utility-payment-service-service.yaml
└── supporting/                 # Supporting infrastructure
    ├── mysql-deployment.yaml
    ├── mysql-service.yaml
    ├── rabbitmq-deployment.yaml
    ├── rabbitmq-service.yaml
    ├── zipkin-deployment.yaml
    ├── zipkin-service.yaml
    ├── keycloak-deployment.yaml
    └── keycloak-service.yaml
```

## Prerequisites

1. Kubernetes cluster (v1.20+)
2. kubectl configured to access your cluster
3. NGINX Ingress Controller installed
4. Container images built and pushed to registry

## Deployment Instructions

### Step 1: Create Namespace and Base Resources

```bash
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
```

### Step 2: Deploy Supporting Services

Deploy supporting infrastructure (MySQL, RabbitMQ, Zipkin, Keycloak):

```bash
kubectl apply -f supporting/
```

Wait for supporting services to be ready:

```bash
kubectl wait --for=condition=ready pod -l tier=database -n internet-banking --timeout=300s
kubectl wait --for=condition=ready pod -l tier=messaging -n internet-banking --timeout=300s
kubectl wait --for=condition=ready pod -l tier=observability -n internet-banking --timeout=300s
kubectl wait --for=condition=ready pod -l tier=security -n internet-banking --timeout=300s
```

### Step 3: Deploy Infrastructure Services

Deploy service registry and config server first (order matters):

```bash
# Deploy Service Registry (Eureka)
kubectl apply -f deployments/service-registry-deployment.yaml
kubectl apply -f services/service-registry-service.yaml

# Wait for service registry to be ready
kubectl wait --for=condition=ready pod -l app=service-registry -n internet-banking --timeout=300s

# Deploy Config Server
kubectl apply -f deployments/config-server-deployment.yaml
kubectl apply -f services/config-server-service.yaml

# Wait for config server to be ready
kubectl wait --for=condition=ready pod -l app=config-server -n internet-banking --timeout=300s
```

### Step 4: Deploy Business Services

```bash
kubectl apply -f deployments/core-banking-service-deployment.yaml
kubectl apply -f services/core-banking-service-service.yaml

kubectl apply -f deployments/user-service-deployment.yaml
kubectl apply -f services/user-service-service.yaml

kubectl apply -f deployments/fund-transfer-service-deployment.yaml
kubectl apply -f services/fund-transfer-service-service.yaml

kubectl apply -f deployments/utility-payment-service-deployment.yaml
kubectl apply -f services/utility-payment-service-service.yaml
```

### Step 5: Deploy API Gateway

```bash
kubectl apply -f deployments/api-gateway-deployment.yaml
kubectl apply -f services/api-gateway-service.yaml
```

### Step 6: Deploy Ingress

```bash
kubectl apply -f ingress.yaml
```

## Configuration TODOs

Before deploying to production, complete these tasks:

### 1. Update Container Images

Replace placeholder images in all deployment files:
```yaml
# Current placeholder:
image: ghcr.io/org/service-name:latest

# Update to your actual registry:
image: your-registry.io/your-org/service-name:v1.0.0
```

### 2. Configure Secrets

Update `secrets.yaml` with base64-encoded actual values:

```bash
# Example: Encode a password
echo -n 'your-password' | base64

# Update secrets.yaml with encoded values
```

Required secrets:
- MySQL root password, user, and password
- RabbitMQ username and password
- Keycloak admin credentials

### 3. Update Ingress Host

In `ingress.yaml`, replace `banking.example.com` with your actual domain:
```yaml
rules:
- host: banking.yourdomain.com  # Update this
```

### 4. Configure TLS/SSL

Uncomment and configure TLS section in `ingress.yaml` after obtaining certificates.

### 5. Configure Persistent Storage

For production, replace `emptyDir` volumes with `PersistentVolumeClaim`:

Create PVCs for:
- MySQL data
- RabbitMQ data

### 6. Externalize Supporting Services

Consider using managed services in production:
- Managed MySQL (RDS, Cloud SQL, Azure Database)
- Managed RabbitMQ (CloudAMQP, Amazon MQ)
- Managed Keycloak or other identity providers

### 7. Update Resource Limits

Adjust CPU and memory requests/limits based on your workload:
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### 8. Configure Database Initialization

Ensure MySQL databases are created for each service:
- `banking_core` - Core banking service
- `banking_users` - User service
- `banking_fund_transfer` - Fund transfer service
- `banking_utility_payment` - Utility payment service

## Service Communication

Services communicate using Kubernetes DNS:

- **Service Registry**: `http://service-registry:8081/eureka`
- **Config Server**: `http://config-server:8090`
- **Core Banking**: `http://core-banking-service:8083`
- **User Service**: `http://user-service:8082`
- **Fund Transfer**: `http://fund-transfer-service:8084`
- **Utility Payment**: `http://utility-payment-service:8085`
- **MySQL**: `mysql:3306`
- **RabbitMQ**: `rabbitmq:5672`
- **Zipkin**: `http://zipkin:9411`
- **Keycloak**: `http://keycloak:8080`

## Health Checks

All services expose health endpoints at `/actuator/health`:

```bash
# Check service health
kubectl exec -n internet-banking deployment/api-gateway -- curl -s localhost:8080/actuator/health
```

## Monitoring

Access service dashboards:

```bash
# Port-forward to Eureka dashboard
kubectl port-forward -n internet-banking svc/service-registry 8081:8081
# Access at http://localhost:8081

# Port-forward to RabbitMQ management
kubectl port-forward -n internet-banking svc/rabbitmq 15672:15672
# Access at http://localhost:15672 (guest/guest)

# Port-forward to Zipkin UI
kubectl port-forward -n internet-banking svc/zipkin 9411:9411
# Access at http://localhost:9411

# Port-forward to Keycloak admin
kubectl port-forward -n internet-banking svc/keycloak 8080:8080
# Access at http://localhost:8080 (admin/admin)
```

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n internet-banking
```

### View Pod Logs
```bash
kubectl logs -n internet-banking deployment/api-gateway -f
```

### Describe Pod for Events
```bash
kubectl describe pod -n internet-banking <pod-name>
```

### Check Service Endpoints
```bash
kubectl get endpoints -n internet-banking
```

### Test Service Connectivity
```bash
# Test from within a pod
kubectl exec -n internet-banking deployment/api-gateway -- curl -s http://service-registry:8081/actuator/health
```

## Scaling

Scale services horizontally:

```bash
# Scale API Gateway
kubectl scale deployment api-gateway -n internet-banking --replicas=3

# Scale Core Banking Service
kubectl scale deployment core-banking-service -n internet-banking --replicas=2
```

## Cleanup

Remove all resources:

```bash
kubectl delete namespace internet-banking
```

Or remove individually:

```bash
kubectl delete -f ingress.yaml
kubectl delete -f services/
kubectl delete -f deployments/
kubectl delete -f supporting/
kubectl delete -f configmap.yaml
kubectl delete -f secrets.yaml
kubectl delete -f namespace.yaml
```

## Production Considerations

1. **High Availability**: Run multiple replicas of each service
2. **Database**: Use managed database services with backups
3. **Secrets Management**: Use external secret managers (Vault, AWS Secrets Manager)
4. **Monitoring**: Integrate with Prometheus and Grafana
5. **Logging**: Configure centralized logging (ELK, Loki)
6. **Security**: Implement NetworkPolicies, PodSecurityPolicies
7. **Resource Quotas**: Set namespace resource quotas
8. **Auto-scaling**: Configure HorizontalPodAutoscaler
9. **Backup**: Regular backups of persistent data
10. **CI/CD**: Automate deployment with GitOps (ArgoCD, Flux)

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Spring Cloud Kubernetes](https://spring.io/projects/spring-cloud-kubernetes)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
