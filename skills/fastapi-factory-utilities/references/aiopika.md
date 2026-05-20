# AioPika RabbitMQ Messaging

The AioPika plugin provides RabbitMQ message broker integration with validated naming, fluent builders, robust connection handling, and OpenTelemetry instrumentation.

## When to use

- Building message-driven architectures with RabbitMQ.
- Publishing audit / domain events with consistent routing keys.
- Subscribing to topic exchanges with wildcard patterns.
- Decoupling services with durable message queues.

## Module entry points

```python
from fastapi_factory_utilities.core.plugins.aiopika import (
    AbstractListener,
    AbstractPublisher,
    AiopikaPlugin,
    AiopikaPluginBaseError,
    AiopikaPluginConfigError,
    EventRoutingKeyBuilder,
    Exchange,
    ExchangeName,
    ExchangeNameBuilder,
    GenericMessage,
    ListenerRoutingKeyBuilder,
    PartStr,
    Queue,
    QueueName,
    QueueNameBuilder,
    RoutingKey,
    depends_aiopika_robust_connection,
)
```

## Validated string types

| Type | Rules | Notes |
|---|---|---|
| `PartStr` | `^[a-zA-Z0-9\-_]+$`, length 3–32 | Single routing key segment. `*` is allowed as a wildcard for listener patterns. |
| `AbstractName` | `^[a-zA-Z0-9\-_.*]+$`, length 3–255 | Multi-segment dotted name; can contain `*` per segment for topic patterns. |
| `RoutingKey`, `QueueName`, `ExchangeName` | Same as `AbstractName` | Strongly-typed subclasses for self-documenting APIs. |

`AbstractName.get_parts()` returns the per-segment `PartStr` list — useful when comparing patterns or extracting metadata.

## Fluent builders

Use the builders to construct routing keys, queue names, and exchange names instead of hand-crafted strings.

```python
from fastapi_factory_utilities.core.plugins.aiopika import (
    EventRoutingKeyBuilder,
    ListenerRoutingKeyBuilder,
    QueueNameBuilder,
    ExchangeNameBuilder,
    PartStr,
)


publish_key = (
    EventRoutingKeyBuilder(prefix=PartStr("all"))
    .set_domain_name("library")
    .set_service_name("book_service")
    .set_entity_name("book")
    .set_functional_event_name("created")
    .build()
)


listener_pattern = (
    ListenerRoutingKeyBuilder(prefix=PartStr("all"))
    .set_domain_name("library")
    .set_service_name("book_service")
    .build()
)


queue_name = (
    QueueNameBuilder(prefix="all")
    .set_domain_name("library")
    .set_service_name("book_service")
    .set_entity_name("book")
    .set_functional_queue_name("audit_replay")
    .build()
)


exchange_name = (
    ExchangeNameBuilder(prefix="all")
    .set_domain_name("library")
    .set_service_name("book_service")
    .build()
)
```

- `EventRoutingKeyBuilder` produces `{prefix?}.{domain}.{service}.{entity}.{functional_event}` with concrete `PartStr` parts; this is the pattern used by `AbstractAuditPublisherService` (see [Audit service](audit-service.md)).
- `ListenerRoutingKeyBuilder` initializes each segment with `*` so consumers subscribe to topic patterns by overriding the parts they care about.
- `QueueNameBuilder` / `ExchangeNameBuilder` skip empty segments — handy when modeling shared vs service-specific queues.

## GenericMessage

Type-safe message wrapper backed by Pydantic.

```python
class GenericMessage(BaseModel, Generic[GenericMessageData]):
    data: GenericMessageData
```

Methods:

- `get_headers() / set_headers(headers)` — interact with AMQP headers.
- `to_aiopika_message()` — convert to the raw `aio_pika.Message`.
- `set_incoming_message(...)` — used internally by `AbstractListener` to bind the incoming AMQP message for ack/reject.
- `ack()`, `reject(requeue)` — proxy methods on the underlying incoming message.

Message bodies are encoded / decoded as UTF-8 JSON (`json.loads(body.decode("utf-8"))`); invalid bytes or invalid JSON are rejected with `requeue=True` so an upstream consumer can inspect or DLQ them.

## AbstractListener

```python
class OrderListener(AbstractListener[OrderMessage]):
    def __init__(self, queue: Queue, exclusive: bool | None = None) -> None:
        super().__init__(queue=queue, name="order_listener", exclusive=exclusive)

    async def on_message(self, message: OrderMessage) -> None:
        await process_order(message.data)
        await message.ack()
```

- The concrete `GenericMessage` subclass is inferred from `__orig_bases__`.
- `exclusive` defaults to `queue.exclusive`; pass `True` / `False` on `__init__` to override per listener instance — useful when one queue serves both an exclusive primary consumer and shared replay consumers.
- `_on_message` (private) is the wire-level callback. It decodes UTF-8 JSON, validates the message, and dispatches to `on_message`. Decoding / validation failures `reject(requeue=True)` and log a structured error.

## AbstractPublisher

```python
class OrderPublisher(AbstractPublisher[OrderMessage]):
    async def publish_order(self, order: OrderData) -> None:
        message = OrderMessage(data=order)
        routing_key = build_order_routing_key(order)
        await self.publish(message=message, routing_key=routing_key)
```

`AbstractAuditPublisherService` extends this base; see [Audit service](audit-service.md) for the audit-specific wiring.

## Queue & Exchange

```python
queue = Queue(connection=connection, name=QueueName("orders"), durable=True, auto_delete=False, exclusive=False)
await queue.setup()


exchange = Exchange(name=ExchangeName("orders"), exchange_type=ExchangeType.TOPIC, durable=True, auto_delete=False)
exchange.set_robust_connection(connection)
await exchange.setup()
```

Both `Queue` and `Exchange` defer declaration to `setup()` so failures surface during startup. They share `set_robust_connection(...)` for reconnection-aware setups.

## AiopikaPlugin

Bridges the FastAPI application to a robust RabbitMQ connection.

```python
plugin = AiopikaPlugin()
```

The plugin builds an `aio_pika.connect_robust` connection from `RabbitMQCredentialsConfig` (see `core.utils.rabbitmq_configs`). Connection failures (`AMQPConnectionError`) are wrapped in `AiopikaPluginBaseError("Failed to connect to RabbitMQ")` so the app's startup pipeline reports a single, structured error.

Access the connection from a request:

```python
from fastapi import Depends
from fastapi_factory_utilities.core.plugins.aiopika.depends import depends_aiopika_robust_connection


@router.get("/status")
async def status(connection = Depends(depends_aiopika_robust_connection)):
    return {"connected": not connection.is_closed}
```

## OpenTelemetry instrumentation

When the OpenTelemetry plugin is enabled, the AioPika plugin emits publish / consume spans with routing keys, message sizes, and durations. Listener decoding failures are recorded on the active span and increment the global error counters.

## Error handling

```python
from fastapi_factory_utilities.core.plugins.aiopika import AiopikaPluginBaseError

try:
    await publisher.publish(message=message, routing_key=key)
except AiopikaPluginBaseError as exc:
    logger.error("Failed to publish message", error=exc, routing_key=str(key))
```

`AiopikaPluginBaseError` wraps publish failures (AMQP channel / connection errors) so callers do not have to know the underlying `aio_pika` exception types. `AuditServiceError` re-wraps these for audit-flow consumers (see [Audit service](audit-service.md)).

## Best practices

1. Use the builders for routing keys, queue names, and exchange names — never hard-code dotted strings.
2. Use `PartStr` wildcards (`*`) only for listener patterns; producers should always emit concrete keys.
3. Subscribe with `exclusive=True` for high-throughput consumers and `exclusive=False` for shared queues; override the queue default when both modes coexist.
4. Treat `requeue=True` carefully — pair with a DLQ to avoid infinite re-delivery on malformed payloads.
5. Always call `setup()` on queues and exchanges before publishing or consuming; failures during `setup()` are easier to diagnose than surprise channel errors later.

## Reference

- `src/fastapi_factory_utilities/core/plugins/aiopika/__init__.py`
- `src/fastapi_factory_utilities/core/plugins/aiopika/types.py`
- `src/fastapi_factory_utilities/core/plugins/aiopika/builders.py`
- `src/fastapi_factory_utilities/core/plugins/aiopika/queue.py`
- `src/fastapi_factory_utilities/core/plugins/aiopika/exchange.py`
- `src/fastapi_factory_utilities/core/plugins/aiopika/message.py`
- `src/fastapi_factory_utilities/core/plugins/aiopika/listener/abstract.py`
- `src/fastapi_factory_utilities/core/plugins/aiopika/publisher/abstract.py`
- `src/fastapi_factory_utilities/core/plugins/aiopika/plugins.py`
