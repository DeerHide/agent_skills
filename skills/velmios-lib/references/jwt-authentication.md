# JWT authentication (Velmios)

## When to use

- Configuring or debugging **internal** vs **customer** Hydra JWT verification.
- Understanding `VelmiosInternalJWTPayload` vs `VelmiosCustomerJWTPayload` and how they map to `AuthenticationContext`.
- Wiring `JWTBearerAuthenticationConfig` for both stacks on a Velmios application.

## Overview

Velmios splits JWT handling into **two parallel stacks** (internal platform vs customer-issued tokens), each with its own Hydra introspection dependency, verifier, decoder, authentication service, and payload type. Public imports live under `velmios.core.security.jwt`.

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
    depends_velmios_internal_jwt_token_decoder,
    depends_velmios_customer_jwt_token_decoder,
    depends_velmios_internal_jwt_token_verifier,
    depends_velmios_customer_jwt_token_verifier,
)
```

Hydra HTTP clients for introspection are provided from `velmios.core.services.hydra` (`depends_velmios_internal_hydra_introspect_service`, `depends_velmios_customer_hydra_introspect_service`, and related helpers).

## Payloads

### VelmiosInternalJWTPayload

```python
class VelmiosInternalJWTPayload(JWTPayload):
    metadata: dict[str, Any] | None = None
    ext: dict[str, Any] | None = None
```

Used with the **internal** JWT pipeline. The resolver hook reads `metadata["id"]` to populate `SystemEntity.id` when present (otherwise the zero UUID is used). `scopes` are taken from the `scp` claim on the base payload.

### VelmiosCustomerJWTPayload

```python
class VelmiosCustomerJWTPayload(JWTPayload):
    metadata: dict[str, Any] | None = None
    ext: AdminLiteEntity | CustomerLiteEntity = Field(discriminator="persona")
```

The `ext` claim is a **discriminated union** of `AdminLiteEntity` / `CustomerLiteEntity` validated by Pydantic on the `persona` field. The resolver hook also propagates the JWT `sub` into `identity_id` on the resulting `AuthenticationContext`.

Hydra v5.0.2 made the upstream introspection DTOs accept non-string nested values inside `ext`, so richer token metadata (lists, nested objects) parses without errors.

## Services, verifiers, decoders

| Class | Role |
|---|---|
| `VelmiosInternalJWTAuthenticationService` | Bearer extract → verify (Hydra introspect) → decode (JWKS) for internal tokens. |
| `VelmiosCustomerJWTAuthenticationService` | Same pipeline for customer tokens. |
| `VelmiosInternalJWTTokenVerifier` / `VelmiosCustomerJWTTokenVerifier` | Hydra introspection. |
| `VelmiosInternalJWTTokenDecoder` / `VelmiosCustomerJWTTokenDecoder` | JWKS-backed decoding. |

Each has a matching `depends_*` factory in `velmios.core.security.jwt`. Invalid tokens raise `ExpiredJWTError` (from `fastapi_factory_utilities`) for expired bearer tokens; other verifier failures are mapped to HTTP **403** by the upstream FFU 5.0.1 hardening — see [FFU JWT reference](../../fastapi-factory-utilities/references/jwt-authentication.md).

## JWKS store

`configure_velmios_jwks_store_memory(application)` constructs the in-memory JWKS store used by both decoders. It pulls keys from the configured Hydra introspect services and merges them into a single `PyJWKSet`. `VelmiosApplicationAbstract.configure_jwks_store_memory()` calls this helper at startup and registers the store on ASGI state via `DependsHydraJWKStoreMemory`.

## Configuration

Both stacks are configured by `JWTBearerAuthenticationConfigBuilder(key=...)`:

```python
internal_builder = JWTBearerAuthenticationConfigBuilder(key="internal")
internal_builder.add_application_yaml_path(package_name=PACKAGE_NAME, filename=CONFIG_FILENAME)
internal_config = internal_builder.build()

customer_builder = JWTBearerAuthenticationConfigBuilder(key="customer")
customer_builder.add_application_yaml_path(package_name=PACKAGE_NAME, filename=CONFIG_FILENAME)
customer_config = customer_builder.build()

DependsJWTBearerAuthenticationConfig.import_to_state(state=asgi_app.state, key="internal", config=internal_config)
DependsJWTBearerAuthenticationConfig.import_to_state(state=asgi_app.state, key="customer", config=customer_config)
```

`VelmiosApplicationAbstract.configure_jwt_bearer_authentication()` performs the wiring above automatically when the configs are not injected via `__init__` kwargs. `audience` lives on each `JWTBearerAuthenticationConfig` (moved out of `BaseApplicationConfig` upstream in FFU v0.19.2).

## Mapping to AuthenticationContext

Resolver hooks in `velmios.core.security.resolvers`:

- **Internal JWT success** → `AuthenticationPersona.SYSTEM` + `SystemEntity`, `scopes` from `scp`, `system.id` from `metadata["id"]` when present.
- **Customer JWT success** → `ADMIN` or `CUSTOMER` with the discriminated lite entity from `ext`; `identity_id` set from `sub`; `scopes` from `scp`.

## Reference

- `src/velmios/core/security/jwt/__init__.py`
- `src/velmios/core/security/jwt/objects.py`
- `src/velmios/core/security/jwt/services.py`
- `src/velmios/core/security/jwt/verifiers.py`
- `src/velmios/core/security/jwt/decoders.py`
- `src/velmios/core/security/jwt/stores.py`
- `src/velmios/core/services/hydra.py`
- `src/velmios/core/app/applications.py`
