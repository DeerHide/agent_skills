# Shared Infrastructure Library Reference

This document provides guidance on building and maintaining a shared infrastructure library that provides common implementations for cross-cutting concerns across services.

---

## Overview

A shared infrastructure library is a reusable package that provides standardized implementations for infrastructure concerns, reducing code duplication and ensuring consistency across services.

### Benefits

| Benefit | Description |
|---------|-------------|
| **Consistency** | All services follow the same patterns and conventions |
| **Reduced Duplication** | Common code is written once, used everywhere |
| **Lower Maintenance** | Bug fixes and improvements benefit all services |
| **Faster Development** | New services start with proven infrastructure |
| **Standardized Observability** | Consistent logging, metrics, and tracing |
| **Knowledge Sharing** | Best practices encoded in library |

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| **Tight Coupling** | Keep library focused on infrastructure, not business logic |
| **Breaking Changes** | Use semantic versioning, deprecation periods |
| **One Size Fits All** | Provide extension points and configuration options |
| **Slow Evolution** | Maintain clear ownership and contribution guidelines |

---

## Library Structure

```
shared-infrastructure/
├── core/                      # Core abstractions and interfaces
│   ├── repository/            # Repository base classes and interfaces
│   ├── unit_of_work/          # Unit of work pattern
│   └── events/                # Event base classes
│
├── persistence/               # Database adapters
│   ├── sql/                   # SQL database adapters
│   ├── nosql/                 # NoSQL database adapters
│   └── caching/               # Caching implementations
│
├── messaging/                 # Message broker clients
│   ├── producer/              # Message producers
│   ├── consumer/              # Message consumers
│   └── serialization/         # Message serialization
│
├── http/                      # HTTP utilities
│   ├── client/                # HTTP client with resilience
│   └── middleware/            # Common middleware
│
├── observability/             # Logging, metrics, tracing
│   ├── logging/               # Structured logging
│   ├── metrics/               # Metrics collection
│   └── tracing/               # Distributed tracing
│
├── configuration/             # Configuration management
│   ├── loaders/               # Config loaders (env, file, etc.)
│   └── validation/            # Config validation
│
├── health/                    # Health check utilities
│   ├── checks/                # Health check implementations
│   └── endpoints/             # Health endpoint handlers
│
├── errors/                    # Error handling
│   ├── exceptions/            # Common exception types
│   └── responses/             # Error response formatting
│
└── security/                  # Security utilities
    ├── authentication/        # Auth utilities
    └── authorization/         # Authorization helpers
```

---

## Core Components

### Repository Pattern

Provide abstract repository classes that implement common data access patterns.

**Interface:**
```
interface Repository<Entity, Id>:
    method find_by_id(id: Id): Entity | None
    method find_all(): List<Entity>
    method find_by_criteria(criteria: Criteria): List<Entity>
    method save(entity: Entity): void
    method delete(entity: Entity): void
    method exists(id: Id): boolean
```

**Base Implementation:**
```
abstract class BaseRepository<Entity, Id> implements Repository<Entity, Id>:
    protected database_adapter: DatabaseAdapter
    
    // Common implementations
    method exists(id: Id): boolean:
        return find_by_id(id) is not None
    
    method save(entity: Entity): void:
        if exists(entity.id):
            update(entity)
        else:
            insert(entity)
    
    // Abstract methods for specific implementations
    abstract method map_to_entity(row: DatabaseRow): Entity
    abstract method map_to_row(entity: Entity): DatabaseRow
```

**Criteria Builder:**
```
class Criteria:
    method where(field: string, operator: string, value: any): Criteria
    method and_where(field: string, operator: string, value: any): Criteria
    method or_where(field: string, operator: string, value: any): Criteria
    method order_by(field: string, direction: string): Criteria
    method limit(count: int): Criteria
    method offset(count: int): Criteria

// Usage
criteria = Criteria()
    .where("status", "=", "active")
    .and_where("created_at", ">", last_week)
    .order_by("created_at", "desc")
    .limit(10)

users = user_repository.find_by_criteria(criteria)
```

### Unit of Work

Coordinate multiple repository operations in a single transaction.

```
interface UnitOfWork:
    method begin(): void
    method commit(): void
    method rollback(): void
    method register_new(entity: Entity): void
    method register_dirty(entity: Entity): void
    method register_deleted(entity: Entity): void

class DatabaseUnitOfWork implements UnitOfWork:
    method begin():
        database.begin_transaction()
    
    method commit():
        // Persist all registered changes
        for entity in new_entities:
            repository.insert(entity)
        for entity in dirty_entities:
            repository.update(entity)
        for entity in deleted_entities:
            repository.delete(entity)
        database.commit_transaction()
    
    method rollback():
        database.rollback_transaction()
        clear_registered_entities()
```

### Domain Events

Base classes for domain event publishing and handling.

```
abstract class DomainEvent:
    property event_id: UUID
    property occurred_at: DateTime
    property correlation_id: string
    
    constructor():
        event_id = generate_uuid()
        occurred_at = now()

interface EventPublisher:
    method publish(event: DomainEvent): void
    method publish_all(events: List<DomainEvent>): void

interface EventHandler<T extends DomainEvent>:
    method handle(event: T): void
```

---

## Database Adapters

### Connection Management

```
interface DatabaseAdapter:
    method connect(): Connection
    method disconnect(): void
    method execute(query: string, params: List): Result
    method begin_transaction(): Transaction
    method health_check(): HealthStatus

class DatabaseConfig:
    property host: string
    property port: int
    property database: string
    property username: string
    property password: string
    property pool_size: int = 10
    property connection_timeout: int = 30
    property retry_attempts: int = 3
```

### Transaction Management

```
class TransactionManager:
    method execute_in_transaction<T>(operation: () -> T): T:
        transaction = database.begin_transaction()
        try:
            result = operation()
            transaction.commit()
            return result
        except Exception as e:
            transaction.rollback()
            raise e
```

---

## Messaging

### Producer

```
interface MessageProducer:
    method send(topic: string, message: Message): void
    method send_batch(topic: string, messages: List<Message>): void

class Message:
    property id: string
    property payload: any
    property headers: Map<string, string>
    property timestamp: DateTime

class MessageProducerConfig:
    property broker_url: string
    property retry_attempts: int = 3
    property retry_delay_ms: int = 1000
    property timeout_ms: int = 5000
```

### Consumer

```
interface MessageConsumer:
    method subscribe(topic: string, handler: MessageHandler): void
    method unsubscribe(topic: string): void
    method start(): void
    method stop(): void

interface MessageHandler:
    method handle(message: Message): void
    method on_error(message: Message, error: Exception): void

class ConsumerConfig:
    property group_id: string
    property auto_commit: boolean = false
    property max_poll_records: int = 100
    property dead_letter_topic: string
```

---

## HTTP Client

### Resilient HTTP Client

```
class HttpClientConfig:
    property base_url: string
    property timeout_ms: int = 5000
    property retry_attempts: int = 3
    property retry_delay_ms: int = 1000
    property circuit_breaker_threshold: int = 5
    property circuit_breaker_timeout_ms: int = 30000

class ResilientHttpClient:
    property circuit_breaker: CircuitBreaker
    property retry_policy: RetryPolicy
    
    method get<T>(path: string, headers: Map): T
    method post<T>(path: string, body: any, headers: Map): T
    method put<T>(path: string, body: any, headers: Map): T
    method delete(path: string, headers: Map): void
    
    // Automatically applies:
    // - Timeout
    // - Retry with exponential backoff
    // - Circuit breaker
    // - Request/response logging
    // - Correlation ID propagation
```

### Circuit Breaker

```
class CircuitBreaker:
    property state: CircuitState  // CLOSED, OPEN, HALF_OPEN
    property failure_threshold: int
    property success_threshold: int
    property timeout_ms: int
    
    method execute<T>(operation: () -> T): T:
        if state == OPEN:
            if timeout_expired():
                state = HALF_OPEN
            else:
                raise CircuitOpenException()
        
        try:
            result = operation()
            record_success()
            return result
        except Exception as e:
            record_failure()
            raise e
```

---

## Observability

### Structured Logging

```
interface Logger:
    method debug(message: string, context: Map): void
    method info(message: string, context: Map): void
    method warn(message: string, context: Map): void
    method error(message: string, error: Exception, context: Map): void

class LogConfig:
    property level: LogLevel
    property format: string  // json, text
    property output: string  // stdout, file
    property include_caller: boolean = true
    property include_timestamp: boolean = true

// Standard log format
{
    "timestamp": "2024-01-15T10:30:00Z",
    "level": "INFO",
    "service": "order-service",
    "correlation_id": "abc-123",
    "message": "Order created",
    "context": {
        "order_id": "ord-456",
        "customer_id": "cust-789"
    }
}
```

### Metrics Collection

```
interface MetricsCollector:
    method counter(name: string, value: int, tags: Map): void
    method gauge(name: string, value: number, tags: Map): void
    method histogram(name: string, value: number, tags: Map): void
    method timer(name: string): Timer

// Standard metrics
- http_requests_total{method, path, status}
- http_request_duration_seconds{method, path}
- database_query_duration_seconds{operation, table}
- message_published_total{topic}
- message_consumed_total{topic, consumer_group}
- circuit_breaker_state{service}
```

### Distributed Tracing

```
interface Tracer:
    method start_span(name: string, parent: SpanContext): Span
    method inject(context: SpanContext, carrier: Map): void
    method extract(carrier: Map): SpanContext

class Span:
    property trace_id: string
    property span_id: string
    property parent_span_id: string
    property operation_name: string
    property start_time: DateTime
    property end_time: DateTime
    property tags: Map<string, string>
    property logs: List<LogEntry>
    
    method set_tag(key: string, value: string): void
    method log(message: string, fields: Map): void
    method finish(): void
```

---

## Configuration

### Configuration Loader

```
interface ConfigLoader:
    method load<T>(schema: ConfigSchema): T

class ConfigLoaderChain implements ConfigLoader:
    // Load from multiple sources with priority
    // 1. Environment variables (highest)
    // 2. Config file
    // 3. Default values (lowest)

class ConfigSchema:
    method define(key: string, type: Type, default: any, required: boolean)
    method validate(config: Map): ValidationResult

// Usage
schema = ConfigSchema()
    .define("DATABASE_HOST", string, "localhost", required=true)
    .define("DATABASE_PORT", int, 5432, required=false)
    .define("LOG_LEVEL", enum(DEBUG, INFO, WARN, ERROR), INFO, required=false)

config = ConfigLoaderChain()
    .add(EnvironmentLoader())
    .add(FileLoader("config.yaml"))
    .add(DefaultsLoader())
    .load(schema)
```

---

## Health Checks

### Health Check Framework

```
interface HealthCheck:
    property name: string
    method check(): HealthCheckResult

class HealthCheckResult:
    property status: HealthStatus  // UP, DOWN, DEGRADED
    property message: string
    property details: Map

class HealthCheckRegistry:
    method register(check: HealthCheck): void
    method check_all(): HealthReport
    method check_liveness(): HealthReport
    method check_readiness(): HealthReport

// Built-in checks
class DatabaseHealthCheck implements HealthCheck:
    method check(): HealthCheckResult:
        try:
            database.execute("SELECT 1")
            return HealthCheckResult(UP, "Database connection OK")
        except Exception as e:
            return HealthCheckResult(DOWN, e.message)

class MessageBrokerHealthCheck implements HealthCheck
class DiskSpaceHealthCheck implements HealthCheck
class MemoryHealthCheck implements HealthCheck
```

---

## Error Handling

### Common Exceptions

```
// Base exception
class InfrastructureException extends Exception:
    property code: string
    property details: Map

// Specific exceptions
class DatabaseException extends InfrastructureException
class ConnectionException extends DatabaseException
class QueryException extends DatabaseException

class MessagingException extends InfrastructureException
class PublishException extends MessagingException
class ConsumeException extends MessagingException

class HttpClientException extends InfrastructureException
class TimeoutException extends HttpClientException
class CircuitOpenException extends HttpClientException

class ConfigurationException extends InfrastructureException
class ValidationException extends InfrastructureException
```

### Error Response Formatting

```
class ErrorResponse:
    property error_code: string
    property message: string
    property details: Map
    property correlation_id: string
    property timestamp: DateTime

class ErrorResponseFactory:
    method create(exception: Exception, correlation_id: string): ErrorResponse:
        return ErrorResponse(
            error_code = map_to_error_code(exception),
            message = get_user_friendly_message(exception),
            details = extract_details(exception),
            correlation_id = correlation_id,
            timestamp = now()
        )

// Standard error response format
{
    "error": {
        "code": "DATABASE_CONNECTION_ERROR",
        "message": "Unable to process request. Please try again later.",
        "correlation_id": "abc-123-def-456",
        "timestamp": "2024-01-15T10:30:00Z"
    }
}
```

---

## Versioning Strategy

### Semantic Versioning

Follow semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Deprecation Policy

1. Mark deprecated features with warnings
2. Provide migration path in documentation
3. Support deprecated features for at least 2 minor versions
4. Remove in next major version

```
@deprecated("Use new_method() instead. Will be removed in v3.0.0")
method old_method(): void:
    log.warn("Deprecated method old_method() called")
    // Implementation
```

---

## Usage Guidelines

### When to Use the Shared Library

✅ **Use for:**
- Database connections and repositories
- Message broker clients
- HTTP client with resilience
- Logging and metrics
- Configuration loading
- Health checks
- Common error handling

❌ **Do NOT use for:**
- Business logic
- Domain models
- Service-specific configurations
- UI components
- API contracts

### Integration Example

```
// Service configuration
class OrderServiceConfig:
    property database: DatabaseConfig
    property messaging: MessageProducerConfig
    property http_client: HttpClientConfig
    property logging: LogConfig

// Service setup using shared library
class OrderService:
    constructor(config: OrderServiceConfig):
        // Use shared infrastructure components
        this.database = SharedInfrastructure.create_database(config.database)
        this.producer = SharedInfrastructure.create_producer(config.messaging)
        this.http_client = SharedInfrastructure.create_http_client(config.http_client)
        this.logger = SharedInfrastructure.create_logger(config.logging)
        
        // Register health checks
        health_registry.register(DatabaseHealthCheck(database))
        health_registry.register(MessageBrokerHealthCheck(producer))
```
