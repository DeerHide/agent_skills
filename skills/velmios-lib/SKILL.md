---
name: velmios-lib
description: Use Velmios Core types, lite entities, dual JWT and Kratos authentication, composable permissions, realm-isolated resource APIs and use cases, features API with global overrides, audit events, and Velmios application scaffolding when building Velmios platform microservices.
metadata:
  author: Deerhide
  version: 2.0.0
---

# Velmios Core Library

Shared library providing core types, lite domain entities, authentication, composable permissions, realm-isolated HTTP resource APIs and use-case abstracts, realm-aware audit events, and Velmios application scaffolding for the Velmios platform microservices. Built on top of `fastapi-factory-utilities` (>= 5.x). When creating new Velmios microservices, you SHOULD also use the [`fastapi-factory-utilities` skill](../fastapi-factory-utilities/SKILL.md) for application scaffolding, plugins, configuration, observability, [typed query filters](../fastapi-factory-utilities/references/query-utilities.md), and [PUT update reconciliation](../fastapi-factory-utilities/references/api-response-and-update.md).

## When to use this skill?

- When you need Velmios **strongly-typed identifiers** (`RealmId`, `CustomerId`, `AdminId`, `SystemId`, `PublicUserId`, `FeatureForRealmEntityId`, `KratosIdentityId`).
- When you need **validated, display, and safe URL types** (`Email`, `Username`, `Feature`, `FeatureGlobalOverride`, Velmios HTTPS URL types).
- When you need **role enums** (`AdminRole`, `CustomerRole`, `PublicUserRole`, `SystemRole`) and **`AuthenticationPersona`** (including `PARTIAL` for incomplete Kratos registrations and `NONE` for explicit anonymous routes).
- When you use Velmios **lite entities** (`AdminLiteEntity`, `CustomerLiteEntity`, `PublicUserEntity`, `SystemEntity`) carried on `AuthenticationContext`. Full non-lite admin / customer entities are no longer exported.
- When you implement **authentication** with `AuthenticationContext`, `AuthenticationResolver`, `DependsAuthenticationContext`, and `DependsAuthenticationContextWithKratosSessionSupport`.
- When you restrict **which token or session mechanisms** apply using `AuthenticationType` (internal JWT, customer JWT, Kratos session, none).
- When you implement **composable role-based permissions** with `Permission`, `PermissionRequirement` (`&` / `|` / `predicate(...)`), `AbstractPermissionsResolverService`, and `AbstractDependsPermissionsRequired`.
- When you build **realm-isolated HTTP resource APIs** using `RResourceAPIAbstract`, `CUDResourceAPIAbstract`, and `CRUDResourceAPIAbstract` together with the Velmios **use-case abstracts** (`CreateUseCaseAbstract`, `UpdateUseCaseAbstract`, `DeleteUseCaseAbstract`, `SearchUseCaseAbstract`) and their `Basic*` variants.
- When you wire **realm-scoped feature flags** via `FeaturesAPI` (search, get-by-id, PUT update), `FeaturesUpdateUseCase`, `FeatureDeclaration`, and `DependsFeaturesService.register_features`.
- When you publish **realm-aware audit events** with `GenericAuditService`, `RealmIsolatedAuditEvent`, and `RealmIsolatedPersistedAuditableEntity`.
- When you scaffold a microservice with `VelmiosApplicationAbstract` / `VelmiosApplicationBuilderAbstract`, dual JWT bearer configs (internal vs customer), and JWKS store wiring.
- When you wire **centralized exception handling** with `register_security_exception_handlers`, `HTTPExceptionDetailEnricher`, and the `velmios.security.auth_failures` OpenTelemetry counter.
- When you enforce **realm boundary rules** (Velmios realm vs tenant realms) on entities, use cases, and audit events.
- When you integrate **Ory Kratos** (session, identity admin) and **Ory Hydra** (dual introspection paths for internal vs customer JWT) via Velmios services.

## Quick Start

See [assets/quick_start_example.py](assets/quick_start_example.py). Minimal endpoint pattern:

```python
from fastapi import Depends
from velmios.core.security import (
    AuthenticationContext,
    AuthenticationType,
    DependsAuthenticationContext,
)
from velmios.core.types import AuthenticationPersona


@app.get("/my-endpoint")
async def my_endpoint(
    auth: AuthenticationContext = Depends(
        DependsAuthenticationContext(
            authorized_personas=[AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER],
        )
    ),
) -> dict:
    return {"realm_id": str(auth.realm_id), "persona": auth.persona, "identity_id": str(auth.identity_id) if auth.identity_id else None}
```

## Realm boundary rules

IMPORTANT: Velmios enforces strict realm boundaries via the reserved realm ID `00000000-0000-0000-0000-000000000000`.

- `AdminLiteEntity` MUST use the Velmios realm ID.
- `CustomerLiteEntity` MUST NOT use the Velmios realm ID.
- `SystemEntity` with `SystemRole.SYSTEM` MUST use the Velmios realm ID; with `SystemRole.CUSTOMER` MUST NOT.
- `PublicUserEntity` MUST NOT use the Velmios realm ID and defaults to `PublicUserRole.GUEST` when `id` is `None`.

These rules are enforced by Pydantic validators and MUST NOT be bypassed. Use-case abstracts can opt into a controlled cross-realm bypass through `allow_cross_realm_when_velmios_admin_or_system` (defaults to `True`).

## Authentication flow (summary)

1. The client sends an internal or customer Hydra **JWT** Bearer token and/or a **Kratos session cookie**, depending on the resolver registered on the app.
2. `DependsAuthenticationContext` (or the Kratos-session-aware variant) configures the resolver with **authorized personas** and optionally **supported authentication types**, then calls `authenticate(request)`.
3. **Internal Hydra JWT** → `AuthenticationPersona.SYSTEM` with a `SystemEntity` and JWT scopes on the context.
4. **Customer Hydra JWT** → `ADMIN` or `CUSTOMER` with **lite** entities (validated by Pydantic) and scopes.
5. **Kratos session** → `AdminLiteEntity` if `metadata_public.realm_id == VELMIOS_REALM_ID`; otherwise `CustomerLiteEntity` cross-checked against the optional `realm_id` query parameter; identities missing `metadata_public` and `traits.realm_id` resolve to `AuthenticationPersona.PARTIAL`.
6. `AuthenticationContext` exposes `realm_id`, `identity_id`, `persona`, `entity`, and `scopes` (`list[OAuth2Scope]`). Scopes are not enforced by a built-in dependency; layer scope checks via permissions or small custom dependencies.

## Dependency injection (common symbols)

| Dependency / type | Returns / role |
|---|---|
| `DependsAuthenticationContext(...)` | Authenticates, checks persona/auth-type, returns `AuthenticationContext` |
| `DependsAuthenticationContextWithKratosSessionSupport(...)` | Same contract using the Kratos session-aware resolver |
| `depends_authentication_resolver()` | `AuthenticationResolver` with internal + customer JWT |
| `depends_authentication_resolver_with_kratos_session()` | Same plus Kratos session (`velmios.core.security.resolvers`) |
| `depends_velmios_internal_jwt_authentication_service()` | Internal JWT auth service |
| `depends_velmios_customer_jwt_authentication_service()` | Customer JWT auth service |
| `depends_velmios_kratos_whoami_service()` | Kratos whoami HTTP service |
| `depends_velmios_kratos_identity_service()` | Kratos identity admin API service |
| `depends_velmios_internal_hydra_introspect_service()` | Internal Hydra token introspection service |
| `depends_velmios_customer_hydra_introspect_service()` | Customer Hydra token introspection service |

## Reference documentation

### Types

| Reference | Description |
|---|---|
| [Functional Types](references/functional-types.md) | UUID identifiers, `AuthenticationPersona`, `Feature`, `FeatureGlobalOverride`, `FeatureForRealmEntityId`, `KratosIdentityId` |
| [Validated Types](references/validated-types.md) | Input-validated types (`Email`, `Username`, …) |
| [Display Types](references/display-types.md) | UI-oriented types (`ColorHexCode`, `IconCode`) |
| [Safe URL types](references/safe-url-types.md) | HTTPS Velmios host constraints (`VelmiosSafeUrl`, API/auth/portal variants) |
| [Role Enums](references/role-enums.md) | Role definitions for all persona types |

### Entities

| Reference | Description |
|---|---|
| [Entities](references/entities.md) | Lite entities, realm validators, `PublicUserEntity`, `SystemEntity`, feature aggregates |

### Security

| Reference | Description |
|---|---|
| [Authentication](references/authentication.md) | `AuthenticationContext`, `AuthenticationResolver`, `AuthenticationType`, `PARTIAL` persona, `identity_id` |
| [Authorization Dependencies](references/authorization-dependencies.md) | `DependsAuthenticationContext`, Kratos session variant, scope notes |
| [JWT Authentication](references/jwt-authentication.md) | Internal vs customer JWT stack, payloads, JWKS, flexible `ext` claim |
| [Kratos Authentication](references/kratos-authentication.md) | Session authentication, identity admin, `metadata_public` + `metadata_admin` fallback |
| [Exception handling](references/exception-handling.md) | `register_security_exception_handlers`, `HTTPExceptionDetailEnricher`, OTel auth-failure metrics, 401/403/422 envelopes |

### HTTP patterns

| Reference | Description |
|---|---|
| [Features and resource APIs](references/features-and-resource-apis.md) | `FeaturesAPI` (search, get-by-id, PUT update), `FeaturesUpdateUseCase`, `FeatureDeclaration`, `DependsFeaturesService.register_features`, resource API base classes |
| [Use cases](references/use-cases.md) | `UseCaseAbstract`, `AuthenticatedUseCaseAbstract`, `Create/Update/Delete/SearchUseCaseAbstract`, hooks (`pre_*`, `post_*`, `can_be_*`), `Basic*` variants, segmentation/not-allowed errors, cross-realm bypass |
| [Audit and events](references/audit-and-events.md) | `GenericService`, `GenericAuditService`, `RealmIsolatedAuditEvent`, `RealmIsolatedPersistedAuditableEntity`, audit `realm_id` and `changed` metadata |

### Services and application

| Reference | Description |
|---|---|
| [Permissions](references/permissions.md) | `Permission`, `PermissionRequirement` (`&` / `|` / `predicate`), `AbstractPermissionsResolverService`, `AbstractDependsPermissionsRequired` |
| [Application](references/application.md) | `VelmiosApplicationAbstract`, builder, default plugins, dual JWT configs, JWKS store wiring, exception handler registration, auto-redirect middleware |

## Best practices

1. Import public types from `velmios.core.types`, entities from `velmios.core.entities`, security primitives from `velmios.core.security`, abstracts from `velmios.core.abstracts`, and application primitives from `velmios.core.app`. Avoid deep imports from private submodules unless you maintain the library.
2. Prefer `DependsAuthenticationContext` for persona (and optional mechanism) gating instead of duplicating resolver logic in routes. Use the Kratos-session-aware variant when routes must accept browser sessions.
3. Enforce machine-to-machine routes with `AuthenticationPersona.SYSTEM`, `AuthenticationType.HYDRA_INTERNAL_JWT`, and explicit scope or permission checks. Never rely on a `*` wildcard scope in production.
4. Compose permission requirements with `Permission(...)`, `&`, `|`, and `predicate(...)`; subclass `AbstractDependsPermissionsRequired` to wire `Depends(DependsAuthenticationContext(...))` (or your app's auth dependency).
5. Build resource APIs by combining one Velmios resource API base (`RResourceAPIAbstract`, `CUDResourceAPIAbstract`, `CRUDResourceAPIAbstract`) with the use-case abstracts and a service that extends `ServiceCUDAbstract` / `ServiceSearchAbstract`. Use `Basic*Usecase` when default hooks are enough.
6. Respect realm boundary rules on every entity construction path; rely on `allow_cross_realm_when_velmios_admin_or_system` rather than ad-hoc bypasses.
7. Use `SearchableEntity` / `ApiEntityAbstract` from `fastapi-factory-utilities` for entities exposed over HTTP (see the fastapi-factory skill).
8. Always call `register_security_exception_handlers(app, http_exception_detail_enricher=...)` so 401, 403, and validation 422 envelopes (plus telemetry) stay consistent across services.

## Related skills

- [fastapi-factory-utilities](../fastapi-factory-utilities/SKILL.md) — plugins, configuration, observability, repositories, query utilities, PUT reconciliation, audit pipeline, CSRF/validation handlers.
