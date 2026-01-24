# Python Microservice Structure

## Overview

This document describes the recommended project structure for a Python microservice following Clean Architecture principles. The structure enforces separation of concerns, dependency inversion, and testability.

## Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                      External World                          │
│  (HTTP Requests, Databases, External APIs, Message Queues)  │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                    Infrastructure Layer                      │
│              (api/, persistence/, external/)                 │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                    Application Layer                         │
│                  (usecases/, services/)                      │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┘
│                      Domain Layer                            │
│                       (domain/)                              │
└─────────────────────────────────────────────────────────────┘
```

**Dependency Rule:** Dependencies point inward. Outer layers can depend on inner layers, but inner layers must not depend on outer layers.

---

## Directory Structure

```
src/
|-- {org}/
|   |-- app/
|   |   |-- api/
|   |   |   |-- __init__.py
|   |   |   |-- books/
|   |   |   |   |-- __init__.py
|   |   |   |   |-- routes.py
|   |   |   |-- middlewares.py
|   |   |-- persistence/
|   |   |   |-- __init__.py
|   |   |   |-- models/
|   |   |   |-- __init__.py
|   |   |   |-- user_model.py
|   |   |-- domain/
|   |   |   |-- __init__.py
|   |   |   |-- entities/
|   |   |   |   |-- __init__.py
|   |   |   |   |-- book.py
|   |   |   |-- types/
|   |   |   |   |-- __init__.py
|   |   |   |   |-- book_type.py
|   |   |-- services/
|   |   |   |-- __init__.py
|   |   |   |-- book_service.py
|   |   |-- external/
|   |   |   |-- __init__.py
|   |   |   |-- book_client.py
|   |   |-- config/
|   |   |   |-- __init__.py
|   |   |   |-- app_config.py
|   |   |-- usecases/
|   |   |   |-- __init__.py
|   |   |   |-- generics/
|   |   |   |   |-- __init__.py
|   |   |   |   |-- register_books.py
|   |   |   |-- borrowers/
|   |   |   |   |-- __init__.py
|   |   |   |   |-- borrow_book.py
|   |   |   |-- managers/
|   |   |   |   |-- __init__.py
|   |   |   |   |-- manage_inventory.py
|   |   |-- __init__.py
|   |   |-- __main__.py
|   |   |-- application.py
|-- tests/
|   |-- fixtures/
|   |-- units/
|   |-- integrations/
|-- pyproject.toml
|-- poetry.lock
|-- README.md
|-- .env
```

---

## Layer Descriptions

### Domain Layer (`domain/`)

The innermost layer containing business logic and entities. This layer has **no external dependencies**.

| Directory | Purpose |
|-----------|---------|
| `entities/` | Core business objects with their attributes and behaviors |
| `types/` | Domain-specific types, enums, and value objects |

**Guidelines:**
- Entities should be pure Python classes (Pydantic models)
- No framework imports (no FastAPI, SQLAlchemy, etc.)
- Contains business rules and validations
- Should be the most stable layer

```python
# domain/entities/book.py
from pydantic import BaseModel, Field

class Book(BaseModel):
    id: str
    title: str
    author: str
    isbn: str
    available: bool = Field(default=True)
    borrower_id: str | None = Field(default=None)
    revision_id: int = Field(default=0)
    
    def is_available_for_borrowing(self) -> bool:
        """Business rule: check if book can be borrowed."""
        return self.available
```

---

### Application Layer (`usecases/`, `services/`)

Contains application-specific business rules and orchestrates the flow of data.

| Directory | Purpose |
|-----------|---------|
| `usecases/` | Single-purpose operations representing user intentions |
| `services/` | Reusable business logic shared across use cases |

**Use Cases Guidelines:**
- One class per use case (Single Responsibility)
- Named after the action being performed (verb + noun)
- Organized by actor/role when multiple user types exist
- Depends only on domain layer and abstractions
- Use setter attributes for inputs and read-only properties for results

For detailed patterns, examples, and best practices for implementing use cases, see [Use Cases Pattern](usecases-pattern.md).

**Services Guidelines:**
- Contains logic reused across multiple use cases
- Should not contain HTTP or database-specific code

---

### Infrastructure Layer (`api/`, `persistence/`, `external/`)

The outermost layer handling external concerns like HTTP, databases, and third-party APIs.

#### API (`api/`)

| Directory | Purpose |
|-----------|---------|
| `{resource}/routes.py` | FastAPI route definitions grouped by resource |
| `middlewares.py` | HTTP middlewares (logging, auth, error handling) |

**Guidelines:**
- Routes should be thin - delegate to use cases
- Handle HTTP concerns (status codes, headers, serialization)
- Group routes by resource/domain concept

```python
# api/books/routes.py
from fastapi import APIRouter, Depends, HTTPException, status

router = APIRouter(prefix="/books", tags=["books"])

@router.post("/{book_id}/borrow", status_code=status.HTTP_200_OK)
async def borrow_book(
    book_id: str,
    borrower_id: str,
    use_case: BorrowBookUseCase = Depends(get_borrow_book_use_case)
):
    try:
        book = use_case.execute(book_id, borrower_id)
        return {"message": "Book borrowed successfully", "book_id": book.id}
    except BookNotFoundError:
        raise HTTPException(status_code=404, detail="Book not found")
    except BookNotAvailableError:
        raise HTTPException(status_code=409, detail="Book not available")
```

#### Persistence (`persistence/`)

| Directory | Purpose |
|-----------|---------|
| `models/` | ORM models (SQLAlchemy, etc.) |
| `repositories/` | Repository implementations |

**Guidelines:**
- ORM models are separate from domain entities
- Repositories implement interfaces defined in the application layer
- Handle data mapping between ORM models and domain entities

```python
# persistence/repositories/book_repository.py
from sqlalchemy.orm import Session

class SQLAlchemyBookRepository(BookRepositoryInterface):
    def __init__(self, session: Session):
        self._session = session
    
    def find_by_id(self, book_id: str) -> Book | None:
        model = self._session.query(BookModel).filter_by(id=book_id).first()
        return self._to_entity(model) if model else None
    
    def _to_entity(self, model: BookModel) -> Book:
        return Book(
            id=model.id,
            title=model.title,
            author=model.author,
            isbn=model.isbn,
            available=model.available
        )
```

#### External (`external/`)

| Directory | Purpose |
|-----------|---------|
| `*_client.py` | Clients for external APIs and services |

**Guidelines:**
- Wrap third-party API calls
- Implement retry logic and circuit breakers
- Map external data formats to domain entities

---

### Configuration (`config/`)

Centralized configuration management.

| File | Purpose |
|------|---------|
| `app_config.py` | Application settings using Pydantic |

```python
# config/app_config.py
from pydantic_settings import BaseSettings

class DatabaseConfig(BaseSettings):
    host: str = "localhost"
    port: int = 5432
    name: str = "app"
    
    model_config = {"env_prefix": "DB_"}

class AppConfig(BaseSettings):
    debug: bool = False
    database: DatabaseConfig = DatabaseConfig()
```

---

### Application Entry Points

| File | Purpose |
|------|---------|
| `__main__.py` | CLI entry point (`python -m {org}.app`) |
| `application.py` | FastAPI application factory |

```python
# application.py
from fastapi import FastAPI

def create_application() -> FastAPI:
    app = FastAPI(title="Book Service")
    
    # Register routes
    app.include_router(books_router)
    
    # Register middlewares
    app.add_middleware(...)
    
    return app
```

---

## Tests Structure

| Directory | Purpose |
|-----------|---------|
| `fixtures/` | Shared test fixtures and factories |
| `units/` | Unit tests (isolated, fast, no I/O) |
| `integrations/` | Integration tests (database, external APIs) |

**Testing Guidelines:**
- Unit tests mirror the `src/` structure
- Use dependency injection to mock infrastructure
- Integration tests use real (containerized) dependencies

---

## Key Principles

1. **Dependency Inversion** - High-level modules don't depend on low-level modules
2. **Single Responsibility** - Each module has one reason to change
3. **Interface Segregation** - Small, focused interfaces
4. **Testability** - Easy to test each layer in isolation
5. **Framework Independence** - Business logic doesn't depend on FastAPI