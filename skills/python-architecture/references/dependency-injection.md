# Dependency Injection in Python

## Overview

Dependency Injection (DI) is a design pattern where objects receive their dependencies from external sources rather than creating them internally. This promotes loose coupling, testability, and adherence to SOLID principles (particularly the Dependency Inversion Principle).

---

## Dependency Inversion Principle (DIP)

The Dependency Inversion Principle is the "D" in SOLID principles. It states:

> 1. **High-level modules should not depend on low-level modules.** Both should depend on abstractions.
> 2. **Abstractions should not depend on details.** Details should depend on abstractions.

### Without Dependency Inversion

```
┌─────────────────────┐
│   UserService       │  High-level module
│   (Business Logic)  │
└─────────┬───────────┘
          │ depends on
          ▼
┌─────────────────────┐
│  PostgresRepository │  Low-level module
│  (Data Access)      │
└─────────────────────┘
```

```python
# ❌ High-level module depends directly on low-level module
class PostgresRepository:
    def save(self, data: dict):
        # PostgreSQL-specific implementation
        pass

class UserService:
    def __init__(self):
        self.repository = PostgresRepository()  # Direct dependency
    
    def create_user(self, name: str):
        self.repository.save({"name": name})
```

**Problems:**
- `UserService` cannot work without `PostgresRepository`
- Changing database requires modifying `UserService`
- Testing requires a real PostgreSQL database

### With Dependency Inversion

```
┌─────────────────────┐
│   UserService       │  High-level module
│   (Business Logic)  │
└─────────┬───────────┘
          │ depends on
          ▼
┌─────────────────────┐
│ RepositoryInterface │  Abstraction (owned by high-level)
│     (Abstract)      │
└─────────▲───────────┘
          │ implements
          │
┌─────────┴───────────┐
│  PostgresRepository │  Low-level module
│  (Data Access)      │
└─────────────────────┘
```

```python
from abc import ABC, abstractmethod

# ✅ Abstraction - owned by the high-level module
class RepositoryInterface(ABC):
    @abstractmethod
    def save(self, data: dict) -> None:
        pass
    
    @abstractmethod
    def find_by_id(self, id: str) -> dict | None:
        pass

# ✅ High-level module depends on abstraction
class UserService:
    def __init__(self, repository: RepositoryInterface):
        self.repository = repository
    
    def create_user(self, name: str):
        self.repository.save({"name": name})

# ✅ Low-level module implements abstraction
class PostgresRepository(RepositoryInterface):
    def save(self, data: dict) -> None:
        # PostgreSQL-specific implementation
        pass
    
    def find_by_id(self, id: str) -> dict | None:
        # PostgreSQL-specific implementation
        pass

# ✅ Easy to swap implementations
class MongoRepository(RepositoryInterface):
    def save(self, data: dict) -> None:
        # MongoDB-specific implementation
        pass
    
    def find_by_id(self, id: str) -> dict | None:
        # MongoDB-specific implementation
        pass
```

### DIP vs DI: Understanding the Difference

| Concept | Type | Purpose |
|---------|------|---------|
| **Dependency Inversion Principle** | Design Principle | Defines *what* the relationship between modules should be |
| **Dependency Injection** | Design Pattern | Provides *how* to achieve loose coupling |

- **DIP** tells us to depend on abstractions, not concretions
- **DI** is a technique to provide those abstractions at runtime

Together, they enable:
- Swappable implementations
- Easy unit testing with mocks
- Flexible architecture that can evolve

---

## Pure Python Dependency Injection

Before exploring framework-specific solutions, it's important to understand how dependency injection works in plain Python.

### Without Dependency Injection (Tight Coupling)

```python
class DatabaseConnection:
    def query(self, sql: str):
        # Execute query against production database
        pass

class UserRepository:
    def __init__(self):
        # ❌ Creates its own dependency - tight coupling
        self.db = DatabaseConnection()
    
    def get_all_users(self):
        return self.db.query("SELECT * FROM users")
```

**Problems:**
- `UserRepository` is tightly coupled to `DatabaseConnection`
- Cannot easily swap implementations (e.g., for testing)
- Violates the Dependency Inversion Principle

### With Dependency Injection (Loose Coupling)

```python
from abc import ABC, abstractmethod

# Define an abstract interface
class DatabaseConnectionInterface(ABC):
    @abstractmethod
    def query(self, sql: str):
        pass

# Production implementation
class PostgresConnection(DatabaseConnectionInterface):
    def query(self, sql: str):
        # Execute query against PostgreSQL
        pass

# Test implementation
class MockConnection(DatabaseConnectionInterface):
    def query(self, sql: str):
        return [{"id": 1, "name": "Test User"}]

class UserRepository:
    def __init__(self, db: DatabaseConnectionInterface):
        # ✅ Dependency is injected from outside
        self.db = db
    
    def get_all_users(self):
        return self.db.query("SELECT * FROM users")

# Usage - caller controls the dependency
db = PostgresConnection()
repo = UserRepository(db)

# Testing - easy to swap implementations
mock_db = MockConnection()
test_repo = UserRepository(mock_db)
```

### Constructor Injection Pattern

The most common DI pattern - dependencies are provided via the constructor:

```python
class EmailService:
    def send(self, to: str, subject: str, body: str):
        pass

class UserService:
    def __init__(
        self,
        repository: UserRepository,
        email_service: EmailService
    ):
        self._repository = repository
        self._email_service = email_service
    
    def create_user(self, name: str, email: str):
        user = self._repository.create(name, email)
        self._email_service.send(
            to=email,
            subject="Welcome!",
            body=f"Hello {name}"
        )
        return user
```

### Factory Pattern for DI

Use factories to centralize dependency creation:

```python
class ServiceFactory:
    def __init__(self, config: dict):
        self._config = config
        self._db = None
    
    def get_database(self) -> DatabaseConnectionInterface:
        if self._db is None:
            self._db = PostgresConnection(self._config["database_url"])
        return self._db
    
    def get_user_repository(self) -> UserRepository:
        return UserRepository(self.get_database())
    
    def get_user_service(self) -> UserService:
        return UserService(
            repository=self.get_user_repository(),
            email_service=EmailService()
        )

# Application bootstrap
factory = ServiceFactory(config)
user_service = factory.get_user_service()
```

---

## FastAPI's Depends System

FastAPI provides a powerful built-in dependency injection system through the `Depends` function. It builds on the patterns above but integrates seamlessly with request handling.

### Basic Usage

```python
from fastapi import Depends, FastAPI

app = FastAPI()

def get_database_connection():
    """Dependency that provides a database connection."""
    connection = DatabaseConnection()
    try:
        yield connection
    finally:
        connection.close()

@app.get("/users")
async def get_users(db = Depends(get_database_connection)):
    return db.query("SELECT * FROM users")
```

### Key Features

| Feature | Description |
|---------|-------------|
| **Automatic Resolution** | Dependencies are resolved automatically at request time |
| **Caching per Request** | Same dependency is reused within a single request |
| **Nested Dependencies** | Dependencies can depend on other dependencies |
| **Generator Support** | Use `yield` for setup/teardown patterns |
| **Async Support** | Works with both sync and async functions |

### Dependency with Parameters

```python
from fastapi import Depends, Query

def pagination(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=1000)
):
    """Reusable pagination dependency."""
    return {"skip": skip, "limit": limit}

@app.get("/items")
async def list_items(pagination: dict = Depends(pagination)):
    return {"skip": pagination["skip"], "limit": pagination["limit"]}
```

### Class-Based Dependencies

```python
from fastapi import Depends

class UserService:
    def __init__(self, db = Depends(get_database_connection)):
        self.db = db
    
    def get_user(self, user_id: int):
        return self.db.query(f"SELECT * FROM users WHERE id = {user_id}")

@app.get("/users/{user_id}")
async def get_user(user_id: int, service: UserService = Depends()):
    return service.get_user(user_id)
```

### Nested Dependencies

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    """Dependency that extracts and validates the current user."""
    user = decode_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    return user

async def get_current_active_user(user = Depends(get_current_user)):
    """Nested dependency that ensures user is active."""
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user"
        )
    return user

@app.get("/me")
async def read_current_user(user = Depends(get_current_active_user)):
    return user
```

### Global Dependencies

Apply dependencies to all routes in a router or application:

```python
from fastapi import Depends, FastAPI, APIRouter

async def verify_api_key(api_key: str = Header(...)):
    if api_key != "expected-key":
        raise HTTPException(status_code=403, detail="Invalid API key")

# Apply to entire application
app = FastAPI(dependencies=[Depends(verify_api_key)])

# Or apply to a specific router
router = APIRouter(dependencies=[Depends(verify_api_key)])
```

### Generator Dependencies (Context Managers)

Use `yield` for resources that need cleanup:

```python
from contextlib import asynccontextmanager
from fastapi import Depends

async def get_db_session():
    """Dependency with cleanup logic."""
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

@app.post("/items")
async def create_item(item: Item, db = Depends(get_db_session)):
    db.add(item)
    return item
```

## Best Practices

1. **Keep dependencies focused** - Each dependency should have a single responsibility
2. **Use type hints** - Always annotate return types for better IDE support and documentation
3. **Prefer composition** - Build complex dependencies from simpler ones
4. **Use generators for resources** - Leverage `yield` for proper resource management
5. **Avoid side effects in dependency definitions** - Dependencies should be predictable
6. **Test dependencies in isolation** - Override dependencies in tests using `app.dependency_overrides`

## Testing with Dependency Overrides

```python
from fastapi.testclient import TestClient

def override_get_database():
    return MockDatabase()

app.dependency_overrides[get_database_connection] = override_get_database

client = TestClient(app)
response = client.get("/users")
```

## External References

| Document | Description |
|----------|-------------|
| [FastAPI Dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/) | Official FastAPI dependency documentation |
| [Advanced Dependencies](https://fastapi.tiangolo.com/advanced/advanced-dependencies/) | Advanced dependency patterns |
