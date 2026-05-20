# Audit Service

The audit service publishes structured audit events to RabbitMQ via AioPika using a typed, routed publisher.

## When to use

- Recording entity lifecycle events (created, updated, deleted) for compliance and replay.
- Tracking user / system actions on auditable entities.
- Decoupling business logic from audit publishing.
- Building consumers that listen on specific routing key patterns.

## Module layout

```python
from fastapi_factory_utilities.core.services.audit import (
    AbstractAuditPublisherService,
    AbstractAuditListenerService,
    AuditEventObject,
    AuditableEntity,
    PersistedAuditableEntity,
    UseCaseName,
    DomainName,
    EntityName,
    EntityFunctionalEventName,
    ServiceName,
    AuditServiceError,
)
```

## AuditEventObject

Generic over an actor entity type (`AuditEventActorGeneric` bound by `AuditableEntity[Any]`).

```python
class AuditEventObject(SearchableEntity, ApiResponseModelAbstract, BaseModel, Generic[Actor]):
    id: Annotated[uuid.UUID | None, ApiField(searchable=True)] = None
    what: Annotated[EntityName, ApiField(searchable=True)]
    why: Annotated[EntityFunctionalEventName, ApiField(searchable=True)]
    where: Annotated[ServiceName, ApiField(searchable=True)]
    when: Annotated[datetime.datetime, ApiField(searchable=True)]
    who: Annotated[dict[str, Any], ApiField(searchable=True)]
    entity: Annotated[Actor, ApiField(searchable=True)]
    domain: Annotated[DomainName, ApiField(searchable=True)]
    service: Annotated[ServiceName, ApiField(searchable=True)]
    use_case: Annotated[UseCaseName, ApiField(searchable=True)] = Field(default=UseCaseName(PartStr("unknown")))
    metadata: Annotated[dict[str, Any], ApiField(searchable=True)] = Field(default_factory=dict)
```

Validators:

- `who` MUST be a non-empty `dict[str, Any]`. The producer typically includes the actor id, and may also include realm, group, or session ids.
- `use_case` is a `NewType` wrapper over `PartStr` (validated routing-key part).

**`pre_publish_hook(cls, entity)`** is a class method called by the publisher to scrub sensitive data from the actor entity before publishing. Override on subclasses to redact PII.

### Auditable entities

```python
class AuditableEntity(SearchableEntity, ApiResponseModelAbstract, BaseModel, Generic[Id]):
    model_config = ConfigDict(extra="allow", arbitrary_types_allowed=True)

    id: Annotated[Id, ApiField(searchable=True)]
    created_at: Annotated[datetime.datetime, ApiField(searchable=True)]
    updated_at: Annotated[datetime.datetime, ApiField(searchable=True)]
    deleted_at: Annotated[datetime.datetime | None, ApiField(searchable=True)] = None
    published: Annotated[bool, ApiField(searchable=True)] = False
    published_at: Annotated[datetime.datetime | None, ApiField(searchable=True)] = None


class PersistedAuditableEntity(AuditableEntity[Id], Generic[Id]):
    id: Annotated[Id, ApiField(searchable=True)] = Field(default_factory=uuid.uuid4)
    revision_id: uuid.UUID | None = Field(default=None)
```

- `extra="allow"` so domain attributes can extend the auditable shape without subclassing twice.
- `published` / `published_at` are set by audit-aware services (Velmios `GenericAuditService`) once the event reaches the broker.
- `PersistedAuditableEntity` aligns the persistence fields with `PersistedEntity` (default-generated `id`, optional `revision_id`).

## AbstractAuditPublisherService

```python
class AbstractAuditPublisherService(AbstractPublisher[GenericMessage[Event]], ABC, Generic[Event]):
    EXCHANGE_NAME: ClassVar[ExchangeName] = ExchangeName("default")
    EXCHANGE_TYPE: ClassVar[ExchangeType] = ExchangeType.TOPIC

    ROUTING_KEY_PREFIX: ClassVar[PartStr] = PartStr("all")
    ROUTING_KEY_DOMAIN_NAME: ClassVar[DomainName] = DomainName(PartStr("default"))
    ROUTING_KEY_SERVICE_NAME: ClassVar[ServiceName] = ServiceName(PartStr("default"))
    ROUTING_KEY_ENTITY_NAME: ClassVar[EntityName] = EntityName(PartStr("default"))

    def build_routing_key_pattern(self, audit_event: Event) -> RoutingKey: ...

    async def publish(self, message: GenericMessage[Event], routing_key: RoutingKey) -> None: ...
```

Subclass per audit stream (typically one per service):

```python
class BookAuditPublisher(AbstractAuditPublisherService[BookAuditEvent]):
    ROUTING_KEY_PREFIX = PartStr("all")
    ROUTING_KEY_DOMAIN_NAME = DomainName(PartStr("library"))
    ROUTING_KEY_SERVICE_NAME = ServiceName(PartStr("book_service"))
    ROUTING_KEY_ENTITY_NAME = EntityName(PartStr("book"))
```

Behaviour:

- `build_routing_key_pattern(event)` returns `{prefix}.{domain}.{service}.{entity}.{functional_event}` via `EventRoutingKeyBuilder`. Override only if a service uses a different pattern.
- `publish(message, routing_key)`:
  1. Calls `message.data.pre_publish_hook(entity)` to scrub the actor.
  2. Delegates to `AbstractPublisher.publish`.
  3. Wraps `AiopikaPluginBaseError` into `AuditServiceError(audit_event=..., routing_key=..., cause=...)`.

### Example routing keys

- `all.library.book_service.book.created`
- `all.library.book_service.book.updated`
- `all.payments.payment_service.payment.processed`

## AbstractAuditListenerService

Mirror class on the consumer side, built on `AbstractListener` (see [AioPika](aiopika.md#abstractlistener)). Use it to subscribe with exclusive or shared consumption modes and pattern-based bindings.

## Use cases driving audit metadata

Velmios use case abstracts feed metadata through the service signature:

```python
await service.update(
    entity=entity_updated,
    event_name=EntityFunctionalEventName(PartStr("update")),
    use_case=UseCaseName(PartStr("update")),
    authentication_context=authentication_context,
    metadata={"changed": [{"path": "email", "old_value": "...", "new_value": "...", "kind": "updated"}]},
)
```

`UpdateUseCaseAbstract.build_audit_metadata()` builds `metadata["changed"]` from `FieldChange` records; override to surface request ids, request paths, etc. See the Velmios [Audit and events reference](../../velmios-lib/references/audit-and-events.md) for the realm-aware integration.

## Error handling

```python
from fastapi_factory_utilities.core.services.audit import AuditServiceError

try:
    await publisher.publish(GenericMessage(data=event), routing_key=key)
except AuditServiceError as exc:
    logger.error("Failed to publish audit event", error=exc)
    # exc.audit_event and exc.routing_key are available for retry queueing.
```

## Best practices

1. Define one publisher subclass per service (set `ROUTING_KEY_*` constants).
2. Always populate `entity`, `domain`, `service`, and `use_case` on the audit event; default `unknown` should only appear in test code.
3. Implement `pre_publish_hook` to scrub PII (passwords, raw tokens, etc.).
4. Pair the publisher with `AbstractAuditListenerService` exclusivity overrides when multiple consumers share a queue (see [AioPika](aiopika.md)).
5. Catch `AuditServiceError` only when the caller can persist the event for replay; otherwise let it bubble for observability.

## Reference

- `src/fastapi_factory_utilities/core/services/audit/__init__.py`
- `src/fastapi_factory_utilities/core/services/audit/objects.py`
- `src/fastapi_factory_utilities/core/services/audit/services.py`
- `src/fastapi_factory_utilities/core/services/audit/exceptions.py`
- See also: [AioPika](aiopika.md), [Repository pattern](repository-pattern.md), Velmios [audit and events](../../velmios-lib/references/audit-and-events.md).
