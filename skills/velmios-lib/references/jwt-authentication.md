# JWT Authentication

## When to Use

- When you need to understand how **system-to-system JWT authentication** works in Velmios.
- When configuring or customizing the JWT authentication pipeline.
- When debugging JWT token verification or Hydra introspection issues.

## Overview

The JWT authentication module provides Velmios-specific extensions to the `fastapi-factory-utilities` JWT framework. It handles Bearer token extraction, Hydra introspection for token verification, JWKS-based decoding, and payload parsing.

```python
from velmios.core.security.jwt import (
    VelmiosJWTAuthenticationService,
    VelmiosJWTPayload,
    VelmiosJWTTokenVerifier,
    VelmiosJWTTokenDecoder,
    VelmiosHydraInstrospectService,
    configure_jwks_in_memory_store,
)
```

## Components

### VelmiosJWTPayload

Extends the base `JWTPayload` from `fastapi-factory-utilities` with an optional metadata field.

```python
class VelmiosJWTPayload(JWTPayload):
    metadata: Optional[dict[str, Any]] = None
```

The `metadata` field is used to carry additional information in the JWT, notably the `id` field used to identify the system entity.

### VelmiosJWTAuthenticationService

Main authentication service that orchestrates token extraction, verification, and decoding.

```python
class VelmiosJWTAuthenticationService(JWTAuthenticationServiceAbstract[VelmiosJWTPayload]):
    def __init__(
        self,
        jwt_bearer_authentication_config: JWTBearerAuthenticationConfig,
        jwks_store: JWKStoreAbstract,
        jwt_verifier: VelmiosJWTTokenVerifier,
        raise_exception: bool = True,
    ) -> None: ...
```

**Authentication flow:**
1. Extract Bearer token from the `Authorization` header.
2. Verify the token via Hydra introspection (`VelmiosJWTTokenVerifier`).
3. Decode the token payload using JWKS (`VelmiosJWTTokenDecoder`).
4. Store the decoded `VelmiosJWTPayload` for hook consumption.

### VelmiosJWTTokenVerifier

Verifies JWT tokens by calling the Ory Hydra introspection endpoint.

```python
class VelmiosJWTTokenVerifier:
    def __init__(self, hydra_instrospect_service: VelmiosHydraInstrospectService) -> None: ...
```

### VelmiosJWTTokenDecoder

Decodes JWT tokens using the JWKS (JSON Web Key Set) in-memory store.

### VelmiosHydraInstrospectService

HTTP client service that calls the Ory Hydra token introspection endpoint.

### JWKS Store

In-memory store for JSON Web Keys used to decode JWT tokens.

```python
from velmios.core.security.jwt import configure_jwks_in_memory_store, depends_jwks_in_memory_store
```

## Dependency Wiring

| Dependency | Returns | Description |
|---|---|---|
| `depends_jwt_bearer_authentication_config()` | `JWTBearerAuthenticationConfig` | JWT Bearer configuration from app settings |
| `depends_jwks_in_memory_store()` | `JWKStoreAbstract` | JWKS in-memory key store |
| `depends_velmios_jwt_token_verifier()` | `VelmiosJWTTokenVerifier` | Token verifier via Hydra |
| `depends_velmios_hydra_instrospect_service()` | `VelmiosHydraInstrospectService` | Hydra introspection HTTP client |
| `depends_velmios_jwt_authentication_service()` | `VelmiosJWTAuthenticationService` | Fully configured JWT auth service |

All dependencies are automatically wired when using `depends_authentication_resolver()`.

## JWT to AuthenticationContext Mapping

When JWT authentication succeeds, the `jwt_authentication_context_hook` in `resolvers.py` creates:

```python
AuthenticationContext(
    realm_id=VELMIOS_REALM_ID,
    persona=AuthenticationPersona.SYSTEM,
    entity=SystemEntity(
        id=SystemId(payload.metadata["id"]),  # or default UUID if no metadata
        realm_id=VELMIOS_REALM_ID,
        role=SystemRole.SYSTEM,
    ),
    scopes=payload.scp,
)
```

NOTE: JWT-authenticated entities are always `SYSTEM` persona in the Velmios realm.

## Reference

- `src/velmios/core/security/jwt/objects.py`
- `src/velmios/core/security/jwt/services.py`
- `src/velmios/core/security/jwt/verifiers.py`
- `src/velmios/core/security/jwt/decoders.py`
- `src/velmios/core/security/jwt/hydra.py`
- `src/velmios/core/security/jwt/jwks_store.py`
- `src/velmios/core/security/jwt/depends.py`
