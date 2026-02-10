# Authentication

## When to Use

- When you need to understand the **authentication flow** in a Velmios microservice.
- When you need to access the **current user's identity** in a FastAPI endpoint.
- When you need to configure the `AuthenticationResolver` with custom authentication methods.
- When you need to check the **persona type** of the authenticated user.

## Overview

The authentication system resolves incoming requests to an `AuthenticationContext` by trying multiple authentication methods (JWT and Kratos sessions) in parallel.

```python
from velmios.core.security import AuthenticationContext, AuthenticationPersona
from velmios.core.security import depends_authentication_resolver
```

## AuthenticationContext

Immutable Pydantic model containing the result of authentication.

```python
class AuthenticationContext(BaseModel):
    realm_id: RealmId
    persona: AuthenticationPersona
    entity: Union[AdminEntity, CustomerEntity, PublicUserEntity, SystemEntity] | None
    scopes: list[OAuth2Scope]
```

### Properties

| Property | Returns | Raises |
|---|---|---|
| `.admin` | `AdminEntity` | `ValueError` if entity is not an admin |
| `.customer` | `CustomerEntity` | `ValueError` if entity is not a customer |
| `.public_user` | `PublicUserEntity` | `ValueError` if entity is not a public user |
| `.system` | `SystemEntity` | `ValueError` if entity is not a system |

### Methods

| Method | Returns | Description |
|---|---|---|
| `persona_is(persona)` | `bool` | Check if the authenticated user matches a specific persona |

### Usage

```python
from fastapi import Depends
from velmios.core.security import AuthenticationContext, AuthenticationPersona, depends_authentication_context

@app.get("/resource")
async def get_resource(
    auth: AuthenticationContext = Depends(depends_authentication_context),
) -> dict:
    if auth.persona_is(AuthenticationPersona.ADMIN):
        admin = auth.admin
        return {"admin_id": str(admin.id)}
    elif auth.persona_is(AuthenticationPersona.CUSTOMER):
        customer = auth.customer
        return {"customer_id": str(customer.id), "realm": str(customer.realm_id)}
    elif auth.persona_is(AuthenticationPersona.SYSTEM):
        system = auth.system
        return {"system_id": str(system.id), "scopes": auth.scopes}
```

## AuthenticationPersona

Enum defining the four persona types.

| Value | String | Description |
|---|---|---|
| `CUSTOMER` | `"customer"` | Tenant customer authenticated via Kratos session |
| `PUBLIC` | `"public"` | Public/guest user (optionally authenticated) |
| `ADMIN` | `"admin"` | Velmios admin authenticated via Kratos session |
| `SYSTEM` | `"system"` | System process authenticated via JWT/Hydra |

## AuthenticationType

Flag enum defining the supported authentication methods.

| Value | Description |
|---|---|
| `HYDRA_JWT` | OAuth2 JWT token verified via Ory Hydra introspection |
| `KRATOS_SESSION` | Session cookie verified via Ory Kratos whoami endpoint |

## AuthenticationResolver

Orchestrates multiple authentication methods and resolves the request to an `AuthenticationContext`.

```python
class AuthenticationResolver:
    def add_authentication(
        self,
        authentication: AuthenticationAbstract,
        authentication_type: AuthenticationType,
        authentication_context_hook: Callable | None = None,
    ) -> None: ...

    def set_authorized_personas(self, authorized_personas: list[AuthenticationPersona]) -> None: ...
    def authorize_public(self) -> bool: ...
    async def authenticate(self, request: Request) -> AuthenticationContext: ...
```

### Authentication Flow

1. All registered authentication methods run in parallel (`asyncio.gather`).
2. The first method that succeeds without errors provides the `AuthenticationContext` via its hook.
3. If no method succeeds and public access is authorized, a `PublicUserEntity` is created using the `realm_id` query parameter.
4. If all methods fail and public access is not authorized, raises `HTTPException(401)`.

### Default Configuration

The `depends_authentication_resolver()` dependency pre-configures:
- **JWT authentication** via `VelmiosJWTAuthenticationService` with `jwt_authentication_context_hook`.
- **Kratos session authentication** via `VelmiosKratosSessionAuthenticationService` with `kratos_session_authentication_context_hook`.

### Authentication Context Hooks

**JWT hook** (`jwt_authentication_context_hook`):
- Extracts `SystemId` from `jwt_payload.metadata["id"]` (defaults to `00000000-...` if no metadata).
- Creates `AuthenticationContext` with `persona=SYSTEM`, `entity=SystemEntity`, and OAuth2 scopes.

**Kratos hook** (`kratos_session_authentication_context_hook`):
- If the Kratos session realm is the Velmios realm: creates `AdminEntity` with `persona=ADMIN`.
- Otherwise: creates `CustomerEntity` with `persona=CUSTOMER`.
- Validates that the `realm_id` query parameter matches the session realm (prevents cross-realm impersonation).

## Error Handling

| Error | HTTP Status | Condition |
|---|---|---|
| `HTTPException(401)` | Unauthorized | No authentication method succeeded and public access not allowed |
| `HTTPException(401)` | Unauthorized | JWT payload is `None` or missing metadata `id` |

## Reference

- `src/velmios/core/security/contexts.py`
- `src/velmios/core/security/enums.py`
- `src/velmios/core/security/resolvers.py`
