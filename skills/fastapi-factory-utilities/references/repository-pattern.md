# Repository Pattern

The repository pattern provides a type-safe abstraction for MongoDB/Beanie data access, separating domain entities from persistence concerns.

## When to use

- Implementing a data access layer with clean architecture.
- Separating domain entities from database documents.
- Building testable services with mockable data access.
- Performing CRUD operations with type safety.
- Writing unit tests without a real database via `AbstractRepositoryInMemory`.
- Persisting auditable entities (`PersistedAuditableEntity`).

## AbstractRepository

Generic over the Beanie `Document` type and the Pydantic entity type.

```python
from fastapi_factory_utilities.core.plugins.odm_plugin import AbstractRepository
from my_app.models import BookDocument
from my_app.entities import BookEntity


class BookRepository(AbstractRepository[BookDocument, BookEntity]):
    """Repository for books."""
```

The repository:

- Maps between document and entity types (`PersistedEntity` is the recommended entity base).
- Manages database sessions (decorator `@managed_session()`).
- Updates `created_at` / `updated_at` automatically.
- Surfaces structured exceptions on operational failures.

## CRUD operations

### Insert / update / delete

```python
created = await repository.insert(entity)

entity.title = "Updated"
updated = await repository.update(entity)

await repository.delete_one_by_id(entity_id)
await repository.delete_one_by_id(entity_id, raise_if_not_found=True)
```

### Get by id

```python
entity = await repository.get_one_by_id(entity_id)
if entity is None:
    raise HTTPException(status_code=404, detail="Not found")
```

### Find with filters

```python
from beanie import SortDirection

entities = await repository.find()
entities = await repository.find(skip=0, limit=10, sort=[("created_at", SortDirection.DESCENDING)])
entities = await repository.find({"author": "Robert C. Martin"})
entities = await repository.find(BookDocument.author == "Robert C. Martin", BookDocument.published_year >= 2000)
```

### Translating from `QueryAbstract`

Prefer `ODMQueryBuilder` (see [ODM plugin](odm-plugin.md#query-translation-odmquerybuilder)) over hand-coded filters:

```python
builder = ODMQueryBuilder()
builder.set_query_filter(book_query_filter)
find_query = builder.build()

entities = await repository.find(
    find_query.mongo_filter,
    skip=find_query.skip,
    limit=find_query.limit,
    sort=find_query.sort,
)
```

## Session management

`@managed_session()` (used internally) opens a transaction when `use_transactions=True` is set on the underlying Mongo client. To run multiple operations in one session manually:

```python
async with repository.get_session() as session:
    e1 = await repository.insert(entity1, session=session)
    e2 = await repository.insert(entity2, session=session)
```

## Repositories for auditable entities

`AbstractRepository[Document, PersistedAuditableEntity[Id]]` works seamlessly with `PersistedAuditableEntity`. The repository persists the audit fields (`published`, `published_at`, `revision_id`) that audit-aware services (e.g. Velmios `GenericAuditService`) update after publishing.

```python
class OrderRepository(AbstractRepository[OrderDocument, OrderEntity]):
    """OrderEntity inherits PersistedAuditableEntity[OrderEntityId]."""
```

When the audit publisher confirms a message, the audit service calls `update(...)` to set `published=True` and `published_at=...`. Use the same repository for the entity and its audit lifecycle.

## Testing with `AbstractRepositoryInMemory`

In-memory implementation for unit tests. Combine with [AioHttp mocking](aiohttp.md#testing-with-mocks) when the service also makes HTTP calls.

```python
from fastapi_factory_utilities.core.plugins.odm_plugin import AbstractRepositoryInMemory


class BookRepositoryInMemory(AbstractRepositoryInMemory[BookDocument, BookEntity]):
    """In-memory repository for testing."""
```

```python
@pytest.fixture
def repository() -> BookRepositoryInMemory:
    return BookRepositoryInMemory()


@pytest.fixture
def repository_seeded() -> BookRepositoryInMemory:
    return BookRepositoryInMemory(entities=[
        BookEntity(id=uuid4(), title="Existing", author="Existing Author", published_year=2024),
    ])
```

### Query support

```python
entities = await repository.find({"author": "John"})
entities = await repository.find({"year": {"$gt": 2000}})
entities = await repository.find({"status": {"$in": ["active", "pending"]}})
entities = await repository.find({"title": {"$regex": "^Clean", "$options": "i"}})
entities = await repository.find({"deleted_at": {"$exists": False}})
entities = await repository.find({"tags": {"$all": ["python", "fastapi"]}})
entities = await repository.find({"tags": {"$size": 3}})
```

Beanie-style operand expressions also work because the in-memory repository implements the same `MockQueryField` shim:

```python
entities = await repository.find(BookDocument.author == "John", BookDocument.year >= 2000)
```

`AbstractRepositoryInMemory` also accepts `PersistedAuditableEntity` types so audit-aware services can be unit tested without RabbitMQ.

## Error handling

```python
from fastapi_factory_utilities.core.plugins.odm_plugin.exceptions import (
    OperationError,
    UnableToCreateEntityDueToDuplicateKeyError,
)

try:
    await repository.insert(entity)
except UnableToCreateEntityDueToDuplicateKeyError:
    raise HTTPException(status_code=409, detail="Already exists")
except OperationError as exc:
    logger.error("Database operation failed", error=exc)
    raise HTTPException(status_code=500, detail="Database error")
```

## Best practices

1. One repository per domain aggregate.
2. Always specialize `AbstractRepository[Document, Entity]` — the generic types drive Beanie ↔ Pydantic conversion.
3. Inject repositories with FastAPI `Depends`.
4. Pair audit-aware repositories with `GenericAuditService` so `published_at` is maintained.
5. Use `AbstractRepositoryInMemory` for unit tests; pre-seed the data through the `entities` constructor argument.
6. Never import Beanie symbols in entity modules — keep entities free of persistence imports.

## Reference

- `src/fastapi_factory_utilities/core/plugins/odm_plugin/repositories.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/mockers.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/helpers.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/exceptions.py`
- See also: [ODM plugin](odm-plugin.md), [Audit service](audit-service.md), [AioHttp](aiohttp.md).
