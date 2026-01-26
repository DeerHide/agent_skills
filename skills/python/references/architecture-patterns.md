# Architecture Patterns

## Abstract Base Classes

Use `ABC` and `abstractmethod` for interfaces:

```python
from abc import ABC, abstractmethod

class AbstractRepository(ABC, Generic[DocumentGenericType, EntityGenericType]):
    """Abstract repository interface."""

    @abstractmethod
    async def create(self, entity: EntityGenericType) -> DocumentGenericType:
        """Create a new entity."""
        raise NotImplementedError
```

## Plugin Pattern

Implement plugins by extending `PluginAbstract`:

```python
from fastapi_factory_utilities.core.plugins.abstracts import PluginAbstract

class MyPlugin(PluginAbstract):
    """Plugin implementation."""

    async def setup(self) -> Self:
        """Setup the plugin."""
        # Initialization logic
        return self

    async def shutdown(self) -> None:
        """Shutdown the plugin."""
        # Cleanup logic
```

## Dependency Injection

Use FastAPI's dependency injection system:

```python
from fastapi import Depends
from fastapi_factory_utilities.core.app import depends_dependency_config

async def my_endpoint(
    config: DependencyConfig = Depends(depends_dependency_config),
) -> dict[str, Any]:
    """Endpoint using dependency injection."""
    return {"config": config}
```

## Repository Pattern

Implement repositories for data access:

```python
class UserRepository(AbstractRepository[UserDocument, UserEntity]):
    """Repository for user entities."""

    async def find_by_email(self, email: str) -> UserDocument | None:
        """Find user by email."""
        return await self.find_one(UserDocument.email == email)
```

## Service Layer

Implement service classes for business logic:

```python
class UserService:
    """Service for user operations."""

    def __init__(self, repository: UserRepository) -> None:
        """Initialize the service."""
        self._repository: UserRepository = repository

    async def create_user(self, user_data: UserEntity) -> UserDocument:
        """Create a new user."""
        # Business logic here
        return await self._repository.create(user_data)
```
