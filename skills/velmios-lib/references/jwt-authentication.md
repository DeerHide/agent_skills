# JWT authentication (Velmios)

## When to use

- Configuring or debugging **internal** vs **customer** Hydra JWT verification.
- Understanding **`VelmiosInternalJWTPayload`** vs **`VelmiosCustomerJWTPayload`** and how they map to **`AuthenticationContext`**.

## Overview

Velmios splits JWT handling into **two parallel stacks** (internal platform vs customer-issued tokens), each with its own Hydra introspection dependency, verifier, decoder, authentication service, and payload type. Public imports live under **`velmios.core.security.jwt`**.

```python
from velmios.core.security.jwt import (
    VelmiosInternalJWTAuthenticationService,
    VelmiosCustomerJWTAuthenticationService,
    VelmiosInternalJWTPayload,
    VelmiosCustomerJWTPayload,
    VelmiosInternalJWTTokenVerifier,
    VelmiosCustomerJWTTokenVerifier,
    VelmiosInternalJWTTokenDecoder,
    VelmiosCustomerJWTTokenDecoder,
    configure_velmios_jwks_store_memory,
    depends_velmios_internal_jwt_authentication_service,
    depends_velmios_customer_jwt_authentication_service,
)
```

Hydra HTTP clients for introspection are provided from **`velmios.core.services.hydra`** (`depends_velmios_internal_hydra_introspect_service`, `depends_velmios_customer_hydra_introspect_service`, …).

## Payloads

### VelmiosInternalJWTPayload

Extends **`JWTPayload`** from `fastapi-factory-utilities`. Carries optional **`metadata`** (e.g. system `id`) and optional **`ext`**. Used with the **internal** JWT pipeline.

### VelmiosCustomerJWTPayload

Extends **`JWTPayload`**. Carries **`ext`**: a discriminated union of **`AdminLiteEntity`** and **`CustomerLiteEntity`** (by **`persona`** field) for customer-facing tokens.

## Services

| Class | Role |
|---|---|
| **`VelmiosInternalJWTAuthenticationService`** | Bearer extract → verify (Hydra) → decode (JWKS) for internal tokens |
| **`VelmiosCustomerJWTAuthenticationService`** | Same pipeline for customer tokens |

Dependencies: **`depends_velmios_internal_jwt_authentication_service`**, **`depends_velmios_customer_jwt_authentication_service`**.

## Verifiers and decoders

- **`VelmiosInternalJWTTokenVerifier`** / **`VelmiosCustomerJWTTokenVerifier`** — Hydra introspection.
- **`VelmiosInternalJWTTokenDecoder`** / **`VelmiosCustomerJWTTokenDecoder`** — JWKS-backed decoding.

Matching **`depends_*`** functions exist in `jwt/verifiers.py` and `jwt/decoders.py`.

## JWKS store

**`configure_velmios_jwks_store_memory`** configures the in-memory JWKS store used by decoders (see `jwt/stores.py`).

## Mapping to AuthenticationContext

Resolver hooks in **`resolvers.py`**:

- **Internal** success → **`SYSTEM`** + **`SystemEntity`**, **`scopes`** from payload **`scp`**; system id from **`metadata["id"]`** when present.
- **Customer** success → **`ADMIN`** or **`CUSTOMER`** with lite entity from **`ext`**, scopes from **`scp`**.

## Application wiring

**`VelmiosApplicationAbstract`** (`velmios.core.app.applications`) configures **two** JWT bearer configs (`internal` / `customer`) and JWKS where applicable. Consumer apps should follow the same split when mounting dependencies.

## Reference

- `src/velmios/core/security/jwt/__init__.py`
- `src/velmios/core/security/jwt/objects.py`
- `src/velmios/core/security/jwt/services.py`
- `src/velmios/core/security/jwt/verifiers.py`
- `src/velmios/core/security/jwt/decoders.py`
- `src/velmios/core/security/jwt/stores.py`
- `src/velmios/core/services/hydra.py`
