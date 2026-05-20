# Audit and events

## When to use

- Publishing **realm-aware audit events** when persisting Velmios entities.
- Wiring the **audit publisher** for a microservice on top of `fastapi-factory-utilities`.
- Customizing **`who` / `metadata` / `realm_id`** propagation on each audit envelope.

## Overview

Velmios layers a realm-isolated audit pipeline on top of the FFU audit primitives:

| Velmios component | FFU base | Role |
|---|---|---|
| `RealmIsolatedAuditEvent[Actor]` | `AuditEventObject[Actor]` | Adds `realm_id: RealmId` to every audit envelope. |
| `RealmIsolatedPersistedAuditableEntity[Id]` | `PersistedAuditableEntity[Id]` + `RealmIsolatedEntity` | Auditable persisted entity with `realm_id`. |
| `GenericService` | `ServiceAbstract` | CRUD service without audit. |
| `GenericAuditService` | `GenericService` + audit publisher | CRUD service that publishes audits on create / update / delete. |
| `AuditServiceError` | re-exported from FFU | Publisher / routing failure. |

The publisher contract itself lives in `fastapi-factory-utilities` (`AbstractAuditPublisherService.publish`, `pre_publish_hook`, etc.); see the [FFU audit service reference](../../fastapi-factory-utilities/references/audit-service.md).

## RealmIsolatedAuditEvent

```python
from typing import Annotated, Generic, TypeVar
from fastapi_factory_utilities.core.services.audit import AuditableEntity, AuditEventObject
from fastapi_factory_utilities.core.utils.api import ApiField

from velmios.core.types import RealmId


AuditEventActorGeneric = TypeVar("AuditEventActorGeneric", bound=AuditableEntity)


class RealmIsolatedAuditEvent(AuditEventObject[AuditEventActorGeneric], Generic[AuditEventActorGeneric]):
    realm_id: Annotated[RealmId, ApiField(searchable=True)]
```

Subclass when you need extra event-specific fields. Otherwise reuse it directly with the actor type for your service.

## RealmIsolatedPersistedAuditableEntity

```python
class RealmIsolatedPersistedAuditableEntity(
    PersistedAuditableEntity[GenericId], RealmIsolatedEntity, Generic[GenericId]
):
    """Realm isolated persisted auditable entity abstract."""
```

Use it as the base for every persisted entity that must publish audits. It pulls in `id`, `revision_id`, `created_at`, `updated_at`, `published`, `published_at` from FFU and adds `realm_id` from `RealmIsolatedEntity`.

## GenericService

Realm-isolated CRUD service backed by an `AbstractRepository`. Methods accept the optional audit parameters (`event_name`, `use_case`, `authentication_context`, `metadata`) so signatures stay compatible with `GenericAuditService`; the non-audit variant simply ignores them.

```python
class GenericService(ServiceAbstract[GenericPersistedEntity, GenericId, GenericQueryFilter]):
    SERVICE_ERROR = GenericServiceError
    SERVICE_NOT_FOUND_ERROR = GenericServiceNotFoundError

    def __init__(self, repository: GenericRepository) -> None: ...

    async def get_by_id(self, entity_id: GenericId) -> GenericPersistedEntity: ...
    async def create(self, entity, *, event_name=None, use_case=None, authentication_context=None, metadata=None): ...
    async def update(self, entity, *, event_name=None, use_case=None, authentication_context=None, metadata=None): ...
    async def delete(self, entity_id, *, event_name=None, use_case=None, authentication_context=None, metadata=None): ...
    async def search(self, query_filter: GenericQueryFilter) -> list[GenericPersistedEntity]: ...
```

`search` uses `ODMQueryBuilder` to translate the typed Velmios query filter into the underlying `ODMFindQuery`. `OperationError` from the repository is mapped to `SERVICE_ERROR` or `SERVICE_NOT_FOUND_ERROR`.

## GenericAuditService

Extends `GenericService` and publishes a `RealmIsolatedAuditEvent` for every successful create / update / delete. The concrete audit event type is **resolved from `Generic[...]` parameters** on the subclass (`_concrete_audit_event_type_from_class`).

```python
class GenericAuditService(
    GenericService[GenericId, GenericAuditableEntity, GenericQueryFilter, GenericRepository],
    Generic[
        GenericId, GenericAuditableEntity, GenericQueryFilter, GenericRepository, GenericPublisher, GenericAuditEvent,
    ],
):
    def __init__(self, repository: GenericRepository, publisher: GenericPublisher) -> None: ...
```

`_publish_audit_event(...)` builds the envelope with:

- `who` enriched from `AuthenticationContext` (via `velmios.core.utils.audits.enrich_audit_event_who_with_authentication_context`).
- `realm_id=entity.realm_id` (used both as a top-level field and to forward into the audit event constructor when it inherits `RealmIsolatedAuditEvent`).
- `what` / `where` / `domain` / `service` derived from the publisher constants.
- `why` defaulting to `create` / `update` / `delete` when the use case does not provide a custom `EntityFunctionalEventName`.
- `metadata` defaulting to `{}` (use-case-supplied data such as `{"changed": [...]}` flows through unchanged).

Routing key: `await self._publisher.publish(message=GenericMessage(data=event), routing_key=self._publisher.build_routing_key_pattern(event))`. The default FFU pattern is `{prefix}.{domain}.{service}.{what}.{why}` with `prefix="all"`.

Errors: `AiopikaPluginBaseError` raised by the publisher becomes `AuditServiceError(audit_event=..., routing_key=...)` so callers can recover the failed envelope.

After publishing, the persisted entity is updated with `published=True` and `published_at=datetime.now(UTC)` so consumers can replay missed events.

## Audit metadata from use cases

Use-case abstracts forward audit metadata into the service:

- `UpdateUseCaseAbstract.build_audit_metadata()` returns `{"changed": [...]}` by default — derived from `update_diff` (FFU `FieldChange` serialized via `asdict`). Override the method to include `realm_id`, request ids, or other diagnostic data.
- The publisher receives the metadata as part of the audit event and forwards it to the routing pipeline.

Top-level audit kwargs (`realm_id`, `use_case`, `authentication_context`) are always passed to the service even when `metadata` is `None`, ensuring multi-realm services keep their audit identity correctly populated.

## Wiring an auditable service

1. Define a concrete entity by subclassing `RealmIsolatedPersistedAuditableEntity[MyEntityId]`.
2. Define a concrete event subclass `MyEntityAuditEvent(RealmIsolatedAuditEvent[MyEntity])` if you need extra fields; otherwise use `RealmIsolatedAuditEvent[MyEntity]` directly.
3. Implement an `AbstractAuditPublisherService` subclass via `fastapi-factory-utilities` with the correct `ROUTING_KEY_*` constants.
4. Build the service as `GenericAuditService[MyEntityId, MyEntity, MyQueryFilter, MyRepository, MyPublisher, MyEntityAuditEvent]`.
5. Plug it into the create/update/delete use-case abstracts described in [Use cases](use-cases.md).

## Best practices

1. Always use `RealmIsolatedPersistedAuditableEntity` for entities that must publish audits — the `realm_id` propagation is otherwise impossible.
2. Override `build_audit_metadata` (on update use cases) instead of mutating audit envelopes downstream.
3. Catch `AuditServiceError` only when you can compensate (e.g. retry queue); otherwise let it bubble to the global handler so the failure is observable.
4. Use distinct `EntityFunctionalEventName` strings (`PartStr("create_via_oidc")`, etc.) when the same use case has multiple semantic events.
5. Don't bypass `GenericAuditService` for "small" operations — every CUD path on an auditable entity should publish, otherwise audit replays will be incomplete.

## Reference

- `src/velmios/core/abstracts/events.py`
- `src/velmios/core/abstracts/entities.py`
- `src/velmios/core/abstracts/services.py`
- `src/velmios/core/utils/audits.py`
- See also: [FFU audit service](../../fastapi-factory-utilities/references/audit-service.md), [Use cases](use-cases.md), [Features and resource APIs](features-and-resource-apis.md).
