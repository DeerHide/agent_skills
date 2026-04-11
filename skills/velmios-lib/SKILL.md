---
name: velmios-lib
description: Use Velmios Core types, entities, authentication, permissions, resource APIs, and feature models when building Velmios platform microservices.
metadata:
  author: Deerhide
  version: 1.0.1
---

# Velmios Core Library

Shared library providing core types, domain entities, authentication, authorization, HTTP resource abstractions, and realm-scoped feature models for Velmios platform microservices. Built on top of `fastapi-factory-utilities`. When creating new Velmios microservices, you SHOULD also use the [`fastapi-factory-utilities` skill](../fastapi-factory-utilities/SKILL.md) for application scaffolding, plugins, configuration, observability, and [typed query filters](../fastapi-factory-utilities/references/query-utilities.md).

## When to use this skill?

- When you need Velmios **strongly-typed identifiers** (`RealmId`, `CustomerId`, `AdminId`, `SystemId`, `PublicUserId`, `FeatureForRealmEntityId`, `KratosIdentityId`)
- When you need **validated and display types** (`Email`, `Username`, `Feature`, safe URL types, and others under `velmios.core.types`)
- When you need **role enums** (`AdminRole`, `CustomerRole`, `PublicUserRole`, `SystemRole`) and **`AuthenticationPersona`** (import from `velmios.core.types`)
- When you use **domain entities** — full models (`AdminEntity`, `CustomerEntity`, …) or **lite** variants (`AdminLiteEntity`, `CustomerLiteEntity`) carried in `AuthenticationContext`
- When you implement **authentication** with `AuthenticationContext`, `AuthenticationResolver`, and **`DependsAuthenticationContext`**
- When you restrict **which token or session mechanisms** apply using **`AuthenticationType`** (internal JWT, customer JWT, Kratos session, none)
- When you implement **role-based permissions** with `AbstractPermissionsResolverService` and `AbstractDependsPermissionsRequired`
- When you build **read/CUD HTTP resource APIs** using `velmios.core.abstracts` and optional **`FeaturesAPI`** patterns
- When you integrate **Ory Kratos** and **Ory Hydra** via Velmios services (dual introspection paths for internal vs customer JWT)
- When you enforce **realm boundary rules** (Velmios realm vs tenant realms)

## Quick Start

See [assets/quick_start_example.py](assets/quick_start_example.py). Minimal endpoint pattern:

```python
from fastapi import Depends
from velmios.core.security import AuthenticationContext, AuthenticationType, DependsAuthenticationContext
from velmios.core.types import AuthenticationPersona

@app.get("/my-endpoint")
async def my_endpoint(
    auth: AuthenticationContext = Depends(
        DependsAuthenticationContext(
            authorized_personas=[AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER],
        )
    ),
) -> dict:
    return {"realm_id": str(auth.realm_id), "persona": auth.persona}
```

## Realm boundary rules

IMPORTANT: Velmios enforces strict realm boundaries via the reserved realm ID `00000000-0000-0000-0000-000000000000`.

- `AdminEntity` / `AdminLiteEntity` MUST use the Velmios realm ID.
- `CustomerEntity` / `CustomerLiteEntity` MUST NOT use the Velmios realm ID.
- `SystemEntity` with `SystemRole.SYSTEM` MUST use the Velmios realm ID; with `SystemRole.CUSTOMER` MUST NOT.

These rules are enforced by Pydantic validators and MUST NOT be bypassed.

## Authentication flow (summary)

1. The client sends a Bearer token (internal or customer Hydra JWT) and/or a Kratos session cookie, depending on what the app registers on `AuthenticationResolver`.
2. `DependsAuthenticationContext` configures the resolver with **authorized personas** and optionally **supported authentication types**, then calls `authenticate(request)`.
3. **Internal Hydra JWT** resolves to `AuthenticationPersona.SYSTEM` with a `SystemEntity` and JWT scopes on the context.
4. **Customer Hydra JWT** resolves to `ADMIN` or `CUSTOMER` with **lite** admin or customer entities and scopes.
5. **Kratos session** (when registered) resolves to **lite** `AdminLiteEntity` or `CustomerLiteEntity` with realm checks against optional `realm_id` query parameter.
6. **`AuthenticationContext`** exposes `realm_id`, `persona`, `entity`, `scopes` (`list[OAuth2Scope]` from `fastapi_factory_utilities`). There is **no** built-in `Depends*` that validates a single OAuth2 scope; enforce scopes in the handler, a small custom dependency, or the permissions layer.

## Dependency injection (common symbols)

| Dependency / type | Returns / role |
|---|---|
| `DependsAuthenticationContext(...)` | Callable dependency: authenticates, checks persona (and optional auth types), returns `AuthenticationContext` |
| `depends_authentication_resolver()` | `AuthenticationResolver` with **internal + customer** JWT (`velmios.core.security`) |
| `depends_authentication_resolver_with_kratos_session()` | Same plus **Kratos session** — defined in **`velmios.core.security.resolvers`** (import from that module when wiring apps) |
| `depends_velmios_internal_jwt_authentication_service()` | Internal JWT auth service |
| `depends_velmios_customer_jwt_authentication_service()` | Customer JWT auth service |
| `depends_velmios_kratos_whoami_service()` | Kratos whoami HTTP service |
| `depends_velmios_kratos_identity_service()` | Kratos identity admin API service |

Hydra wiring uses `depends_velmios_internal_hydra_introspect_service`, `depends_velmios_customer_hydra_introspect_service`, and related helpers in `velmios.core.services.hydra`.

## Reference documentation

### Types

| Reference | Description |
|---|---|
| [Functional Types](references/functional-types.md) | UUID identifiers, `AuthenticationPersona`, `Feature`, `FeatureForRealmEntityId`, `KratosIdentityId` |
| [Validated Types](references/validated-types.md) | Input-validated types (`Email`, `Username`, …) |
| [Display Types](references/display-types.md) | UI-oriented types (`ColorHexCode`, `IconCode`) |
| [Safe URL types](references/safe-url-types.md) | HTTPS Velmios host constraints (`VelmiosSafeUrl`, API/auth/portal variants) |
| [Role Enums](references/role-enums.md) | Role definitions for all persona types |

### Entities

| Reference | Description |
|---|---|
| [Entities](references/entities.md) | Full and lite entities, realm validation, feature aggregates |

### Security

| Reference | Description |
|---|---|
| [Authentication](references/authentication.md) | `AuthenticationContext`, `AuthenticationResolver`, `AuthenticationType` |
| [Authorization Dependencies](references/authorization-dependencies.md) | `DependsAuthenticationContext`, public/none, scope notes |
| [JWT Authentication](references/jwt-authentication.md) | Internal vs customer JWT stack, payloads, JWKS |
| [Kratos Authentication](references/kratos-authentication.md) | Session authentication and Kratos services |

### HTTP patterns

| Reference | Description |
|---|---|
| [Features and resource APIs](references/features-and-resource-apis.md) | `FeaturesForRealm*`, abstract resource APIs, auth permission hooks |

### Services

| Reference | Description |
|---|---|
| [Permissions](references/permissions.md) | `Permission`, `AbstractPermissionsResolverService`, `AbstractDependsPermissionsRequired` |

## Best practices

1. Import public types from `velmios.core.types`, entities from `velmios.core.entities`, security primitives from `velmios.core.security`. Avoid deep imports from private submodules unless you maintain the library.
2. Prefer **`DependsAuthenticationContext`** for persona (and optional mechanism) gating instead of duplicating resolver logic in routes.
3. For machine-to-machine routes, combine **`AuthenticationPersona.SYSTEM`**, **`AuthenticationType.HYDRA_INTERNAL_JWT`**, and explicit **scope** or **permission** checks; never rely on a `*` wildcard scope in production.
4. Extend **`AbstractPermissionsResolverService`** per microservice for role-to-permission maps; use **`AbstractDependsPermissionsRequired`** subclasses wired with `Depends(DependsAuthenticationContext(...))` (or your app’s auth dependency).
5. Respect realm boundary rules on every entity construction path.
6. Use **`SearchableEntity`** / factory query models from `fastapi-factory-utilities` for list filters when exposing Velmios models over HTTP (see the fastapi-factory skill).

## Related skills

- [fastapi-factory-utilities](../fastapi-factory-utilities/SKILL.md) – Plugins, configuration, observability, repositories, **query utilities**.
