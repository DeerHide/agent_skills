# Clean Architecture Reference

This document provides detailed explanations of Clean Architecture principles, layer responsibilities, and implementation patterns.

**Primary Reference**: Robert C. Martin, "Clean Architecture: A Craftsman's Guide to Software Structure and Design"

---

## Overview

Clean Architecture is a software design philosophy that organizes code into concentric layers with strict dependency rules. The core principle is that dependencies should point inward—outer layers depend on inner layers, never the reverse.

```
┌─────────────────────────────────────────────────────────────┐
│                    Frameworks & Drivers                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 Interface Adapters                   │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │              Application Layer               │    │    │
│  │  │  ┌─────────────────────────────────────┐    │    │    │
│  │  │  │           Domain Layer              │    │    │    │
│  │  │  │         (Entities/Core)             │    │    │    │
│  │  │  └─────────────────────────────────────┘    │    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘

Dependencies flow INWARD →
```

---

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Dependency Rule** | Source code dependencies must point inward toward higher-level policies |
| **Independence of Frameworks** | Architecture doesn't depend on feature-laden frameworks |
| **Testability** | Business rules can be tested without UI, database, or external elements |
| **Independence of UI** | UI can change without affecting business rules |
| **Independence of Database** | Business rules aren't bound to a specific database |
| **Independence of External Agencies** | Business rules don't know about external interfaces |

---

## Layer Responsibilities

### Domain Layer (Entities)

The innermost layer containing enterprise-wide business rules and domain models. This layer has no dependencies on any other layer.

**Contains:**
- Entities (business objects with identity)
- Value Objects (immutable domain concepts)
- Domain Services (stateless operations)
- Domain Events
- Repository Interfaces (ports)
- Domain Exceptions

**Rules:**
- No framework dependencies
- No infrastructure concerns (no database, HTTP, etc.)
- Pure business logic only
- Can be shared across applications

**Example Structure:**
```
domain/
├── entities/
│   ├── user.ext
│   └── order.ext
├── value_objects/
│   ├── money.ext
│   └── email.ext
├── services/
│   └── pricing_service.ext
├── events/
│   └── order_placed.ext
├── ports/
│   └── user_repository.ext (interface)
└── exceptions/
    └── domain_exception.ext
```

### Application Layer (Use Cases)

Contains application-specific business rules. Orchestrates the flow of data to and from entities and directs them to use their enterprise-wide business rules.

**Contains:**
- Use Cases / Interactors (application-specific logic)
- Input/Output Ports (interfaces)
- Data Transfer Objects (DTOs)
- Application Services
- Command/Query handlers

**Rules:**
- Depends only on Domain layer
- No knowledge of delivery mechanism (HTTP, CLI, etc.)
- No knowledge of persistence mechanism
- Orchestrates domain objects to fulfill use cases

**Example Structure:**
```
application/
├── use_cases/
│   ├── create_order/
│   │   ├── create_order_use_case.ext
│   │   ├── create_order_input.ext
│   │   └── create_order_output.ext
│   └── get_user/
│       ├── get_user_use_case.ext
│       └── get_user_output.ext
├── ports/
│   ├── input/
│   │   └── create_order_port.ext (interface)
│   └── output/
│       ├── user_repository_port.ext (interface)
│       └── notification_port.ext (interface)
├── services/
│   └── order_service.ext
└── dto/
    └── order_dto.ext
```

### Interface Adapters Layer

Converts data from the format most convenient for use cases and entities to the format most convenient for external agencies (database, web, etc.).

**Contains:**
- Controllers (web, CLI)
- Presenters (format output)
- Gateways (abstract external services)
- Repository Implementations
- Mappers (data conversion)

**Rules:**
- Depends on Application and Domain layers
- No knowledge of specific frameworks
- Adapts between internal and external formats

**Example Structure:**
```
adapters/
├── controllers/
│   ├── order_controller.ext
│   └── user_controller.ext
├── presenters/
│   ├── json_presenter.ext
│   └── html_presenter.ext
├── gateways/
│   └── payment_gateway.ext
├── repositories/
│   └── sql_user_repository.ext (implements port)
└── mappers/
    └── order_mapper.ext
```

### Infrastructure Layer (Frameworks & Drivers)

The outermost layer containing frameworks, tools, and delivery mechanisms. This is where all the details live.

**Contains:**
- Web Frameworks
- Database Implementations
- External Service Clients
- Configuration
- Dependency Injection Setup
- Logging Implementation

**Rules:**
- Depends on all inner layers
- Contains framework-specific code
- Implements interfaces defined in inner layers
- Handles technical concerns (caching, logging, etc.)

**Example Structure:**
```
infrastructure/
├── web/
│   ├── routes.ext
│   └── middleware.ext
├── persistence/
│   ├── database_config.ext
│   ├── orm_models/
│   │   └── user_model.ext
│   └── migrations/
├── external/
│   ├── stripe_client.ext
│   └── sendgrid_client.ext
├── config/
│   └── app_config.ext
├── di/
│   └── container.ext
└── logging/
    └── logger.ext
```

---

## Dependency Inversion with Ports and Adapters

The key to maintaining the dependency rule is using interfaces (ports) and their implementations (adapters).

### Port Definition (in Application Layer)

```
// application/ports/output/user_repository_port.ext
interface UserRepositoryPort:
    method find_by_id(id: UserId): User | None
    method find_by_email(email: Email): User | None
    method save(user: User): void
    method delete(user: User): void
```

### Adapter Implementation (in Infrastructure Layer)

```
// infrastructure/persistence/sql_user_repository.ext
class SqlUserRepository implements UserRepositoryPort:
    constructor(database: Database):
        this.db = database
    
    method find_by_id(id: UserId): User | None:
        row = db.query("SELECT * FROM users WHERE id = ?", id)
        if row is None:
            return None
        return UserMapper.to_domain(row)
    
    method save(user: User): void:
        model = UserMapper.to_persistence(user)
        db.save(model)
```

### Use Case Using Port (in Application Layer)

```
// application/use_cases/get_user_use_case.ext
class GetUserUseCase:
    constructor(user_repository: UserRepositoryPort):  // Depends on interface
        this.user_repository = user_repository
    
    method execute(user_id: UserId): UserOutput:
        user = user_repository.find_by_id(user_id)
        if user is None:
            raise UserNotFoundException(user_id)
        return UserOutput.from_user(user)
```

---

## Data Flow

### Request Flow (Outside → Inside)

```
HTTP Request
    ↓
Controller (parse request, create input DTO)
    ↓
Use Case (business logic, calls domain)
    ↓
Domain (entities, value objects, business rules)
    ↓
Repository Port (interface call)
    ↓
Repository Adapter (persistence operation)
    ↓
Database
```

### Response Flow (Inside → Outside)

```
Database
    ↓
Repository Adapter (reconstruct domain object)
    ↓
Repository Port (returns domain object)
    ↓
Domain (domain object)
    ↓
Use Case (creates output DTO)
    ↓
Presenter (formats for delivery)
    ↓
Controller (HTTP response)
    ↓
HTTP Response
```

---

## Testing Strategy

Clean Architecture enables effective testing at each layer:

| Layer | Test Type | Dependencies |
|-------|-----------|--------------|
| Domain | Unit Tests | None (pure logic) |
| Application | Unit Tests | Mocked ports |
| Interface Adapters | Integration Tests | Mocked external services |
| Infrastructure | Integration/E2E Tests | Real external services |

### Example Test Structure

```
tests/
├── unit/
│   ├── domain/
│   │   ├── test_user_entity.ext
│   │   └── test_money_value_object.ext
│   └── application/
│       └── test_create_order_use_case.ext
├── integration/
│   ├── adapters/
│   │   └── test_sql_user_repository.ext
│   └── infrastructure/
│       └── test_stripe_payment_gateway.ext
└── e2e/
    └── test_order_workflow.ext
```

---

## Common Patterns

### Use Case Pattern

```
class CreateOrderUseCase:
    constructor(
        order_repository: OrderRepositoryPort,
        payment_gateway: PaymentGatewayPort,
        notification_service: NotificationPort
    ):
        // Inject dependencies
    
    method execute(input: CreateOrderInput): CreateOrderOutput:
        // 1. Validate input
        validated = validate(input)
        
        // 2. Execute business logic
        order = Order.create(validated.customer_id, validated.items)
        
        // 3. Persist through port
        order_repository.save(order)
        
        // 4. Side effects through ports
        payment_gateway.charge(order.total)
        notification_service.send_confirmation(order)
        
        // 5. Return output DTO
        return CreateOrderOutput.from_order(order)
```

### Input/Output DTOs

```
// Input DTO (what comes from outside)
class CreateOrderInput:
    customer_id: string
    items: List<OrderItemInput>
    shipping_address: AddressInput
    
    method validate(): ValidationResult

// Output DTO (what goes outside)
class CreateOrderOutput:
    order_id: string
    status: string
    total: decimal
    created_at: datetime
    
    static method from_order(order: Order): CreateOrderOutput
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| **Leaking Infrastructure** | Database models used in domain | Separate domain and persistence models |
| **Anemic Use Cases** | Use cases that just call repositories | Put orchestration logic in use cases |
| **Fat Controllers** | Business logic in controllers | Move logic to use cases |
| **Skipping Layers** | Controller directly calls repository | Always go through use cases |
| **Bidirectional Dependencies** | Inner layer imports from outer layer | Use dependency inversion |
| **Shared DTOs** | Same DTO for input, output, persistence | Create layer-specific DTOs |
| **Framework Coupling** | Domain depends on web framework | Keep domain pure |

---

## Comparison with Related Architectures

| Architecture | Focus | Layers |
|--------------|-------|--------|
| **Clean Architecture** | Dependency rules, independence | Entities, Use Cases, Adapters, Frameworks |
| **Hexagonal (Ports & Adapters)** | Ports and adapters, testability | Core, Ports (interfaces), Adapters |
| **Onion Architecture** | Concentric layers, domain at center | Domain, Domain Services, Application, Infrastructure |

All three architectures share the same core principle: **dependencies point inward, and the domain is at the center**.
