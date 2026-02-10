---
name: velmios-lib
description: Use Velmios Core types, entities, authentication, and permissions when building Velmios platform microservices.
metadata:
  author: Deerhide
  version: 1.0.0
---

# Velmios Core Library

Shared library providing core types, domain entities, authentication, and authorization utilities for all Velmios platform microservices. Built on top of `fastapi-factory-utilities`. When creating new Velmios microservices, you SHOULD also use the [`fastapi-factory-utilities` skill](../fastapi-factory-utilities/SKILL.md) for application scaffolding, plugins, configuration, and observability.

## When to use this skill?

- When you need to use Velmios **strongly-typed identifiers** (`RealmId`, `CustomerId`, `AdminId`, `SystemId`, `PublicUserId`)
- When you need to use Velmios **validated types** (`Email`, `Username`, `PhoneNumber`, `Name`, `Country`, `ColorHexCode`, `IconCode`)
- When you need to use Velmios **role enums** (`AdminRole`, `CustomerRole`, `PublicUserRole`, `SystemRole`)
- When you create or consume Velmios **domain entities** (`AdminEntity`, `CustomerEntity`, `PublicUserEntity`, `SystemEntity`)
- When you implement **authentication** with `AuthenticationContext` and `AuthenticationResolver`
- When you add **persona-based authorization** to FastAPI endpoints using `DependsAuthorizedPersona`
- When you add **scope-based authorization** for system-to-system calls using `DependsSystemHasScope`
- When you implement **role-based permissions** using `AbstractPermissionsResolverService`
- When you integrate with **Ory Kratos** for session authentication via Velmios Kratos services
- When you integrate with **Ory Hydra** for JWT/OAuth2 authentication via Velmios JWT services
- When you need to enforce **realm boundary rules** (Velmios realm vs tenant realms)

## Quick Start

See [assets/quick_start_example.py](assets/quick_start_example.py) for a complete example of a FastAPI endpoint using Velmios authentication and authorization.

```python
from fastapi import Depends
from velmios.core.security import (
    AuthenticationContext,
    AuthenticationPersona,
    DependsAuthorizedPersona,
)

@app.get("/my-endpoint")
async def my_endpoint(
    auth: AuthenticationContext = Depends(
        DependsAuthorizedPersona([AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER])
    ),
) -> dict:
    return {"realm_id": str(auth.realm_id), "persona": auth.persona}
```

## Realm Boundary Rules

IMPORTANT: Velmios enforces strict realm boundaries via the reserved realm ID `00000000-0000-0000-0000-000000000000`.

- `AdminEntity` MUST use the Velmios realm ID.
- `CustomerEntity` MUST NOT use the Velmios realm ID.
- `SystemEntity` with `SystemRole.SYSTEM` MUST use the Velmios realm ID; with `SystemRole.CUSTOMER` MUST NOT.
- These rules are enforced by Pydantic validators on the entities and MUST NOT be bypassed.

## Authentication Flow

1. Client sends a request with a JWT Bearer token (Hydra) or a Kratos session cookie.
2. `AuthenticationResolver` tries both authentication methods in parallel via `asyncio`.
3. JWT authentication produces a `SystemEntity` with OAuth2 scopes.
4. Kratos session authentication produces an `AdminEntity` (Velmios realm) or `CustomerEntity` (tenant realm).
5. The result is wrapped in an `AuthenticationContext` containing `realm_id`, `persona`, `entity`, and `scopes`.
6. FastAPI dependencies (`DependsAuthorizedPersona`, `DependsSystemHasScope`) enforce authorization.

## Dependency Injection

All Velmios services are wired through FastAPI's `Depends()` system:

| Dependency | Returns | Purpose |
|---|---|---|
| `depends_authentication_context()` | `AuthenticationContext` | Authenticate the current request |
| `DependsAuthorizedPersona([...])` | `AuthenticationContext` | Authenticate + authorize by persona |
| `DependsSystemHasScope(scope)` | `AuthenticationContext` | Authenticate + authorize system by OAuth2 scope |
| `depends_authentication_resolver()` | `AuthenticationResolver` | Get the configured resolver (JWT + Kratos) |
| `depends_velmios_jwt_authentication_service()` | `VelmiosJWTAuthenticationService` | JWT authentication service |
| `depends_velmios_kratos_whoami_service()` | `VelmiosKratosWhoamiService` | Kratos whoami service |
| `depends_velmios_kratos_identity_service()` | `VelmiosKratosIdentityService` | Kratos identity management |

## Reference Documentation

### Types

| Reference | Description |
|---|---|
| [Functional Types](references/functional-types.md) | UUID-based `NewType` identifiers (`RealmId`, `CustomerId`, `AdminId`, `SystemId`, `PublicUserId`) |
| [Validated Types](references/validated-types.md) | Input-validated types (`Email`, `Username`, `PhoneNumber`, `Name`, `Country`) |
| [Display Types](references/display-types.md) | UI display types (`ColorHexCode`, `IconCode`) |
| [Role Enums](references/role-enums.md) | Role definitions for all persona types |

### Entities

| Reference | Description |
|---|---|
| [Entities](references/entities.md) | Domain entities (`AdminEntity`, `CustomerEntity`, `PublicUserEntity`, `SystemEntity`) with realm validation |

### Security

| Reference | Description |
|---|---|
| [Authentication](references/authentication.md) | `AuthenticationContext`, `AuthenticationResolver`, persona and type enums |
| [Authorization Dependencies](references/authorization-dependencies.md) | `DependsAuthorizedPersona`, `DependsSystemHasScope`, and `depends_authentication_context` |
| [JWT Authentication](references/jwt-authentication.md) | Velmios JWT services, payload, Hydra introspection, JWKS store |
| [Kratos Authentication](references/kratos-authentication.md) | Velmios Kratos session authentication and whoami/identity services |

### Services

| Reference | Description |
|---|---|
| [Permissions](references/permissions.md) | `Permission` type, `AbstractPermissionsResolverService`, `AbstractDependsPermissionsRequired` |

## Best Practices

1. Always import types from `velmios.core.types`, entities from `velmios.core.entities`, and security utilities from `velmios.core.security`. Do NOT import from internal submodules directly.
2. Use `DependsAuthorizedPersona` for endpoint-level persona authorization rather than checking `auth.persona` manually.
3. Use `DependsSystemHasScope` for machine-to-machine endpoints. Never use the `*` wildcard scope in production.
4. Extend `AbstractPermissionsResolverService` to implement service-specific role-to-permission mappings.
5. Respect realm boundary rules: never construct entities with invalid realm ID combinations.
6. Use the Velmios validated types (`Email`, `Username`, `Name`, etc.) in your Pydantic models to get automatic validation in FastAPI request/response schemas.

## Related Skills

- [fastapi-factory-utilities](../fastapi-factory-utilities/SKILL.md) – Build and configure FastAPI microservices (plugins, configuration, observability) that consume Velmios core types, entities, and authentication.
