---
name: fastapi-factory-utilities
description: Build FastAPI microservices with plugins, typed PUT updates and reconciliation, message brokers, Redis/Valkey, S3/MinIO via aioboto3, OAuth2/OIDC, OpenTelemetry, CSRF and validation handlers, Uvicorn/Hypercorn/Granian, audit field redaction, and structured logging.
metadata:
  author: Deerhide
  version: 2.3.0
---
# FastAPI Factory Utilities

A library for building production-ready FastAPI microservices with a plugin-based architecture, typed HTTP query filters, response/update model builders, OAuth2/OIDC integration (Hydra, Kratos), an audit-event pipeline, and built-in CSRF, validation, and exception handling.

## When to use this skill?

- Use this skill when building FastAPI microservices with the `fastapi_factory_utilities` library (v7.x, aligned through **v7.2.x**).
- Use this skill when implementing plugin-based architectures and lifecycle hooks (`configure`, `on_startup`, `on_shutdown`; plugins use `on_load` / `on_startup` / `on_shutdown`).
- Use this skill when setting up OAuth2/OIDC authentication with Hydra (introspection, JWKS, optional introspect cache) or Kratos (session, admin identity, `delete_session`).
- Use this skill when configuring MongoDB with Beanie ODM, with `PersistedEntity` mixing in `SearchableEntity` and `ApiResponseModelAbstract`, including optional CSFLE via `Settings.encrypted_fields`.
- Use this skill when implementing RabbitMQ message brokers with AioPika (`AbstractManagedListener`, `PREFETCH_COUNT` / `prefetch_count`, `on_gate_saturated`, concurrency gates, delay-retry topology).
- Use this skill when setting up background task processing with Taskiq and Redis (`name_suffix` key prefixes, `prune_unregistered_schedules`, `ensure_cron_schedule`, cron `SET NX` lock).
- Use this skill when integrating MinIO or S3-compatible object storage via the async `S3Plugin` (`aioboto3`, named buckets, `S3BucketDepends`).
- Use this skill when using a standalone Redis / Valkey client via `RedisPlugin` (`name_suffix`, `build_key`, `depends_redis`).
- Use this skill when configuring OpenTelemetry for distributed tracing and metrics.
- Use this skill when implementing structured logging with `structlog` (OTel `trace_id`/`span_id`, probe access-log filter).
- Use this skill when using dependency injection patterns with FastAPI's `Depends` system (typed resource depends, in-memory mockers).
- Use this skill when creating mock resources for testing (AioHttp, in-memory ODM repositories).
- Use this skill when implementing repository patterns for data access (`AbstractRepository`, `AbstractRepositoryInMemory`).
- Use this skill when configuring health checks and status services.
- Use this skill when implementing JWT Bearer authentication with JWKS verification (`JWTBearerAuthenticationConfig`, `JWTBearerAuthenticationConfigBuilder`, configurable bearer extraction strategies, `ExpiredJWTError`, introspect cache fields).
- Use this skill when implementing typed list/search query parameters (`QueryAbstract`, `QueryResolver`, `QueryFieldOperation`, `build_query_filter_kwargs`) with coercion for `UUID`, `NewType`, `enum.Flag` / `IntFlag` / `Enum` / `StrEnum`, nested sequence filters, and lists for `in` / `nin`, plus optional sparse fieldset projection via the `fields` query param on search endpoints.
- Use this skill when defining API response and PUT update contracts (`ApiResponseModelAbstract`, `ApiResponseField`, `ApiField`, `ApiEntityAbstract`, `UpdateableField`, `reconcile_update_request`).
- Use this skill when registering exception handlers for request validation (HTTP 422) and CSRF (HTTP 403) with `register_exception_handlers` / `register_csrf_protect_exception_handler` (manual registration in `configure()`).
- Use this skill when publishing audit events through `AbstractAuditPublisherService` / `AuditEventObject` / `PersistedAuditableEntity` and the `{prefix}.{domain}.{service}.{what}.{why}` routing-key pattern; mark PII with `Redacted()` so the default `pre_publish_hook` can `redact(entity)`.
- Use this skill when running the ASGI app under Uvicorn, Hypercorn, or Granian via `build_as_uvicorn_utils`, `build_as_hypercorn_utils`, `build_as_granian_utils`, or `build_and_serve`.

---

A library for building production-ready FastAPI microservices with plugin-based architecture.

## Quick Start

See [assets/quick_start_example.py](assets/quick_start_example.py) for a minimal application setup.

## Dependency Injection and Testing

The library uses FastAPI's `Depends` for dependency injection. Plugins expose resources via dependency functions (e.g., `AioHttpResourceDepends`, `S3BucketDepends`, `depends_redis`, `depends_status_service`, `depends_scheduler_component`).

For testing, several plugins provide mockers to create mock resources:

- **AioHttp**: `build_mocked_aiohttp_resource`, `build_mocked_aiohttp_response` — mock HTTP clients and responses.
- **ODM**: `AbstractRepositoryInMemory` — in-memory repository for unit testing without MongoDB (also usable for `PersistedAuditableEntity`).
- See [AioHttp reference](references/aiohttp.md#testing-with-mocks) and [Repository Pattern](references/repository-pattern.md#testing-with-abstractrepositoryinmemory) for detailed mocking examples.

## Reference Documentation

### Core

| Reference | Description |
|-----------|-------------|
| [Application Framework](references/application-framework.md) | `ApplicationAbstract`, builders, plugin lifecycle, Uvicorn/Hypercorn/Granian server utilities, `register_exception_handlers` |
| [Configuration](references/configuration-utilities.md) | YAML loading, environment variables, type-safe `RootConfig` |
| [Logging](references/logging-utilities.md) | Structured logging with `structlog` |
| [Status Service](references/status-service.md) | Health and readiness monitoring, `PluginStatusMixin` |
| [CSRF and Validation](references/csrf-and-validation.md) | `fastapi-csrf-protect` integration, validation handler returning HTTP 422 with structured `detail` |

### Plugins

| Reference | Description |
|-----------|-------------|
| [ODM Plugin (MongoDB)](references/odm-plugin.md) | MongoDB/Beanie integration, generic `PersistedEntity[Id]`, `ODMQueryBuilder` / `ODMFindQuery`, `id` → `_id` mapping, CSFLE |
| [Repository Pattern](references/repository-pattern.md) | Type-safe data access, in-memory testing, `PersistedAuditableEntity` flow |
| [AioHttp HTTP Client](references/aiohttp.md) | HTTP client with connection pooling, mocking utilities |
| [AioPika RabbitMQ](references/aiopika.md) | Message publishing/consuming, `AbstractManagedListener`, `PREFETCH_COUNT`, `on_gate_saturated`, concurrency gates, delay-retry topology |
| [S3 Plugin (MinIO / S3)](references/s3-plugin.md) | Async aioboto3 client, multi-bucket YAML, `S3BucketDepends` DI, STORAGE status |
| [Redis Plugin](references/redis-plugin.md) | Standalone Redis/Valkey client, `name_suffix` + `build_key`, `depends_redis` |
| [OpenTelemetry](references/opentelemetry.md) | Distributed tracing and metrics |
| [Taskiq Tasks](references/taskiq.md) | Background task processing with Redis; `name_suffix` key prefixes; `prune_unregistered_schedules`; cron single-flight lock |

### Services

| Reference | Description |
|-----------|-------------|
| [Hydra Service](references/hydra-service.md) | OAuth2 token introspection, JWKS, client credentials, `HydraTokenIntrospectObject` |
| [Kratos Service](references/kratos-service.md) | Identity management, session validation, admin `delete_session` |
| [Audit Service](references/audit-service.md) | `AuditEventObject`, `UseCaseName`, `AbstractAuditPublisherService`, `PersistedAuditableEntity`, `Redacted` / `redact`, routing-key pattern |

### Security

| Reference | Description |
|-----------|-------------|
| [JWT Authentication](references/jwt-authentication.md) | JWT Bearer validation, JWKS store, custom verifiers, configurable bearer extraction strategies, `ExpiredJWTError` |

### API

| Reference | Description |
|-----------|-------------|
| [Query utilities](references/query-utilities.md) | Typed HTTP filters, sorting, `SearchableEntity`, `QueryFilterNestedAbstract`, `QueryResolver`, ODM translation, type coercion, `fields` sparse fieldset |
| [API response & PUT update model](references/api-response-and-update.md) | `ApiResponseModelAbstract`, `ApiResponseField`, `ApiField`, `ApiEntityAbstract`, `UpdateableField`, PUT request models, `reconcile_update_request` |
| [Pagination](references/pagination.md) | Type-safe pagination types |
| [Ory Utilities](references/ory-utilities.md) | Ory API pagination helpers |

## Best Practices

1. **Plugin Order** — Load plugins in dependency order (ODM before repositories).
2. **Configuration** — Use YAML files with `${ENV_VAR:default}` syntax.
3. **Lifecycle** — Keep `configure()` lightweight, use `on_startup()` for connections.
4. **Observability** — Enable OpenTelemetry in production.
5. **Logging** — Use JSON mode in production for log aggregation.
6. **Testing** — Use mockers from the aiohttp plugin and `AbstractRepositoryInMemory` for unit tests.
7. **Audit events** — Always set `entity`, `domain`, `service`, and `use_case` on `AuditEventObject`; mark sensitive fields with `Redacted()`; use `AbstractAuditPublisherService.publish` and react to `AuditServiceError`.
8. **PUT updates** — Mark client-writable fields with `UpdateableField`, call `reconcile_update_request`, and surface `changed`, `ignored_paths`, and `unchanged_paths` in audit metadata.
9. **Exception handling** — Always register validation, CSRF, and (in downstream apps) security exception handlers at app configuration time so that 401/403/422 envelopes stay consistent.
10. **ASGI server choice** — Prefer `build_and_serve` and select Uvicorn, Hypercorn, or Granian from configuration.
