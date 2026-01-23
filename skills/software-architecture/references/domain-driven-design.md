# Domain Driven Design Reference

This document provides detailed explanations of Domain Driven Design (DDD) tactical and strategic patterns.

**Primary Reference**: Eric Evans, "Domain-Driven Design: Tackling Complexity in the Heart of Software"

---

## Overview

Domain Driven Design is an approach to software development that centers on the core domain and domain logic. It focuses on creating a shared understanding between technical and domain experts through a ubiquitous language.

| Aspect | Description |
|--------|-------------|
| **Strategic Design** | High-level patterns for organizing bounded contexts and their relationships |
| **Tactical Design** | Low-level patterns for modeling domain concepts within a bounded context |
| **Ubiquitous Language** | Shared vocabulary used consistently in code, documentation, and conversations |

---

## Strategic Patterns

### Bounded Context

A bounded context is an explicit boundary within which a particular domain model is defined and applicable. Different bounded contexts may have different models for the same real-world concept.

**Characteristics:**
- Explicit boundaries where a model applies
- Own ubiquitous language within the context
- Clear interfaces for communication with other contexts
- Typically aligned with team boundaries

**Example:**
```
E-Commerce System:
├── Sales Context
│   └── Customer = buyer with payment info, order history
├── Support Context
│   └── Customer = ticket requester with support history
└── Shipping Context
    └── Customer = recipient with shipping addresses
```

### Context Mapping

Context mapping defines the relationships between bounded contexts.

| Pattern | Description | Use When |
|---------|-------------|----------|
| **Shared Kernel** | Two contexts share a subset of the domain model | Teams closely collaborate |
| **Customer-Supplier** | Upstream context provides what downstream needs | Clear provider/consumer relationship |
| **Conformist** | Downstream conforms to upstream's model | No influence over upstream |
| **Anti-Corruption Layer** | Translation layer protects downstream model | Integrating with legacy or external systems |
| **Open Host Service** | Published API for multiple consumers | Many downstream contexts |
| **Published Language** | Well-documented shared language (e.g., JSON schema) | Multiple contexts need to integrate |
| **Separate Ways** | No integration between contexts | Integration cost exceeds benefit |
| **Partnership** | Contexts evolve together cooperatively | Mutual dependency, aligned goals |

### Anti-Corruption Layer (ACL)

An ACL is a translation layer that isolates your domain model from external models or legacy systems.

```
Your Bounded Context
├── Domain Model (clean)
├── Anti-Corruption Layer
│   ├── Translator (converts external to internal)
│   ├── Facade (simplifies external interface)
│   └── Adapter (implements internal interface)
└── External System (different model)
```

---

## Tactical Patterns

### Entities

Objects with a distinct identity that persists over time. Identity is what distinguishes one entity from another, not its attributes.

**Characteristics:**
- Unique identifier
- Mutable state
- Lifecycle (created, modified, deleted)
- Equality based on identity, not attributes

**Example:**
```
Entity: User
├── id: UUID (identity)
├── email: String (can change)
├── name: String (can change)
├── created_at: DateTime
└── equals(other): return this.id == other.id
```

### Value Objects

Immutable objects that describe aspects of the domain. They have no identity—two value objects with the same attributes are considered equal.

**Characteristics:**
- No identity (identity-less)
- Immutable
- Equality based on attributes
- Self-validating
- Side-effect free operations

**Example:**
```
Value Object: Money
├── amount: Decimal
├── currency: Currency
├── add(other: Money): Money (returns new instance)
├── equals(other): return this.amount == other.amount AND this.currency == other.currency
└── validate(): amount >= 0, currency is valid
```

**Common Value Objects:**
- Address, Email, PhoneNumber
- Money, Currency, Percentage
- DateRange, TimeSlot
- Coordinates, Distance
- Name, Description

### Aggregates

A cluster of entities and value objects with a defined boundary. The aggregate root is the entry point for all operations on the aggregate.

**Rules:**
1. Reference other aggregates by ID only
2. Changes within an aggregate are atomic
3. External objects can only hold references to the root
4. Only the root can be obtained from repositories
5. Aggregates should be small (prefer smaller aggregates)

**Example:**
```
Aggregate: Order (root)
├── order_id: OrderId
├── customer_id: CustomerId (reference by ID)
├── items: List<OrderItem> (entity, part of aggregate)
│   ├── product_id: ProductId (reference by ID)
│   ├── quantity: Quantity (value object)
│   └── price: Money (value object)
├── shipping_address: Address (value object)
├── status: OrderStatus (value object)
└── total(): Money

// OrderItem cannot be accessed directly, only through Order
```

### Domain Services

Operations that don't naturally belong to any entity or value object. They represent domain concepts that are verbs rather than nouns.

**Characteristics:**
- Stateless
- Defined in terms of the domain model
- Named using ubiquitous language
- Not CRUD operations (those belong in repositories)

**Example:**
```
Domain Service: TransferService
    method transfer(from: Account, to: Account, amount: Money):
        // Business logic for funds transfer
        // Involves multiple aggregates
        from.debit(amount)
        to.credit(amount)
        return TransferResult

Domain Service: PricingService
    method calculate_price(product: Product, customer: Customer): Money
        // Complex pricing logic involving multiple entities
```

### Repositories

Mechanisms for encapsulating storage, retrieval, and search behavior for aggregates. They provide a collection-like interface for accessing domain objects.

**Characteristics:**
- One repository per aggregate root
- Returns fully reconstituted aggregates
- Abstracts persistence mechanism
- Defined as interface in domain layer

**Interface Pattern:**
```
interface OrderRepository:
    method find_by_id(id: OrderId): Order | None
    method find_by_customer(customer_id: CustomerId): List<Order>
    method save(order: Order): void
    method delete(order: Order): void
    method next_identity(): OrderId
```

### Domain Events

Something significant that happened in the domain that domain experts care about. Events are immutable facts about what occurred.

**Characteristics:**
- Named in past tense (OrderPlaced, PaymentReceived)
- Immutable
- Contains relevant data at the time of occurrence
- Can trigger side effects in other bounded contexts

**Example:**
```
Domain Event: OrderPlaced
├── event_id: UUID
├── occurred_at: DateTime
├── order_id: OrderId
├── customer_id: CustomerId
├── items: List<OrderItemSnapshot>
└── total: Money

// Handlers in other contexts can react to this event
```

### Factories

Encapsulate complex object creation logic. Use when constructing an aggregate is complex or involves business rules.

**When to Use:**
- Creation logic is complex
- Multiple ways to create the same type
- Creation involves invariant validation
- Need to hide implementation details

**Example:**
```
Factory: OrderFactory
    method create_order(customer: Customer, items: List<CartItem>): Order
        // Validate customer can place orders
        // Apply business rules for order creation
        // Create Order aggregate with valid state
        
    method reconstitute(data: OrderData): Order
        // Rebuild Order from persistence data
```

---

## Ubiquitous Language

The ubiquitous language is a shared vocabulary that is:
- Used by developers and domain experts
- Reflected in the code (class names, method names)
- Documented and evolved continuously
- Specific to each bounded context

**Building the Language:**

| Activity | Purpose |
|----------|---------|
| Domain expert interviews | Discover terminology and concepts |
| Event storming | Identify events, commands, and aggregates |
| Example mapping | Clarify rules and edge cases |
| Glossary maintenance | Document and share definitions |
| Code review | Ensure code reflects the language |

**Example Glossary Entry:**
```
Term: Order
Context: Sales
Definition: A confirmed request from a customer to purchase products
Attributes: customer, items, shipping address, status
States: Pending, Confirmed, Shipped, Delivered, Cancelled
Related: OrderItem, Customer, Product
```

---

## Event Storming

A workshop technique for exploring complex domains by focusing on domain events.

**Process:**
1. **Domain Events**: Identify events (orange stickies)
2. **Commands**: What triggers events (blue stickies)
3. **Aggregates**: Group events around aggregates (yellow stickies)
4. **Bounded Contexts**: Identify context boundaries
5. **Policies**: Identify reactive logic (purple stickies)
6. **Read Models**: Identify query needs (green stickies)

**Outcome:**
- Shared understanding of the domain
- Identified bounded contexts
- Draft aggregate design
- Event flow visualization

---

## Implementation Guidelines

### Layer Organization

```
domain/
├── model/
│   ├── entities/           # Entity classes
│   ├── value_objects/      # Value object classes
│   └── aggregates/         # Aggregate roots
├── services/               # Domain services
├── events/                 # Domain event definitions
├── repositories/           # Repository interfaces (ports)
├── factories/              # Factory interfaces/implementations
└── exceptions/             # Domain-specific exceptions
```

### Naming Conventions

| Concept | Convention | Example |
|---------|------------|---------|
| Entity | Noun | `User`, `Order`, `Product` |
| Value Object | Noun (descriptive) | `Money`, `Address`, `EmailAddress` |
| Aggregate | Root entity name | `Order` (contains `OrderItem`) |
| Repository | Entity + Repository | `OrderRepository`, `UserRepository` |
| Domain Service | Action + Service | `TransferService`, `PricingService` |
| Domain Event | Past tense | `OrderPlaced`, `PaymentReceived` |
| Factory | Entity + Factory | `OrderFactory`, `UserFactory` |

### Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Anemic Domain Model | Entities with only getters/setters | Put behavior in entities |
| God Aggregate | Too many entities in one aggregate | Split into smaller aggregates |
| Repository per Entity | Repositories for non-root entities | One repository per aggregate root |
| Leaking Domain Logic | Business rules in services/controllers | Keep logic in domain layer |
| Ignoring Bounded Contexts | One model for entire system | Define explicit boundaries |
