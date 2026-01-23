# Microservices Architecture Reference

This document provides detailed guidance on microservices architecture, communication patterns, resilience strategies, and implementation best practices.

**Primary References**: 
- Sam Newman, "Building Microservices"
- Chris Richardson, "Microservices Patterns"

---

## Overview

Microservices Architecture structures an application as a collection of loosely coupled services that:
- Are organized around business capabilities
- Are independently deployable
- Communicate through well-defined APIs
- Are owned by small, autonomous teams

| Aspect | Monolith | Microservices |
|--------|----------|---------------|
| Deployment | All-or-nothing | Independent per service |
| Scaling | Scale entire application | Scale individual services |
| Technology | Single stack | Can vary (but not recommended) |
| Data | Single database | Database per service |
| Team Structure | Organized by layer | Organized by capability |
| Failure | Entire system affected | Isolated to service |

---

## Service Design

### Service Boundaries

Services should be designed around **business capabilities** and **bounded contexts** from DDD.

**Good Service Boundaries:**
- Aligned with business domain
- Minimal dependencies on other services
- Single responsibility
- Owns its data
- Can be developed by one team

**Signs of Poor Boundaries:**
- Frequent cross-service changes
- Circular dependencies
- Chatty communication patterns
- Shared databases
- Distributed transactions

### Service Sizing

| Size | Characteristics | Risks |
|------|-----------------|-------|
| **Too Large** | Many responsibilities, slow deployments | Becoming a distributed monolith |
| **Too Small** | Simple operations, high overhead | Nano-service complexity |
| **Right Size** | Single business capability, team ownership | Balance complexity and cohesion |

**Guideline**: A service should be small enough that a team can fully own it, but large enough to provide meaningful business value independently.

---

## Communication Patterns

### Synchronous Communication

Direct request-response communication between services.

| Pattern | Use Case | Considerations |
|---------|----------|----------------|
| **REST/HTTP** | CRUD operations, simple queries | Simple, widely supported, couples availability |
| **gRPC** | High-performance, internal APIs | Efficient, strongly typed, requires protobuf |
| **GraphQL** | Flexible queries, aggregation | Client flexibility, complexity at gateway |

**REST Example:**
```
// Order Service calls Product Service
GET /products/{product_id}
Response: { "id": "123", "name": "Widget", "price": 29.99 }
```

### Asynchronous Communication

Event-driven, message-based communication.

| Pattern | Use Case | Considerations |
|---------|----------|----------------|
| **Message Queue** | Work distribution, buffering | Decouples services, eventual consistency |
| **Pub/Sub** | Event notification, fan-out | Loose coupling, multiple consumers |
| **Event Sourcing** | Audit, replay, event-driven | Complex, requires event store |

**Event Example:**
```
// Order Service publishes event
Event: OrderPlaced
Topic: orders.placed
Payload: {
    "order_id": "ord-123",
    "customer_id": "cust-456",
    "items": [...],
    "total": 150.00,
    "occurred_at": "2024-01-15T10:30:00Z"
}

// Inventory Service subscribes and updates stock
// Notification Service subscribes and sends email
// Analytics Service subscribes and records metrics
```

### Communication Pattern Selection

```
                    ┌─────────────────┐
                    │ Need immediate  │
                    │    response?    │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
             YES                           NO
              │                             │
              ▼                             ▼
     ┌────────────────┐           ┌─────────────────┐
     │  Synchronous   │           │  Asynchronous   │
     │  (REST, gRPC)  │           │  (Events, MQ)   │
     └────────────────┘           └─────────────────┘
```

---

## Data Management

### Database per Service

Each service owns its database, ensuring loose coupling and independent scaling.

**Benefits:**
- Services can use appropriate database technology
- Schema changes don't affect other services
- Independent scaling and optimization
- Clear data ownership

**Challenges:**
- Data consistency across services
- Cross-service queries
- Data duplication

### Data Consistency Patterns

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Saga** | Sequence of local transactions with compensating actions | Distributed transactions |
| **Event Sourcing** | Store events instead of current state | Audit, temporal queries |
| **CQRS** | Separate read and write models | High-read workloads |
| **Eventual Consistency** | Accept temporary inconsistency | Non-critical data |

**Saga Example (Choreography):**
```
1. Order Service: Create order (PENDING)
   → Publish: OrderCreated

2. Payment Service: Process payment
   → Success: Publish PaymentCompleted
   → Failure: Publish PaymentFailed

3. Order Service: Handle PaymentCompleted
   → Update order (CONFIRMED)
   → Publish: OrderConfirmed

4. Inventory Service: Reserve stock
   → Success: Publish StockReserved
   → Failure: Publish StockReservationFailed
     → Trigger compensation: Refund payment, Cancel order
```

---

## Resilience Patterns

### Circuit Breaker

Prevents cascading failures by stopping requests to failing services.

**States:**
- **Closed**: Requests flow normally
- **Open**: Requests fail immediately (service assumed down)
- **Half-Open**: Limited requests allowed to test recovery

```
┌────────┐  failure threshold  ┌────────┐
│ Closed │ ──────────────────▶ │  Open  │
└────────┘                     └────────┘
    ▲                              │
    │     success threshold        │ timeout
    │                              ▼
    └──────────────────────── ┌──────────┐
                              │Half-Open │
                              └──────────┘
```

### Retry with Backoff

Automatically retry failed requests with increasing delays.

**Strategy:**
```
Attempt 1: Immediate
Attempt 2: Wait 1 second
Attempt 3: Wait 2 seconds
Attempt 4: Wait 4 seconds
Attempt 5: Give up, circuit breaker opens
```

**Considerations:**
- Only retry idempotent operations
- Add jitter to prevent thundering herd
- Set maximum retries

### Bulkhead

Isolate failures to prevent cascading effects.

| Type | Description |
|------|-------------|
| **Thread Pool Bulkhead** | Separate thread pools per dependency |
| **Connection Pool Bulkhead** | Separate connection pools per service |
| **Service Bulkhead** | Separate service instances per consumer |

### Timeout

Set appropriate timeouts to prevent indefinite waiting.

**Guidelines:**
- Set timeouts based on SLAs
- Consider downstream dependencies
- Shorter timeouts for user-facing requests
- Longer timeouts for background jobs

### Fallback

Provide degraded functionality when a service is unavailable.

**Examples:**
- Return cached data
- Return default values
- Use alternative service
- Return partial results

---

## Shared Infrastructure Library

To reduce maintenance costs and ensure consistency, use a **shared infrastructure library** across services.

> See [shared-infrastructure-library.md](shared-infrastructure-library.md) for detailed implementation patterns.

### Why Shared Infrastructure?

| Without Shared Library | With Shared Library |
|------------------------|---------------------|
| Duplicated boilerplate code | Consistent implementations |
| Inconsistent patterns | Standardized patterns |
| Different logging formats | Unified observability |
| Varied error handling | Common error responses |
| Multiple configuration approaches | Centralized configuration |
| Higher maintenance burden | Lower maintenance overhead |

### What to Include

| Component | Purpose |
|-----------|---------|
| Repository Base Classes | Common CRUD operations, query patterns |
| Database Adapters | Connection management, transactions |
| HTTP Client | Configured timeouts, retries, circuit breaker |
| Message Client | Producer/consumer abstractions |
| Logging | Structured logging, correlation IDs |
| Configuration | Environment-based config loading |
| Health Checks | Standardized health endpoints |
| Error Handling | Common exception types, error responses |
| Middleware | Authentication, logging, tracing |

### What NOT to Include

- Business logic (keep in services)
- Service-specific models
- UI components
- Service-specific configuration

---

## Service Discovery

### Patterns

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Client-Side Discovery** | Client queries registry, selects instance | Fine-grained control |
| **Server-Side Discovery** | Load balancer queries registry | Simpler clients |
| **Service Mesh** | Sidecar proxy handles discovery | Advanced traffic management |

### Service Registry

```
Service Registry
├── Order Service
│   ├── Instance 1: 10.0.1.10:8080 (healthy)
│   ├── Instance 2: 10.0.1.11:8080 (healthy)
│   └── Instance 3: 10.0.1.12:8080 (unhealthy)
├── Product Service
│   ├── Instance 1: 10.0.2.10:8080 (healthy)
│   └── Instance 2: 10.0.2.11:8080 (healthy)
└── Payment Service
    └── Instance 1: 10.0.3.10:8080 (healthy)
```

---

## Observability

### Three Pillars

| Pillar | Purpose | Tools |
|--------|---------|-------|
| **Logging** | Record discrete events | ELK, Loki, CloudWatch |
| **Metrics** | Measure system behavior | Prometheus, Datadog, CloudWatch |
| **Tracing** | Track request flow | Jaeger, Zipkin, X-Ray |

### Correlation IDs

Track requests across service boundaries:

```
Request: POST /orders
Headers:
  X-Correlation-ID: abc-123-def-456

Order Service logs:
  {"correlation_id": "abc-123-def-456", "message": "Creating order"}

Payment Service logs:
  {"correlation_id": "abc-123-def-456", "message": "Processing payment"}

Inventory Service logs:
  {"correlation_id": "abc-123-def-456", "message": "Reserving stock"}
```

### Health Endpoints

Every service should expose:

| Endpoint | Purpose |
|----------|---------|
| `/health/live` | Service is running (liveness probe) |
| `/health/ready` | Service can accept traffic (readiness probe) |
| `/health/startup` | Service has finished initialization |

---

## Deployment Patterns

### Blue-Green Deployment

```
Load Balancer
     │
     ├──▶ Blue (v1.0) ← current traffic
     │
     └──▶ Green (v1.1) ← new version, testing
     
After validation: Switch traffic to Green
```

### Canary Deployment

```
Load Balancer
     │
     ├──▶ Stable (v1.0) ← 95% traffic
     │
     └──▶ Canary (v1.1) ← 5% traffic
     
Gradually increase Canary percentage
```

### Rolling Deployment

```
Instances: [v1.0] [v1.0] [v1.0] [v1.0]
Step 1:    [v1.1] [v1.0] [v1.0] [v1.0]
Step 2:    [v1.1] [v1.1] [v1.0] [v1.0]
Step 3:    [v1.1] [v1.1] [v1.1] [v1.0]
Step 4:    [v1.1] [v1.1] [v1.1] [v1.1]
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| **Distributed Monolith** | Tightly coupled services | Define proper boundaries |
| **Shared Database** | Couples services through data | Database per service |
| **Synchronous Chains** | Long request chains, fragile | Use async communication |
| **Big Bang Migration** | High risk, all-or-nothing | Strangler fig pattern |
| **Ignoring CAP Theorem** | Unrealistic expectations | Accept trade-offs |
| **No API Versioning** | Breaking changes affect consumers | Version APIs from start |
| **Missing Circuit Breakers** | Cascading failures | Implement resilience patterns |
