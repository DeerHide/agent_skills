# Authorization Dependencies

## When to Use

- When you need to **restrict a FastAPI endpoint** to specific persona types.
- When you need to **enforce OAuth2 scopes** on system-to-system endpoints.
- When you need the base `AuthenticationContext` dependency without additional authorization.

## Overview

Authorization dependencies are FastAPI `Depends()` callables that authenticate the request and then enforce authorization rules. They return the `AuthenticationContext` on success or raise HTTP exceptions on failure.

```python
from velmios.core.security import (
    depends_authentication_context,
    DependsAuthorizedPersona,
    DependsSystemHasScope,
    AuthenticationPersona,
)
```

## depends_authentication_context

Base dependency that authenticates the request and returns the `AuthenticationContext`. Does NOT enforce any authorization rules.

```python
from fastapi import Depends
from velmios.core.security import AuthenticationContext, depends_authentication_context

@app.get("/resource")
async def get_resource(
    auth: AuthenticationContext = Depends(depends_authentication_context),
) -> dict:
    return {"persona": auth.persona}
```

## DependsAuthorizedPersona

Callable class that authenticates the request and verifies that the authenticated persona is in the list of authorized personas.

### Constructor

```python
DependsAuthorizedPersona(authorized_personas: list[AuthenticationPersona])
```

- `authorized_personas` MUST NOT be empty. Raises `ValueError` if empty.

### Usage

```python
from fastapi import Depends
from velmios.core.security import (
    AuthenticationContext,
    AuthenticationPersona,
    DependsAuthorizedPersona,
)

# Only admins
@app.get("/admin-only")
async def admin_only(
    auth: AuthenticationContext = Depends(
        DependsAuthorizedPersona([AuthenticationPersona.ADMIN])
    ),
) -> dict:
    return {"admin_id": str(auth.admin.id)}

# Admins and customers
@app.get("/users")
async def for_users(
    auth: AuthenticationContext = Depends(
        DependsAuthorizedPersona([AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER])
    ),
) -> dict:
    return {"realm_id": str(auth.realm_id)}
```

### Error Handling

| HTTP Status | Condition |
|---|---|
| `401 Unauthorized` | Authentication failed (no valid JWT or Kratos session) |
| `401 Unauthorized` | Authenticated persona not in `authorized_personas` list |

## DependsSystemHasScope

Callable class that authenticates the request, verifies it is a `SYSTEM` persona, and checks for a specific OAuth2 scope.

### Constructor

```python
DependsSystemHasScope(required_scope: OAuth2Scope)
```

### Usage

```python
from fastapi import Depends
from velmios.core.security import AuthenticationContext, DependsSystemHasScope

@app.post("/internal/process")
async def internal_process(
    auth: AuthenticationContext = Depends(
        DependsSystemHasScope(required_scope="my_service.process:execute")
    ),
) -> dict:
    return {"system_id": str(auth.system.id)}
```

### Scope Rules

- The special scope `*` grants access to all scopes. This is for **development only** and MUST NOT be used in production.
- The `required_scope` is checked against `auth.scopes` from the JWT payload.

### Error Handling

| HTTP Status | Condition |
|---|---|
| `401 Unauthorized` | Authentication failed or persona is not `SYSTEM` |
| `403 Forbidden` | System persona authenticated but missing the required scope |

## Best Practices

1. Prefer `DependsAuthorizedPersona` over manual persona checks in endpoint bodies.
2. Use `DependsSystemHasScope` for all machine-to-machine endpoints. Define scopes following the pattern `service_name.resource:action`.
3. Combine persona authorization with permission checking by layering `DependsAuthorizedPersona` with `AbstractDependsPermissionsRequired`.
4. Never pass an empty list to `DependsAuthorizedPersona` - it will raise `ValueError` at startup.

## Reference

- `src/velmios/core/security/depends.py`
