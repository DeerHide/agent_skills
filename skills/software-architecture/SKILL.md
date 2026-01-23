---
name: software-architecture
description: Best practices and principles for designing robust software architectures including SOLID, DRY, KISS, YAGNI, DDD, Clean Architecture, and Microservices.
metadata:
  author: Deerhide
  version: 1.1.0
---
# Software Architecture

## When to use this skill?

- Use this skill when designing a new software system or application from scratch.
- Use this skill when refactoring an existing codebase to improve maintainability and scalability.
- Use this skill when evaluating architectural decisions and trade-offs.
- Use this skill when establishing coding standards and guidelines for a team.
- Use this skill when reviewing code for adherence to architectural principles.
- Use this skill when splitting a monolith into services or defining service boundaries.

---

## Overview

Software architecture refers to the high-level structure of a software system, encompassing the organization of its components, their interactions, and the guiding principles that dictate design decisions. A well-defined architecture is crucial for ensuring scalability, maintainability, and performance of software applications.

---

## Foundational Principles

These principles form the foundation of good software design and should guide all architectural decisions.

### SOLID Principles

SOLID is an acronym for five design principles that promote maintainable and extensible software.

| Principle | Description |
|-----------|-------------|
| **S**ingle Responsibility | A class should have only one reason to change |
| **O**pen/Closed | Software entities should be open for extension, closed for modification |
| **L**iskov Substitution | Subtypes must be substitutable for their base types |
| **I**nterface Segregation | Clients should not depend on interfaces they don't use |
| **D**ependency Inversion | Depend on abstractions, not concretions |

> See [references/solid-principles.md](references/solid-principles.md) for detailed explanations and examples.

### DRY (Don't Repeat Yourself)

Every piece of knowledge must have a single, unambiguous, authoritative representation within a system. Duplication leads to inconsistency and increases maintenance burden.

**Apply DRY to:**
- Business logic and rules
- Configuration and constants
- Data schemas and validation

**Avoid over-applying DRY when:**
- Abstractions become forced or unclear
- Coupling increases between unrelated components
- Code becomes harder to understand

### KISS (Keep It Simple, Stupid)

The simplest solution that works is often the best. Complexity should only be introduced when it provides clear value.

**Guidelines:**
- Prefer straightforward implementations over clever ones
- Avoid premature optimization
- Use well-known patterns instead of inventing new ones
- Write code that is easy to read and understand

### YAGNI (You Ain't Gonna Need It)

Don't implement functionality until it is actually needed. Speculative features add complexity and maintenance burden without providing immediate value.

**Guidelines:**
- Implement features based on current requirements
- Avoid building for hypothetical future needs
- Refactor when new requirements emerge
- Focus on delivering working software incrementally

---

## Domain Driven Design (DDD)

Domain Driven Design (DDD) is an approach to software development that emphasizes the importance of the domain and domain logic. It encourages collaboration between technical and domain experts to create a shared understanding of the problem space, leading to more effective solutions.

> See [references/domain-driven-design.md](references/domain-driven-design.md) for detailed patterns and implementation guidance.

### Key Concepts of DDD

| Concept | Description |
|---------|-------------|
| **Ubiquitous Language** | A common language shared by developers and domain experts to ensure clear communication |
| **Entities** | Objects that have a distinct identity and lifecycle |
| **Value Objects** | Immutable objects that represent descriptive aspects of the domain |
| **Aggregates** | Clusters of related entities and value objects treated as a single unit |
| **Repositories** | Mechanisms for accessing and persisting aggregates |
| **Services** | Operations that do not naturally fit within entities or value objects |
| **Bounded Contexts** | Explicit boundaries within which a particular model is defined and applicable |
| **Use Cases** | Specific scenarios that describe how users interact with the system to achieve a goal |

---

## Clean Architecture

Clean Architecture is a software design philosophy that promotes separation of concerns and independence of frameworks, databases, and user interfaces. It advocates for organizing code into layers, with the core business logic at the center, ensuring that the system remains flexible and maintainable.

> See [references/clean-architecture.md](references/clean-architecture.md) for detailed layer responsibilities and implementation patterns.

### Principles of Clean Architecture

- **Independence of Frameworks**: The architecture should not depend on any specific framework, allowing for easy replacement or upgrades.
- **Testability**: The design should facilitate unit testing and integration testing.
- **Independence of UI**: The user interface should be decoupled from the business logic.
- **Independence of Database**: The business rules should not depend on the database, allowing for easy changes in data storage solutions.
- **Separation of Concerns**: Each layer should have a distinct responsibility, reducing complexity and improving maintainability.

### Layers of Clean Architecture

| Layer | Responsibility | Dependencies |
|-------|----------------|--------------|
| **Domain (Entities)** | Business rules, domain models, domain services | None (innermost) |
| **Application (Use Cases)** | Application-specific business rules, orchestration | Domain only |
| **Interface Adapters** | Convert data between use cases and external formats | Application, Domain |
| **Infrastructure (Frameworks & Drivers)** | Frameworks, databases, external tools | All inner layers |

### Generic Project Structure

```
project/
├── domain/                    # Core business logic (innermost layer)
│   ├── entities/              # Domain entities with identity
│   ├── value_objects/         # Immutable domain concepts
│   ├── aggregates/            # Aggregate roots and boundaries
│   ├── services/              # Domain services
│   ├── events/                # Domain events
│   └── exceptions/            # Domain-specific exceptions
│
├── application/               # Application business rules
│   ├── use_cases/             # Application use cases / interactors
│   ├── ports/                 # Input/output port interfaces
│   │   ├── input/             # Primary/driving ports
│   │   └── output/            # Secondary/driven ports (repositories, etc.)
│   ├── services/              # Application services
│   └── dto/                   # Data transfer objects
│
├── infrastructure/            # External concerns implementation
│   ├── persistence/           # Database implementations
│   │   ├── repositories/      # Repository implementations
│   │   └── models/            # ORM/database models
│   ├── messaging/             # Message queue implementations
│   ├── external_services/     # Third-party service clients
│   ├── configuration/         # Configuration management
│   └── logging/               # Logging implementation
│
├── interfaces/                # Entry points to the application
│   ├── api/                   # REST/GraphQL controllers
│   ├── cli/                   # Command-line interfaces
│   ├── events/                # Event handlers/consumers
│   └── jobs/                  # Background job handlers
│
└── shared/                    # Cross-cutting concerns
    ├── kernel/                # Shared kernel (if using DDD)
    └── utils/                 # Utility functions
```

---

## Microservices Architecture

Microservices Architecture is an architectural style that structures an application as a collection of small, autonomous services that communicate over well-defined APIs. Each service is responsible for a specific business capability, allowing for independent development, deployment, and scaling.

> See [references/microservices.md](references/microservices.md) for communication patterns, resilience strategies, and implementation details.

### Key Characteristics of Microservices

| Characteristic | Description |
|----------------|-------------|
| **Service Autonomy** | Each microservice can be developed, deployed, and scaled independently |
| **Decentralized Data Management** | Each service manages its own database, promoting data encapsulation |
| **Resilience** | The architecture is designed to handle failures gracefully, with services able to recover independently |
| **Continuous Delivery** | Microservices facilitate continuous integration and deployment, allowing for rapid updates and iterations |
| **Shared Infrastructure Library** | Common cross-cutting concerns are provided by a shared library to reduce maintenance overhead |

### Shared Infrastructure Library

To reduce maintenance costs and ensure consistency across services, use a **shared infrastructure library** that provides common implementations for cross-cutting concerns.

> See [references/shared-infrastructure-library.md](references/shared-infrastructure-library.md) for detailed implementation patterns.

| Component | Purpose |
|-----------|---------|
| **Repository Base Classes** | Abstract repository implementations for common data access patterns |
| **Database Adapters** | Standardized database connection and transaction management |
| **Messaging Clients** | Unified interface for message queue producers and consumers |
| **Logging & Tracing** | Consistent logging format and distributed tracing integration |
| **Configuration Management** | Centralized configuration loading and validation |
| **Health Checks** | Standardized health and readiness endpoints |
| **Error Handling** | Common exception types and error response formatting |

### Best Practices for Microservices

- **Define Clear Boundaries**: Each microservice should have a well-defined purpose and scope aligned with bounded contexts.
- **Use Shared Infrastructure**: Leverage a common library for repositories, adapters, and cross-cutting concerns to reduce duplication and maintenance.
- **Standardize Technology Stack**: Use a consistent technology stack across services to simplify operations and knowledge sharing.
- **Monitor and Log**: Implement comprehensive monitoring and logging to track the health and performance of microservices.
- **Automate Deployment**: Use containerization and orchestration tools to automate the deployment and scaling of microservices.
- **Design for Failure**: Implement circuit breakers, retries, and fallbacks to handle service failures gracefully.

---

## References

| Document | Description |
|----------|-------------|
| [solid-principles.md](references/solid-principles.md) | Detailed SOLID principles with examples and anti-patterns |
| [domain-driven-design.md](references/domain-driven-design.md) | DDD tactical and strategic patterns |
| [clean-architecture.md](references/clean-architecture.md) | Layer responsibilities and dependency rules |
| [microservices.md](references/microservices.md) | Communication patterns and resilience strategies |
| [shared-infrastructure-library.md](references/shared-infrastructure-library.md) | Shared library patterns for infrastructure concerns |
