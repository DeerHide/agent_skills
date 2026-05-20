# Use cases

## When to use

- Implementing **search**, **create**, **update**, or **delete** operations on a Velmios resource API.
- Enforcing **realm segmentation**, optional **cross-realm bypass** for Velmios operators, and **audit metadata** propagation.
- Adding **business hooks** (`pre_*`, `post_*`, `can_be_*`) without rewriting realm/segmentation plumbing.

## Overview

Velmios use cases live in `velmios.core.abstracts.usecases`. Each concrete use case is constructed with a `ServiceCUDAbstract` or `ServiceSearchAbstract` instance and called via FastAPI dependencies from the resource APIs in `velmios.core.abstracts.api`.

```python
from velmios.core.abstracts.usecases import (
    UseCaseAbstract,
    AuthenticatedUseCaseAbstract,
    CreateUseCaseAbstract,
    UpdateUseCaseAbstract,
    DeleteUseCaseAbstract,
    SearchUseCaseAbstract,
    BasicCreateUsecaseAbstract,
    BasicUpdateUsecaseAbstract,
)
```

## UseCaseAbstract

Root abstract that simply defines `USE_CASE_ERROR` and `async def execute() -> Any`. Subclass when you need a bespoke use case not tied to authentication.

## AuthenticatedUseCaseAbstract

```python
class AuthenticatedUseCaseAbstract(UseCaseAbstract):
    allow_cross_realm_when_velmios_admin_or_system: ClassVar[bool] = True

    def set_authentication_context(self, authentication_context: AuthenticationContext) -> Self: ...

    def _allows_cross_realm_for_velmios_operator(self) -> bool: ...
```

Adds an authentication context setter and the **cross-realm bypass switch**:

- `allow_cross_realm_when_velmios_admin_or_system` (default `True`) — when `True` and the request was authenticated as a Velmios admin or system entity (`AuthenticationContext.is_velmios_admin_or_system()`), the realm checks below are bypassed.
- Set the class attribute to `False` on use cases that MUST stay realm-isolated even for operators (e.g. self-service admin tools).

## CreateUseCaseAbstract

```python
class CreateUseCaseAbstract(AuthenticatedUseCaseAbstract, Generic[Entity, Id, QueryFilter]):
    USE_CASE_NAME: ClassVar[UseCaseName] = UseCaseName(PartStr("create"))
    USE_CASE_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_NOT_ALLOWED_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_SEGMENTATION_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]

    def set_entity(self, entity: Entity) -> Self: ...

    @abstractmethod
    async def pre_create_hook(self, entity: Entity) -> Entity: ...

    @abstractmethod
    async def post_create_hook(self, entity: Entity) -> None: ...

    @abstractmethod
    async def can_be_created(self, entity: Entity) -> tuple[bool, str | None]: ...
```

`execute()` flow:

1. **Cross-realm or segmentation gate**:
   - Operators with the bypass enabled skip the realm check entirely.
   - Velmios admins/systems without bypass must already target their own realm; otherwise `USE_CASE_SEGMENTATION_ERROR` is raised.
   - All other callers have their `realm_id` overwritten with the caller's realm (defense in depth).
2. `can_be_created(entity)` — must return `(True, None)` to proceed; otherwise raises `USE_CASE_NOT_ALLOWED_ERROR(reason=...)`.
3. `pre_create_hook(entity)` — return a (possibly mutated) entity for persistence.
4. Calls `service.create(entity=..., authentication_context=..., use_case=USE_CASE_NAME)`.
5. `post_create_hook(entity)` — side effects after persistence.

`BasicCreateUsecaseAbstract` provides default implementations (`pre_create_hook` returns the entity, `post_create_hook` no-ops, `can_be_created` returns `(True, None)`).

## UpdateUseCaseAbstract

```python
class UpdateUseCaseAbstract(AuthenticatedUseCaseAbstract, Generic[Entity, Id, QueryFilter]):
    USE_CASE_NAME: ClassVar[UseCaseName] = UseCaseName(PartStr("update"))
    USE_CASE_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_NOT_FOUND_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_SEGMENTATION_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_NOT_ALLOWED_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]

    def set_entity_id(self, entity_id: Id) -> Self: ...
    def set_entity_to_update(self, entity: Entity) -> Self: ...

    @property
    def entity(self) -> Entity: ...
    @property
    def update_diff(self) -> list[FieldChange]: ...
    @property
    def ignored_update_paths(self) -> list[str]: ...
    @property
    def unchanged_update_paths(self) -> list[str]: ...
    @property
    def reconcile_result(self) -> Any | None: ...

    async def build_audit_metadata(self) -> dict[str, Any]:
        return {"changed": [asdict(change) for change in self._update_diff]}

    @abstractmethod
    async def can_be_updated(self, entity_original, entity_to_update, reconcile_result=None): ...
    @abstractmethod
    async def pre_update_hook(self, entity_original, entity_to_update): ...
    @abstractmethod
    async def post_update_hook(self, entity_original, entity_updated): ...
```

`execute()` flow:

1. `entity_id` MUST equal `entity_to_update.id` (otherwise `USE_CASE_SEGMENTATION_ERROR`).
2. Loads the original entity through the service (`USE_CASE_ERROR` on failure).
3. Realm segmentation: when no cross-realm bypass applies, the original `realm_id` MUST match the caller's realm.
4. **PUT reconciliation** — if the entity class implements `reconcile_update_request`, the use case calls it (`strict=False`), records the reconciled entity, and exposes:
   - `update_diff: list[FieldChange]` — `{path, before, after}` per change.
   - `ignored_update_paths: list[str]` — payload paths discarded because they are not `UpdateableField`.
   - `unchanged_update_paths: list[str]` — updateable paths submitted with the same value.
   - `reconcile_result` — the raw result for advanced consumers.
   See the [FFU PUT update reference](../../fastapi-factory-utilities/references/api-response-and-update.md) for `UpdateableField` semantics.
5. `can_be_updated(entity_original, entity_to_update, reconcile_result)` — gate the update; failure raises `USE_CASE_NOT_ALLOWED_ERROR(reason=...)`.
6. `pre_update_hook(entity_original, entity_to_update)` — return the entity to persist.
7. `build_audit_metadata()` is called and the resulting dict is forwarded to `service.update(..., metadata=...)`. By default it surfaces `changed` for the audit publisher. Override to add deltas, request IDs, etc.
8. Persists via `service.update(..., use_case=USE_CASE_NAME)`.
9. `post_update_hook(entity_original, entity_updated)`.

`BasicUpdateUsecaseAbstract` provides default no-op hooks and `can_be_updated` returning `(True, None)` so simple use cases only override the parts they need.

## DeleteUseCaseAbstract

```python
class DeleteUseCaseAbstract(AuthenticatedUseCaseAbstract, Generic[Entity, Id, QueryFilter]):
    USE_CASE_NAME: ClassVar[UseCaseName] = UseCaseName(PartStr("delete"))
    USE_CASE_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_NOT_FOUND_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_SEGMENTATION_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_NOT_ALLOWED_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]

    def set_entity_id(self, entity_id: Id) -> Self: ...

    @abstractmethod
    async def can_be_deleted(self, entity: Entity) -> tuple[bool, str | None]: ...

    @abstractmethod
    async def post_delete_hook(self, entity: Entity) -> None: ...
```

`execute()` flow:

1. Load entity by id (`USE_CASE_NOT_FOUND_ERROR` when missing).
2. Realm segmentation (`USE_CASE_SEGMENTATION_ERROR`) unless the operator bypass applies.
3. `can_be_deleted(entity)` — failure raises `USE_CASE_NOT_ALLOWED_ERROR(reason=...)`.
4. `service.delete(entity_id, authentication_context=..., use_case=USE_CASE_NAME)`.
5. `post_delete_hook(entity)`.

## SearchUseCaseAbstract

```python
class SearchUseCaseAbstract(AuthenticatedUseCaseAbstract, Generic[Entity, QueryFilter]):
    USE_CASE_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]
    USE_CASE_NOT_FOUND_ERROR: ClassVar[type[FastAPIFactoryUtilitiesError]]

    def set_query_filters(self, query_filters: QueryFilter) -> Self: ...

    @property
    def items(self) -> list[Entity]: ...
```

`execute()` flow:

1. Resolve the type-parameterized `QueryFilter` model from `__orig_bases__`.
2. When no operator bypass applies, `add_realm_id_to_query_filters(...)` constrains the filter to the caller's realm.
3. Calls `service.search(query_filter)` and stores the results on `items`.

Use this as the foundation for `GET /` and `GET /{entity_id}` routes — the resource APIs feed a `id == entity_id` filter to the search use case for single-entity lookups.

## Resource API ↔ HTTP mapping

The CUD resource APIs in `velmios.core.abstracts.api` already map use-case errors to HTTP responses:

| Use-case error | HTTP |
|---|---|
| `USE_CASE_NOT_FOUND_ERROR` | 404 |
| `USE_CASE_NOT_ALLOWED_ERROR` | 403 |
| `USE_CASE_SEGMENTATION_ERROR` | 403 |
| `USE_CASE_ERROR` | 500 |
| JSON / pydantic validation errors | 422 |

`POST` returns 201 with `Location: {collection_path}/{entity.id}`; `PUT` returns 200 with `Location: /{entity_id}`; `DELETE` returns 204. See [Features and resource APIs](features-and-resource-apis.md) and [Exception handling](exception-handling.md).

## Implementation pattern

```python
from velmios.core.abstracts.usecases import BasicCreateUsecaseAbstract


class CreateMyEntityUseCase(
    BasicCreateUsecaseAbstract[MyEntity, MyEntityId, MyEntityQueryFilter]
):
    USE_CASE_ERROR = CreateMyEntityError
    USE_CASE_NOT_ALLOWED_ERROR = CreateMyEntityNotAllowedError
    USE_CASE_SEGMENTATION_ERROR = CreateMyEntitySegmentationError

    async def can_be_created(self, entity: MyEntity) -> tuple[bool, str | None]:
        if entity.email in BLOCKLIST:
            return False, "Email is blocklisted"
        return True, None
```

## Best practices

1. Subclass `Basic*UsecaseAbstract` whenever the default hooks are enough; override only the methods you need.
2. Keep `can_be_*` synchronous in spirit (validation only). Push side effects to `pre_*` / `post_*` hooks.
3. Override `build_audit_metadata` on update use cases when you want to enrich audit events with more than `changed` (e.g. `realm_id`, request ids).
4. Set `allow_cross_realm_when_velmios_admin_or_system = False` on use cases that MUST stay realm-isolated even for Velmios operators.
5. Never raise raw `HTTPException` from inside a use case; raise the class-level `USE_CASE_*` error so the resource API and exception handlers can map it consistently.

## Reference

- `src/velmios/core/abstracts/usecases/abstracts.py`
- `src/velmios/core/abstracts/usecases/create.py`
- `src/velmios/core/abstracts/usecases/update.py`
- `src/velmios/core/abstracts/usecases/delete.py`
- `src/velmios/core/abstracts/usecases/search.py`
- `src/velmios/core/abstracts/services.py`
- `src/velmios/core/abstracts/api.py`
