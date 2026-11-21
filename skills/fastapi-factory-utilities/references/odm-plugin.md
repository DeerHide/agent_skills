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

Base class for all Beanie document models. Adds UUID `id`, optional `revision_id`, indexed `schema_version`, and indexed `created_at` / `updated_at` timestamps (auto-set on insert / update). `revision_id` is Beanie optimistic concurrency; `schema_version` tracks document shape for continuous migrations.

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

`PersistedEntity[Id]` is the canonical base for ODM-backed domain entities. Since v3.x it mixes in **`SearchableEntity`**, **`ApiResponseModelAbstract`**, and `BaseModel`, so every persisted entity also doubles as a response model and supports `build_query_filter_model()`. The `Id` type parameter (typically a `typing.NewType` over `uuid.UUID`) flows into the dynamic query filter so resolver coercion is exact. It also carries `schema_version: int` (default `0`) so repository `model_dump()` / `save()` round-trips the stored version.

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

`schema_version` is **not** searchable and **not** an API response field.

See [API response & PUT update model](api-response-and-update.md) for the response and update flow.

**IMPORTANT**: Entities that do **not** extend `PersistedEntity` **MUST** declare `schema_version: int` themselves. With `extra="ignore"`, `model_dump()` drops unknown fields and the next save cannot carry the stored version.

## Document schema migrations

Continuous forward migrations rewrite legacy Mongo documents while the process serves traffic. Expand and contract are **two releases** of the same chain.

### Register steps on the document

```python
from collections.abc import Mapping
from typing import Any, ClassVar

from fastapi_factory_utilities.core.plugins.odm_plugin import BaseDocument, SchemaMigration


def copy_name_to_display_name(raw: dict[str, Any]) -> dict[str, Any]:
    upgraded = dict(raw)
    upgraded["display_name"] = upgraded.get("name")
    return upgraded


def drop_legacy_name(raw: dict[str, Any]) -> dict[str, Any]:
    upgraded = dict(raw)
    upgraded.pop("name", None)
    return upgraded


class CustomerDocument(BaseDocument):
    CURRENT_SCHEMA_VERSION: ClassVar[int] = 2

    @classmethod
    def schema_migrations(cls) -> Mapping[int, SchemaMigration]:
        return {
            0: SchemaMigration(to_version=1, transform=copy_name_to_display_name),
            1: SchemaMigration(to_version=2, transform=drop_legacy_name),
        }

    class Settings(BaseDocument.Settings):
        name = "customers"
```

- `CURRENT_SCHEMA_VERSION = 0` means no migrations (default).
- `schema_migrations()` **MUST** be a contiguous chain `0 → 1 → … → CURRENT`.
- Each `transform` is pure and **MUST** be safe to run twice (crash between in-memory upgrade and the write).
- Keys removed by a transform become `$unset` on the sweep write. `save()` never unsets unknown keys.

### Read path

A `model_validator(mode="before")` on `BaseDocument` upgrades stored documents in memory before Pydantic validates:

- Stored doc (`_id` / `id` present) missing `schema_version` → treat as version `0` and apply steps.
- New instance (no id, no `schema_version`) → stamp `CURRENT_SCHEMA_VERSION`.
- `schema_version` lower than current → apply forward steps only.
- Already current → untouched.

The read does **not** write. A failing step fails that load; a half-upgraded object is never returned. This keeps the previous document from breaking the new process before the sweep finishes. Expand steps leave old fields in Mongo so the previous process still finds them; old models ignore new fields (`extra` ignore).

### Startup batch sweep

After `init_beanie`, `ODMPlugin` spawns one `asyncio.Task` per document with `CURRENT_SCHEMA_VERSION > 0`, then reports healthy immediately (readiness is **not** blocked). On shutdown the tasks are cancelled.

Per collection:

1. Acquire the collection lock (below). If another owner holds it, sleep and retry.
2. Find one batch (`limit` 100): `schema_version < current` or field missing.
3. For each document in order, `update_one` (filter on `_id` + `revision_id` + observed `schema_version`). `$set` upgraded fields + new `revision_id`; `$unset` removed keys. **No** `bulk_write` / `update_many`.
4. Renew the lock; fetch the next batch. An empty batch releases the lock and idles, then rescans for the life of the process (rolling deploys keep inserting legacy docs).

On `revision_id` mismatch, skip that document. A document that throws is logged and skipped; it does not stop the batch.

### Migration lock

One sweeper per collection. Different collections still migrate in parallel.

`SchemaMigrationLock` protocol: `try_acquire(*, key, owner) -> bool`, `renew(*, key, owner) -> bool`, `release(*, key, owner) -> None`. `key` is the collection name; `owner` is `hostname:pid`.

- Default when `ODMPlugin(..., migration_lock=None)`: `MongoSchemaMigrationLock` — lease documents in `schema_migration_locks` (`{_id, owner, expires_at}`). Acquire matches missing, expired, or same owner. Release deletes only when `owner` matches. Lease renews between batches; a dead process stops renewing and the next pass takes it after expiry.
- Inject a custom lock (e.g. Redis) or `AlwaysAcquireMigrationLock` in tests via `ODMPlugin(..., migration_lock=...)`.

The lock covers the sweep only. Reads still upgrade in memory; a user `save()` can still race one document — `revision_id` decides that write.

### Release rule (expand / contract)

| Step | When to ship |
|------|----------------|
| **Expand** (copy/add fields, keep old ones) | Same release as the code that reads the new field. Safe while the previous release is still running. |
| **Contract** (`$unset` old fields) | **Next** release, after previous pods are gone. An old `save()` `$set`s fields it still knows and would put a dropped field back. |

FFU will not refuse a contract step in the same release; it cannot see the other deployment. The version chain is the only gate.

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
6. Ship expand and contract as **separate** releases; do **not** `$unset` a field the previous process still reads or writes.
7. Keep `schema_version` on the entity (via `PersistedEntity` or an explicit field) so saves carry the stored version.

## Reference

- `src/fastapi_factory_utilities/core/plugins/odm_plugin/plugins.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/documents.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/helpers.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/migrations.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/migration_lock.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/migration_sweep.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/configs.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/depends.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/queries.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/builder.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/encryption/`
- See also: [Query utilities](query-utilities.md), [API response & PUT update model](api-response-and-update.md), [Repository pattern](repository-pattern.md).
