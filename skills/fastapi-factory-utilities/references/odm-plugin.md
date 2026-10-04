# ODM Plugin (MongoDB)

The ODM plugin provides MongoDB integration using Beanie ODM with automatic connection management and status monitoring.

## When to use

Use the ODM plugin when:

- Building applications that need MongoDB persistence.
- Using Beanie ODM for document modeling.
- Managing MongoDB connections with automatic lifecycle.
- Implementing the repository pattern with MongoDB.
- Translating typed `QueryAbstract` filters into Beanie `find` arguments.
- Needing automatic health / readiness status for database connections.

## ODMPlugin

The plugin manages MongoDB connections, Beanie initialization, and status monitoring.

### Configuration

```python
from fastapi_factory_utilities.core.plugins.odm_plugin import ODMPlugin

plugin = ODMPlugin()

plugin = ODMPlugin(document_models=[BookDocument, UserDocument])

from fastapi_factory_utilities.core.plugins.odm_plugin.configs import ODMConfig

odm_config = ODMConfig(
    uri="mongodb://localhost:27017",
    database="my_database",
    connection_timeout_ms=4000,
)
plugin = ODMPlugin(odm_config=odm_config)
```

### YAML configuration

```yaml
odm:
  uri: "${MONGODB_URI:mongodb://localhost:27017}"
  database: "${MONGODB_DATABASE:my_database}"
  connection_timeout_ms: 4000
```

### Application setup

```python
class MyApp(ApplicationAbstract):
    PACKAGE_NAME = "my_app"
    ODM_DOCUMENT_MODELS = [BookDocument, UserDocument]

    def configure(self) -> None:
        pass

    async def on_startup(self) -> None:
        pass

    async def on_shutdown(self) -> None:
        pass
```

## BaseDocument

Base class for all Beanie document models. Adds UUID `id`, optional `revision_id`, and indexed `created_at` / `updated_at` timestamps (auto-set on insert / update).

```python
from typing import Annotated
from beanie import Indexed
from fastapi_factory_utilities.core.plugins.odm_plugin import BaseDocument


class BookDocument(BaseDocument):
    title: Annotated[str, Indexed(unique=True)]
    author: str
    published_year: int

    class Settings(BaseDocument.Settings):
        collection: str = "books"
```

## PersistedEntity (generic)

`PersistedEntity[Id]` is the canonical base for ODM-backed domain entities. Since v3.x it mixes in **`SearchableEntity`**, **`ApiResponseModelAbstract`**, and `BaseModel`, so every persisted entity also doubles as a response model and supports `build_query_filter_model()`. The `Id` type parameter (typically a `typing.NewType` over `uuid.UUID`) flows into the dynamic query filter so resolver coercion is exact.

```python
import uuid
from typing import Annotated, NewType

from fastapi_factory_utilities.core.plugins.odm_plugin import PersistedEntity
from fastapi_factory_utilities.core.utils.api import ApiField, UpdateableField, SearchableField


BookEntityId = NewType("BookEntityId", uuid.UUID)


class BookEntity(PersistedEntity[BookEntityId]):
    title: Annotated[str, ApiField(searchable=True), UpdateableField]
    author: Annotated[str, ApiField(searchable=True), UpdateableField]
    published_year: Annotated[int, ApiField(searchable=True), UpdateableField]
    internal_score: Annotated[int, SearchableField] = 0
```

Fields are marked with `ApiField` flags:

- `ApiField()` / `ApiResponseField` — exposed in the dynamic response model.
- `UpdateableField` — exposed in the response model **and** PUT request model.
- `SearchableField` — search-only (excluded from the response model).

See [API response & PUT update model](api-response-and-update.md) for the response and update flow.

## ODM ↔ Mongo path mapping

The query translator maps the Pydantic field `id` to MongoDB `_id` so Beanie's primary key is targeted correctly. Other paths are passed through verbatim. The mapping is intentional and applies to every `QueryAbstract` filter.

## Query translation (`ODMQueryBuilder`)

```python
from fastapi_factory_utilities.core.plugins.odm_plugin import ODMQueryBuilder, ODMFindQuery


builder: ODMQueryBuilder[BookQueryFilter] = ODMQueryBuilder()
builder.set_query_filter(book_query_filter)
find_query: ODMFindQuery = builder.build()

await repository.find(
    find_query.mongo_filter,
    skip=find_query.skip,
    limit=find_query.limit,
    sort=find_query.sort,
)
```

- `ODMFindQuery(mongo_filter, skip, limit, sort)` is frozen and serializable.
- Sort tokens carry direction (`ASCENDING` / `DESCENDING`).
- Operator merging rules for the same path:
  - Comparison operators (`$gt`, `$lt`, `$gte`, `$lte`, `$ne`) merge into one subdocument when keys do not conflict.
  - `$in` / `$nin` merge with each other or with comparisons when keys do not conflict; otherwise they fall back to `$and`.
  - `$not` (from `not_contains`) and equality terms are emitted as separate `$and` conjuncts.
- Multiple filter paths combine with implicit AND; conflicting same-path operations become an `$and` block.

## Dependencies

```python
from fastapi import Depends
from fastapi_factory_utilities.core.plugins.odm_plugin import depends_odm_database, depends_odm_client


@router.get("/stats")
async def stats(database = Depends(depends_odm_database)):
    return await database.command("dbStats")


@router.get("/health")
async def health(client = Depends(depends_odm_client)):
    return {"connected": client is not None}
```

## Status monitoring

The plugin reports `HEALTHY` / `READY` on successful connection, `UNHEALTHY` / `NOT_READY` on failure. Component type `DATABASE`, identifier `MongoDB`.

## Client-side field-level encryption (CSFLE)

Declare encrypted field paths on the document. Do not encrypt/decrypt at call sites.

```python
class ProcessorCredsDocument(BaseDocument):
    class Settings(BaseDocument.Settings):
        collection = "processor_creds"
        encrypted_fields = ["creds.client_secret"]
```

Enable on `ODMConfig` (`csfle_enabled: true`). Required together: `csfle_vault_address`, `csfle_vault_auth_mount`, `csfle_vault_role`, `csfle_vault_transit_key`, `csfle_master_key_ciphertext`. Optional `csfle_key_vault_collection` (default `__keyVault` in the service database).

Startup unwraps the local KMS master key via Vault Transit (`VaultUnwrapClient` Kubernetes auth), builds a `schemaMap` from `encrypted_fields`, and runs a probe insert/delete on `__csfle_startup_probe` so mongocryptd is spawned before the first request. Algorithm is randomized only (`AEAD_AES_256_CBC_HMAC_SHA_512-Random`); encrypted fields MUST NOT be queried by value.

## Error handling

```python
from fastapi_factory_utilities.core.plugins.odm_plugin.exceptions import (
    OperationError,
    UnableToCreateEntityDueToDuplicateKeyError,
)

try:
    await repository.insert(entity)
except UnableToCreateEntityDueToDuplicateKeyError:
    raise HTTPException(status_code=409, detail="Entity already exists")
except OperationError as exc:
    logger.error("Database operation failed", error=exc)
    raise
```

## Best practices

1. Always parameterize `PersistedEntity[YourEntityId]` and prefer `NewType` over raw `UUID` for stronger typing in `QueryResolver`.
2. Mark only client-writable fields with `UpdateableField`; everything else stays response-only.
3. Use `Entity.build_query_filter_model()` to derive the query filter and assign it to a named class (clean OpenAPI naming).
4. Define indexes via Beanie's `Indexed` annotation in `BaseDocument` subclasses.
5. Load `ODMPlugin` before any plugin that depends on repositories.

## Reference

- `src/fastapi_factory_utilities/core/plugins/odm_plugin/plugins.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/documents.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/helpers.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/configs.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/depends.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/queries.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/builder.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/encryption/`
- See also: [Query utilities](query-utilities.md), [API response & PUT update model](api-response-and-update.md), [Repository pattern](repository-pattern.md).
