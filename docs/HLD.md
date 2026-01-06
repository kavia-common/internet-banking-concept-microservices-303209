# High-Level Design (HLD) - Internet Banking Microservices System

## 1. Executive Summary

This document describes the high-level design of an Internet Banking system built using Java 11 and Spring Boot microservices architecture. The system provides core banking operations including user management, fund transfers, utility payments, and transaction processing through a distributed, cloud-native architecture.

## 2. System Goals and Objectives

### 2.1 Business Goals

The Internet Banking Microservices System aims to deliver a modern, scalable banking platform that enables customers to perform essential banking operations securely and efficiently. The system supports the following business capabilities:

- User registration and profile management with secure authentication
- Real-time fund transfers between accounts with balance validation
- Utility bill payments with third-party provider integration
- Account management including balance inquiries and transaction history
- Secure API access through centralized gateway with OAuth2/OIDC authentication

### 2.2 Technical Goals

The architecture is designed to achieve the following technical objectives:

- Enable independent development, deployment, and scaling of services
- Support horizontal scaling to handle varying transaction volumes
- Provide centralized configuration management across all services
- Implement distributed tracing and monitoring for observability
- Ensure secure inter-service communication and external API access
- Support containerized deployment on Docker and Kubernetes platforms

## 3. Non-Functional Requirements

### 3.1 Availability

The system is designed for high availability through:

- Service replication with multiple instances per microservice
- Netflix Eureka service registry for dynamic service discovery
- Health checks and automatic service registration/deregistration
- Graceful degradation when dependent services are unavailable
- Circuit breaker patterns (via Feign and Resilience4j capabilities)

**Target**: 99.5% uptime during business hours with no single point of failure for critical services.

### 3.2 Scalability

Scalability is achieved through:

- Horizontal scaling of stateless microservices
- Database connection pooling and query optimization
- Asynchronous message processing via RabbitMQ for non-critical operations
- Load balancing through Spring Cloud Gateway and Kubernetes services
- Independent scaling of each microservice based on load patterns

**Target**: Support 1000 concurrent users initially, scalable to 10,000+ users through horizontal scaling.

### 3.3 Consistency

Data consistency is maintained through:

- ACID transactions within service boundaries using JPA/Hibernate
- Transactional integrity for fund transfers with rollback capabilities
- Eventual consistency for cross-service operations through event-driven patterns
- Optimistic locking for concurrent account updates
- Database constraints to enforce referential integrity

**Trade-off**: The system prioritizes availability over strong consistency for non-critical operations, implementing eventual consistency where appropriate.

### 3.4 Observability

Comprehensive observability is achieved through:

- Distributed tracing with Spring Cloud Sleuth and Zipkin for request flow tracking
- Metrics collection and monitoring via Prometheus for system health
- Centralized logging strategy with correlation IDs across service boundaries
- Actuator endpoints for health checks and runtime metrics
- Request/response logging at API Gateway level

**Capabilities**: Track end-to-end request flows, identify performance bottlenecks, monitor service health, and troubleshoot issues across distributed services.

### 3.5 Security

Security is enforced at multiple layers:

- OAuth2/OpenID Connect authentication via Keycloak
- JWT token-based authorization with token propagation across services
- API Gateway as security perimeter with centralized authentication
- Role-based access control (RBAC) through Keycloak realms and roles
- Secure service-to-service communication patterns
- Input validation and sanitization to prevent injection attacks
- Global exception handling to prevent information leakage

**Standards**: Compliant with OWASP security best practices and OAuth2/OIDC standards.

### 3.6 Compliance

The system addresses regulatory compliance through:

- Audit trails for all financial transactions stored in the database
- User data protection with secure credential management via Keycloak
- Transaction reference numbers for regulatory reporting
- Data retention policies enforced through database lifecycle management
- Separation of concerns with dedicated services for sensitive operations

**Note**: Additional compliance requirements (PCI-DSS, GDPR, etc.) may require further enhancements beyond the current implementation.

## 4. Key Design Decisions

### 4.1 Microservices Architecture

**Decision**: Adopt microservices architecture instead of monolithic design.

**Rationale**: Enables independent development cycles, technology stack flexibility, isolated failure domains, and independent scaling of services based on load patterns.

**Trade-offs**: Increased operational complexity, distributed system challenges (network latency, partial failures), and need for sophisticated monitoring and tracing.

### 4.2 Service Discovery with Netflix Eureka

**Decision**: Use Netflix Eureka for dynamic service discovery.

**Rationale**: Eliminates hard-coded service locations, enables dynamic scaling, provides client-side load balancing, and automatically handles service instance registration and health checks.

**Alternative Considered**: Kubernetes service discovery was considered but Eureka provides language-agnostic service discovery that works both in and outside Kubernetes.

### 4.3 API Gateway Pattern

**Decision**: Implement Spring Cloud Gateway as the single entry point for external requests.

**Rationale**: Provides centralized authentication, routing, load balancing, rate limiting capabilities, and shields internal service topology from external clients.

**Implementation**: Gateway integrates with Keycloak for OAuth2/OIDC authentication and propagates user identity via custom headers.

### 4.4 Synchronous Communication with OpenFeign

**Decision**: Use Spring Cloud OpenFeign for inter-service HTTP communication.

**Rationale**: Provides declarative REST client with service discovery integration, built-in load balancing, and simplified error handling compared to RestTemplate.

**Trade-offs**: Tight coupling between services, potential cascading failures (mitigated with circuit breakers), and increased latency for multi-hop requests.

### 4.5 Asynchronous Messaging with RabbitMQ

**Decision**: Implement RabbitMQ for asynchronous event-driven communication.

**Rationale**: Decouples services for non-critical operations, enables scalable notification delivery, provides message durability, and allows services to process events at their own pace.

**Use Cases**: Transaction notifications, audit event publishing, and cross-service event propagation.

### 4.6 Database Per Service Pattern

**Decision**: Each microservice maintains its own database schema within MySQL.

**Rationale**: Ensures loose coupling, allows independent schema evolution, enables service autonomy, and prevents direct database dependencies between services.

**Implementation**: Core banking service owns accounts and transactions; user service owns user profiles; fund transfer and utility payment services own transaction records.

### 4.7 Centralized Configuration with Spring Cloud Config

**Decision**: Use Spring Cloud Config Server backed by Git repository for configuration management.

**Rationale**: Enables externalized configuration, supports environment-specific properties, provides configuration versioning, and allows dynamic configuration updates without redeployment.

**Trade-offs**: Additional infrastructure component and dependency; Config Server becomes a critical component requiring high availability.

### 4.8 Schema Migration with Flyway

**Decision**: Use Flyway for database schema versioning and migration.

**Rationale**: Provides version-controlled schema evolution, repeatable migrations, and consistent database state across environments.

**Approach**: Sequential versioned migrations stored in source control and applied automatically on service startup.

### 4.9 Keycloak for Identity and Access Management

**Decision**: Integrate Keycloak for authentication and authorization instead of custom implementation.

**Rationale**: Provides enterprise-grade OAuth2/OIDC implementation, user federation capabilities, role management, and reduces development effort for security-critical components.

**Integration**: User service integrates with Keycloak Admin API for user management; API Gateway validates JWT tokens issued by Keycloak.

## 5. Bounded Contexts and Domain Model

The system is organized into the following bounded contexts aligned with Domain-Driven Design principles:

### 5.1 User Management Context

**Responsibilities**: User registration, profile management, and authentication lifecycle.

**Key Entities**: User (with identification number, email, name), Keycloak user representation.

**Services**: User Service (application), Keycloak (infrastructure).

**Boundaries**: Manages user identity and profile data; coordinates with Core Banking context for account association.

### 5.2 Core Banking Context

**Responsibilities**: Account management, balance tracking, transaction recording, and core banking operations.

**Key Entities**: BankAccount (with account number, type, status, balances), Transaction (with type, amount, reference), UtilityAccount (provider accounts).

**Services**: Core Banking Service.

**Boundaries**: Authoritative source for account and transaction data; provides APIs for account queries and transaction processing.

### 5.3 Fund Transfer Context

**Responsibilities**: Orchestrating fund transfers between accounts, managing transfer lifecycle, and maintaining transfer history.

**Key Entities**: FundTransfer (with source/destination accounts, amount, status).

**Services**: Fund Transfer Service.

**Boundaries**: Coordinates with Core Banking context for actual fund movement; maintains audit trail of transfer requests and outcomes.

### 5.4 Utility Payment Context

**Responsibilities**: Processing utility bill payments, provider integration, and payment reconciliation.

**Key Entities**: UtilityPayment (with provider ID, account number, amount, reference).

**Services**: Utility Payment Service.

**Boundaries**: Manages payment requests to utility providers; coordinates with Core Banking context for fund deduction.

### 5.5 Infrastructure Context

**Responsibilities**: Cross-cutting concerns including service discovery, configuration, routing, and observability.

**Services**: API Gateway, Service Registry (Eureka), Config Server, Zipkin, Prometheus.

**Boundaries**: Provides platform capabilities used by all business services.

## 6. Service Responsibilities

### 6.1 Core Banking Service

**Primary Responsibilities**:
- Manage bank accounts (creation, queries, status updates)
- Track account balances (actual and available)
- Record financial transactions with full audit trail
- Process fund transfer requests with balance validation
- Process utility payment requests with balance verification
- Maintain utility account provider information
- Provide user information queries

**Technology Stack**: Spring Boot, Spring Data JPA, MySQL, Flyway, Eureka Client.

**API Endpoints**: Account queries, user queries, fund transfer processing, utility payment processing.

**Data Ownership**: Accounts, transactions, users, utility accounts.

### 6.2 User Service

**Primary Responsibilities**:
- Register new users with Keycloak integration
- Update user profiles and manage user lifecycle
- Synchronize user data between local database and Keycloak
- Validate user information (email format, identification)
- Query user details from Core Banking service
- Handle user-related exceptions and validations

**Technology Stack**: Spring Boot, Spring Data JPA, MySQL, Keycloak Admin Client, OpenFeign, Eureka Client.

**API Endpoints**: User registration, user updates, user profile retrieval.

**Data Ownership**: User entities (shared with Core Banking for consistency).

**External Dependencies**: Keycloak (authentication provider), Core Banking Service (user validation).

### 6.3 Fund Transfer Service

**Primary Responsibilities**:
- Accept and validate fund transfer requests
- Orchestrate fund transfers via Core Banking service
- Track transfer status (pending, completed, failed)
- Maintain transfer transaction history
- Provide transfer history queries with pagination
- Handle transfer-related exceptions

**Technology Stack**: Spring Boot, Spring Data JPA, MySQL, OpenFeign, Eureka Client.

**API Endpoints**: Initiate fund transfer, retrieve transfer history.

**Data Ownership**: Fund transfer transaction records.

**External Dependencies**: Core Banking Service (for actual fund movement).

### 6.4 Utility Payment Service

**Primary Responsibilities**:
- Accept and validate utility payment requests
- Orchestrate payments via Core Banking service
- Track payment status and outcomes
- Maintain payment transaction history
- Validate utility account and provider information
- Handle payment-related exceptions

**Technology Stack**: Spring Boot, Spring Data JPA, MySQL, OpenFeign, Eureka Client.

**API Endpoints**: Initiate utility payment, retrieve payment history.

**Data Ownership**: Utility payment transaction records.

**External Dependencies**: Core Banking Service (for fund deduction and validation).

### 6.5 API Gateway

**Primary Responsibilities**:
- Route external requests to appropriate microservices
- Authenticate requests via OAuth2/OIDC with Keycloak
- Validate JWT tokens and extract user identity
- Propagate user identity to downstream services via headers
- Apply cross-cutting concerns (CORS, rate limiting capabilities)
- Provide unified API interface to external clients

**Technology Stack**: Spring Cloud Gateway (WebFlux), Spring Security OAuth2, Eureka Client.

**Routing Strategy**: Dynamic routing based on service discovery with path-based routing rules.

**Security**: OAuth2 Resource Server configuration with JWT validation.

### 6.6 Service Registry (Eureka Server)

**Primary Responsibilities**:
- Maintain registry of all service instances
- Health check monitoring of registered services
- Provide service discovery endpoints for clients
- Support dynamic scaling with automatic registration

**Technology Stack**: Netflix Eureka Server, Spring Boot.

**Port**: 8081 (default configuration).

**High Availability**: Supports peer-to-peer replication for production deployments.

### 6.7 Config Server

**Primary Responsibilities**:
- Serve externalized configuration to all microservices
- Support environment-specific configuration profiles
- Integrate with Git repository for version-controlled configuration
- Provide configuration refresh capabilities via Spring Cloud Bus (future enhancement)

**Technology Stack**: Spring Cloud Config Server, Spring Boot.

**Port**: 8090 (default configuration).

**Backend**: Git repository (https://github.com/javatodev/internet-banking-configurations.git).

## 7. Integration Patterns

### 7.1 Synchronous Request-Response

Used for operations requiring immediate response and strong consistency:
- User queries from Core Banking service
- Account balance checks before transactions
- Fund transfer and payment processing

**Implementation**: Spring Cloud OpenFeign with service discovery and load balancing.

### 7.2 Asynchronous Event-Driven

Used for operations that can be processed eventually:
- Transaction notifications (future enhancement with RabbitMQ)
- Audit event publishing
- Cross-service event propagation

**Implementation**: RabbitMQ message broker with topic exchanges.

### 7.3 API Gateway Pattern

All external requests flow through API Gateway:
- Centralized authentication and authorization
- Dynamic routing to backend services
- User identity propagation via custom headers

### 7.4 Service Registry Pattern

All services register with Eureka:
- Dynamic service discovery
- Client-side load balancing
- Health monitoring and automatic deregistration

## 8. Error Handling Strategy

### 8.1 Exception Hierarchy

The system implements a consistent exception hierarchy:
- `SimpleBankingGlobalException`: Base exception with error code and message
- Domain-specific exceptions: `EntityNotFoundException`, `InsufficientFundsException`, `InvalidEmailException`, `UserAlreadyRegisteredException`

### 8.2 Global Exception Handlers

Each service implements `@RestControllerAdvice` for centralized exception handling:
- Maps exceptions to appropriate HTTP status codes
- Returns consistent `ErrorResponse` structure
- Prevents sensitive information leakage
- Logs exceptions for troubleshooting

### 8.3 Feign Error Handling

Custom Feign error decoders handle inter-service errors:
- Parse error responses from downstream services
- Convert to appropriate domain exceptions
- Enable exception propagation across service boundaries

## 9. Testing Strategy

### 9.1 Unit Testing

Each service includes JUnit tests with Spring Boot Test support:
- Service layer logic testing
- Repository integration tests with H2 in-memory database
- Mock external dependencies using Mockito

### 9.2 Integration Testing

H2 database used for integration tests:
- Validates database schema and migrations
- Tests complete request-response flows
- Verifies data persistence and retrieval

### 9.3 Contract Testing

Feign client interfaces serve as contracts:
- Define expected API signatures
- Enable consumer-driven contract testing approach
- Support independent service evolution

## 10. Deployment Architecture Overview

### 10.1 Containerization

All services are containerized using Docker:
- Consistent runtime environment across environments
- Simplified dependency management
- Support for container orchestration platforms

### 10.2 Orchestration

Kubernetes support for production deployments:
- Service replication and scaling
- Rolling updates with zero downtime
- Health checks (readiness and liveness probes)
- ConfigMaps and Secrets for configuration
- Ingress for external access routing

### 10.3 Infrastructure Dependencies

Required infrastructure components:
- MySQL database for persistent storage
- Keycloak server for authentication
- RabbitMQ broker for messaging
- Zipkin server for distributed tracing
- Prometheus server for metrics collection
- Eureka server for service discovery
- Config server for configuration management

## 11. Assumptions and Constraints

### 11.1 Assumptions

- All services share the same MySQL database server with separate schemas
- Network latency between services is minimal (co-located deployment)
- Keycloak is pre-configured with appropriate realms and clients
- Git repository for Config Server is accessible from all environments
- External clients can obtain OAuth2 tokens from Keycloak before API access

### 11.2 Constraints

- Java 11 runtime required for all services
- Spring Boot 2.5.x framework version
- MySQL database (other RDBMS not supported without code changes)
- Services must register with Eureka to be discoverable
- Configuration must be available in Config Server Git repository

## 12. Future Enhancements

### 12.1 Resilience Improvements

- Implement circuit breakers using Resilience4j
- Add retry policies for transient failures
- Implement bulkhead patterns for resource isolation
- Add timeout configurations for all external calls

### 12.2 Performance Optimizations

- Introduce caching layer (Redis) for frequently accessed data
- Implement database read replicas for query scalability
- Add database connection pooling optimizations
- Consider event sourcing for transaction history

### 12.3 Advanced Features

- Implement saga pattern for distributed transactions
- Add outbox pattern for reliable event publishing
- Introduce rate limiting at API Gateway level
- Implement idempotency for fund transfers and payments
- Add request/response transformation at gateway
- Implement API versioning strategy

### 12.4 Operational Enhancements

- Implement centralized logging with ELK stack
- Add business metrics and dashboards
- Implement automated alerting based on metrics
- Add chaos engineering for resilience testing
- Implement blue-green deployment strategy
