# SOLID Principles Reference

This document provides detailed explanations, examples, and anti-patterns for each SOLID principle.

**Primary Reference**: Robert C. Martin, "Clean Architecture" and "Agile Software Development, Principles, Patterns, and Practices"

---

## Overview

SOLID is an acronym for five design principles intended to make software designs more understandable, flexible, and maintainable.

| Principle | Full Name | Key Benefit |
|-----------|-----------|-------------|
| S | Single Responsibility | Reduces coupling, improves cohesion |
| O | Open/Closed | Enables extension without modification |
| L | Liskov Substitution | Ensures correct inheritance hierarchies |
| I | Interface Segregation | Prevents interface pollution |
| D | Dependency Inversion | Decouples high-level from low-level modules |

---

## Single Responsibility Principle (SRP)

> "A class should have only one reason to change."

A class or module should have one, and only one, responsibility. This responsibility should be entirely encapsulated by the class.

### Benefits

| Benefit | Description |
|---------|-------------|
| Easier testing | Fewer test cases needed per class |
| Lower coupling | Changes in one area don't affect others |
| Better organization | Code is easier to locate and understand |
| Simplified maintenance | Smaller, focused classes are easier to modify |

### Example

**Violation:**
```
class UserService:
    method create_user(data):
        // Validate input
        // Hash password
        // Save to database
        // Send welcome email
        // Log the action
```

**Corrected:**
```
class UserValidator:
    method validate(data): ...

class PasswordHasher:
    method hash(password): ...

class UserRepository:
    method save(user): ...

class EmailService:
    method send_welcome_email(user): ...

class UserService:
    constructor(validator, hasher, repository, emailService):
        // Inject dependencies
    
    method create_user(data):
        validated = validator.validate(data)
        hashed = hasher.hash(validated.password)
        user = repository.save(validated, hashed)
        emailService.send_welcome_email(user)
        return user
```

### Anti-Patterns

- **God Class**: A class that does everything and knows too much
- **Utility Dumping Ground**: A class that accumulates unrelated helper methods
- **Mixed Concerns**: Business logic mixed with infrastructure concerns

---

## Open/Closed Principle (OCP)

> "Software entities should be open for extension, but closed for modification."

You should be able to extend a class's behavior without modifying its existing code. This is typically achieved through abstraction and polymorphism.

### Benefits

| Benefit | Description |
|---------|-------------|
| Stability | Existing code remains unchanged |
| Extensibility | New behavior can be added easily |
| Reduced risk | No regression in existing functionality |
| Better testing | New features can be tested in isolation |

### Example

**Violation:**
```
class DiscountCalculator:
    method calculate(order, customer_type):
        if customer_type == "regular":
            return order.total * 0.0
        else if customer_type == "premium":
            return order.total * 0.1
        else if customer_type == "vip":
            return order.total * 0.2
        // Adding new customer types requires modifying this class
```

**Corrected:**
```
interface DiscountStrategy:
    method calculate(order): decimal

class RegularDiscount implements DiscountStrategy:
    method calculate(order):
        return order.total * 0.0

class PremiumDiscount implements DiscountStrategy:
    method calculate(order):
        return order.total * 0.1

class VipDiscount implements DiscountStrategy:
    method calculate(order):
        return order.total * 0.2

class DiscountCalculator:
    method calculate(order, strategy: DiscountStrategy):
        return strategy.calculate(order)

// New customer types can be added without modifying DiscountCalculator
```

### Anti-Patterns

- **Switch/If Chains**: Long conditional chains based on type
- **Magic Strings/Numbers**: Using literals to determine behavior
- **Hardcoded Dependencies**: Direct instantiation instead of injection

---

## Liskov Substitution Principle (LSP)

> "Subtypes must be substitutable for their base types."

If class B is a subtype of class A, then objects of type A should be replaceable with objects of type B without altering the correctness of the program.

### Benefits

| Benefit | Description |
|---------|-------------|
| Correct polymorphism | Subtypes behave as expected |
| Safe refactoring | Base types can be swapped safely |
| Design validation | Reveals incorrect inheritance hierarchies |
| Code reuse | Enables proper use of inheritance |

### Example

**Violation:**
```
class Rectangle:
    property width
    property height
    
    method set_width(w): width = w
    method set_height(h): height = h
    method area(): return width * height

class Square extends Rectangle:
    method set_width(w):
        width = w
        height = w  // Violates LSP - unexpected side effect
    
    method set_height(h):
        width = h  // Violates LSP - unexpected side effect
        height = h

// Client code expects Rectangle behavior
function resize(rect: Rectangle):
    rect.set_width(5)
    rect.set_height(10)
    assert rect.area() == 50  // Fails for Square!
```

**Corrected:**
```
interface Shape:
    method area(): decimal

class Rectangle implements Shape:
    constructor(width, height): ...
    method area(): return width * height

class Square implements Shape:
    constructor(side): ...
    method area(): return side * side

// Square is not a subtype of Rectangle - they share a common interface
```

### Anti-Patterns

- **Throwing Exceptions in Overrides**: Subtype throws where base type doesn't
- **Weakening Postconditions**: Subtype returns less than promised
- **Strengthening Preconditions**: Subtype requires more than base type
- **Breaking Invariants**: Subtype violates base type's invariants

---

## Interface Segregation Principle (ISP)

> "Clients should not be forced to depend on interfaces they do not use."

Many client-specific interfaces are better than one general-purpose interface. Split large interfaces into smaller, more specific ones.

### Benefits

| Benefit | Description |
|---------|-------------|
| Reduced coupling | Clients depend only on what they use |
| Easier implementation | Smaller interfaces are simpler to implement |
| Better cohesion | Interfaces represent focused capabilities |
| Flexible composition | Clients can pick relevant interfaces |

### Example

**Violation:**
```
interface Worker:
    method work()
    method eat()
    method sleep()
    method attendMeeting()
    method writeReport()

class Robot implements Worker:
    method work(): // OK
    method eat(): throw NotImplemented  // Robots don't eat
    method sleep(): throw NotImplemented  // Robots don't sleep
    method attendMeeting(): // OK
    method writeReport(): // OK
```

**Corrected:**
```
interface Workable:
    method work()

interface Feedable:
    method eat()

interface Restable:
    method sleep()

interface Meetable:
    method attendMeeting()

interface Reportable:
    method writeReport()

class Human implements Workable, Feedable, Restable, Meetable, Reportable:
    // Implements all methods

class Robot implements Workable, Meetable, Reportable:
    // Only implements relevant methods
```

### Anti-Patterns

- **Fat Interfaces**: Interfaces with too many methods
- **Forced Implementation**: Empty or exception-throwing implementations
- **God Interface**: Single interface for all capabilities
- **Header Interfaces**: Copying class methods verbatim to interface

---

## Dependency Inversion Principle (DIP)

> "High-level modules should not depend on low-level modules. Both should depend on abstractions."
> "Abstractions should not depend on details. Details should depend on abstractions."

This principle is the foundation of dependency injection and inversion of control.

### Benefits

| Benefit | Description |
|---------|-------------|
| Loose coupling | Modules are independent of implementations |
| Testability | Dependencies can be mocked easily |
| Flexibility | Implementations can be swapped |
| Maintainability | Changes in low-level modules don't affect high-level |

### Example

**Violation:**
```
class MySqlDatabase:
    method query(sql): ...
    method save(data): ...

class UserRepository:
    property database = new MySqlDatabase()  // Direct dependency
    
    method find_user(id):
        return database.query("SELECT * FROM users WHERE id = " + id)
```

**Corrected:**
```
interface Database:
    method query(sql)
    method save(data)

class MySqlDatabase implements Database:
    method query(sql): ...
    method save(data): ...

class PostgresDatabase implements Database:
    method query(sql): ...
    method save(data): ...

class UserRepository:
    property database: Database
    
    constructor(database: Database):  // Dependency injection
        this.database = database
    
    method find_user(id):
        return database.query("SELECT * FROM users WHERE id = " + id)

// Usage
mysql = new MySqlDatabase()
repo = new UserRepository(mysql)

// Or swap implementation
postgres = new PostgresDatabase()
repo = new UserRepository(postgres)
```

### Anti-Patterns

- **New is Glue**: Direct instantiation creates tight coupling
- **Service Locator Abuse**: Hiding dependencies behind a locator
- **Concrete Dependencies**: Depending on implementations instead of interfaces
- **Circular Dependencies**: Module A depends on B, B depends on A

---

## Applying SOLID Together

The SOLID principles work best when applied together. Here's how they complement each other:

| Combination | Synergy |
|-------------|---------|
| SRP + ISP | Small, focused classes implement small, focused interfaces |
| OCP + DIP | Abstractions enable extension without modification |
| LSP + DIP | Correct abstractions ensure substitutability |
| ISP + DIP | Segregated interfaces make dependency injection cleaner |
| SRP + OCP | Single responsibility makes extension points clearer |

### Warning Signs

Watch for these indicators that SOLID principles may be violated:

- Classes with many dependencies (> 5-7)
- Long methods or classes (> 200-300 lines)
- Frequent changes to existing classes for new features
- Difficulty writing unit tests
- Inheritance hierarchies deeper than 2-3 levels
- Methods with boolean flags that change behavior
- Catch-all exception handling
