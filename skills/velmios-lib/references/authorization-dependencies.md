# Authorization dependencies

## When to use

- Restricting a FastAPI route to specific **personas** (`AuthenticationPersona`).
- Restricting which **authentication mechanisms** may be used (`AuthenticationType`).
- Choosing between the JWT-only resolver and the Kratos session-aware resolver per route.
- Understanding **public** and **none** personas when the resolver is configured to allow them.

## Overview

Velmios exposes two first-class dependency classes that both:

1. Inject an `AuthenticationResolver`.
2. Optionally apply `supported_authentication_types` and `authorized_personas` on the resolver.
3. Call `authenticate(request)` and verify the resulting persona is allowed.

```python
from velmios.core.security import (
    AuthenticationContext,
    AuthenticationType,
    DependsAuthenticationContext,
    DependsAuthenticationContextWithKratosSessionSupport,
)
from velmios.core.types import AuthenticationPersona
```

There is **no** legacy `depends_authentication_context`, `DependsAuthorizedPersona`, or `DependsSystemHasScope`. Migrate to the classes below.

## DependsAuthenticationContext

Uses `depends_authentication_resolver` (internal + customer JWT).

```python
DependsAuthenticationContext(
    authorized_personas: list[AuthenticationPersona],
    supported_authentication_types: list[AuthenticationType] | None = None,
)
```

- `authorized_personas` MUST NOT be empty (raises `ValueError` at construction).
- `supported_authentication_types` MUST NOT be empty when supplied. When `None`, the resolver tries every mechanism registered on it (typically internal JWT + customer JWT).

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

## DependsAuthenticationContextWithKratosSessionSupport

Subclass that injects `depends_authentication_resolver_with_kratos_session` instead, so routes accept JWT **or** a Kratos session cookie. Same constructor signature as `DependsAuthenticationContext`.

```python
@app.get("/portal/me")
async def portal_me(
    auth: AuthenticationContext = Depends(
        DependsAuthenticationContextWithKratosSessionSupport(
            authorized_personas=[AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER],
            supported_authentication_types=[
                AuthenticationType.HYDRA_CUSTOMER_JWT,
                AuthenticationType.KRATOS_SESSION,
            ],
        )
    ),
) -> dict:
    return {"identity_id": str(auth.identity_id) if auth.identity_id else None}
```

## Machine-to-machine pattern

Lock down internal endpoints to the `SYSTEM` persona using only the internal JWT mechanism and combine with explicit scope or permission checks (see [Permissions](permissions.md)):

```python
DependsAuthenticationContext(
    authorized_personas=[AuthenticationPersona.SYSTEM],
    supported_authentication_types=[AuthenticationType.HYDRA_INTERNAL_JWT],
)
```

## OAuth2 scopes

Scopes are available on `auth.scopes` as `list[OAuth2Scope]` from `fastapi_factory_utilities.core.security.types`. Velmios does **not** ship a built-in dependency for "must have scope X". Options:

- Check membership in the route body after the dependency runs.
- Implement a small wrapper dependency.
- Use `AbstractDependsPermissionsRequired` with `required_requirement` so scopes are folded into the resolved permission set.

## Public and none personas

When `AuthenticationPersona.PUBLIC` is authorized and `AuthenticationType.NONE` is supported (and a `NONE` authentication is registered), unauthenticated users can receive a synthetic guest `PublicUserEntity` with `realm_id` taken from the `realm_id` query parameter. `AuthenticationPersona.NONE` represents an explicitly anonymous context (`realm_id` MUST be `None`). See `AuthenticationResolver.authorize_public` and `authorize_none` in `resolvers.py` for exact conditions.

## Error envelopes

`register_security_exception_handlers` standardizes the JSON envelopes:

| Condition | HTTP | Source |
|---|---|---|
| Unauthorized persona or no successful authentication | **401** | `VelmiosNotAuthenticatedError`, `VelmiosSecurityError` |
| Permission requirement failed (`PermissionsRequiredError` or raw `HTTPException(403)`) | **403** | Permissions layer, resource API CUD endpoints |
| Resource not found (`USE_CASE_NOT_FOUND_ERROR`) | **404** | Use-case abstracts |
| Validation error on a CUD payload or query parameter | **422** | `_parse_request_model_or_422` / `_pagination_from_request_or_422` |
| Use-case internal error (`USE_CASE_ERROR`) | **500** | Use-case abstracts |

Telemetry: every `401` and `403` increments the OTel `velmios.security.auth_failures` counter, emits a `security_auth_failure` log entry, and decorates the active span with `security.event=auth_failure` (see [Exception handling](exception-handling.md)).

## Best practices

1. Prefer `DependsAuthenticationContext` (or the Kratos variant) over reimplementing resolver wiring in each route.
2. Pass `supported_authentication_types` whenever a route must not accept a mechanism (e.g. browser-session only).
3. Never construct the dependency with an empty `authorized_personas` (it raises) or an empty `supported_authentication_types` list (it raises).
4. Pair persona checks with `AbstractDependsPermissionsRequired` for fine-grained authorization.
5. Always call `register_security_exception_handlers(app, ...)` so the envelopes and telemetry above are produced consistently.

## Reference

- `src/velmios/core/security/depends.py`
- `src/velmios/core/security/resolvers.py`
- `src/velmios/core/security/handlers.py`
