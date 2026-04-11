# Authorization dependencies

## When to use

- Restricting a FastAPI route to specific **personas** (`AuthenticationPersona`).
- Restricting which **authentication mechanisms** may be used (`AuthenticationType`).
- Understanding **public** and **none** personas when the resolver is configured to allow them.

## Overview

Velmios exposes a single first-class dependency class, **`DependsAuthenticationContext`**, which:

1. Injects **`AuthenticationResolver`** (via `depends_authentication_resolver`).
2. Optionally applies **`supported_authentication_types`** and **`authorized_personas`** on the resolver.
3. Calls **`authenticate(request)`** and verifies the resulting persona is allowed.

```python
from velmios.core.security import (
    AuthenticationContext,
    AuthenticationType,
    DependsAuthenticationContext,
)
from velmios.core.types import AuthenticationPersona
```

There is **no** `depends_authentication_context`, `DependsAuthorizedPersona`, or `DependsSystemHasScope` in current public APIs. Older docs referred to those names; migrate to `DependsAuthenticationContext`.

## DependsAuthenticationContext

### Constructor

```python
DependsAuthenticationContext(
    authorized_personas: list[AuthenticationPersona],
    supported_authentication_types: list[AuthenticationType] | None = None,
)
```

- **`authorized_personas`**: MUST NOT be empty (raises `ValueError` at construction).
- **`supported_authentication_types`**: When not `None`, MUST NOT be empty. When `None`, the resolver tries every mechanism registered on the resolver (typically internal JWT, customer JWT, and optionally Kratos).

### Usage

```python
from fastapi import Depends

@app.get("/admin")
async def admin_only(
    auth: AuthenticationContext = Depends(
        DependsAuthenticationContext(authorized_personas=[AuthenticationPersona.ADMIN])
    ),
) -> dict:
    return {"admin_id": str(auth.admin.id)}


@app.get("/users")
async def for_admins_and_customers(
    auth: AuthenticationContext = Depends(
        DependsAuthenticationContext(
            authorized_personas=[AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER],
        )
    ),
) -> dict:
    return {"realm_id": str(auth.realm_id)}
```

### OAuth2 scopes

Scopes are available on **`auth.scopes`** as `list[OAuth2Scope]` (`fastapi_factory_utilities.core.security.types`). Velmios does **not** ship a dedicated `Depends*` for “must have scope X”. Options:

- Check membership in the route body after `DependsAuthenticationContext`.
- Implement a small wrapper dependency or use **`AbstractDependsPermissionsRequired`** with permissions derived from roles/scopes.

### Machine-to-machine pattern

Use **SYSTEM** persona with **internal JWT** only, then validate scopes (see [assets/quick_start_example.py](../assets/quick_start_example.py)):

```python
DependsAuthenticationContext(
    authorized_personas=[AuthenticationPersona.SYSTEM],
    supported_authentication_types=[AuthenticationType.HYDRA_INTERNAL_JWT],
)
```

### Public and none personas

When **`AuthenticationPersona.PUBLIC`** is authorized and **`AuthenticationType.NONE`** is supported (and the resolver is configured accordingly), unauthenticated users may receive a synthetic **`PublicUserEntity`** using `realm_id` from the query string. Similarly, **`AuthenticationPersona.NONE`** can represent an explicitly anonymous context. See **`AuthenticationResolver.authenticate`** and **`authorize_public` / `authorize_none`** in `resolvers.py` for exact conditions.

### Error handling

| Condition | Typical outcome |
|---|---|
| No authentication succeeded | `VelmiosNotAuthenticatedError` from the resolver (map to HTTP 401 in exception handlers if needed) |
| Authenticated persona not in `authorized_personas` | `HTTPException` **401** from `DependsAuthenticationContext` |

## Best practices

1. Prefer **`DependsAuthenticationContext`** over reimplementing resolver wiring in each route.
2. Pass **`supported_authentication_types`** when a route must not accept a mechanism (e.g. human session only vs internal JWT only).
3. Combine persona checks with **`AbstractDependsPermissionsRequired`** for fine-grained authorization.
4. Never pass an empty `authorized_personas` or empty `supported_authentication_types` when the latter is not `None`.

## Reference

- `src/velmios/core/security/depends.py`
- `src/velmios/core/security/resolvers.py`
