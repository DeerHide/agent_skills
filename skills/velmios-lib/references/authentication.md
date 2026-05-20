# Authentication

## When to use

- Understanding how a request becomes an `AuthenticationContext`.
- Configuring `AuthenticationResolver` with JWT and optional Kratos session authentication.
- Reading `persona`, `realm_id`, `identity_id`, `entity`, and `scopes` from the context.

## Overview

Velmios resolves HTTP requests to an immutable `AuthenticationContext` using `AuthenticationResolver`, which runs registered `AuthenticationAbstract` implementations (from `fastapi_factory_utilities`) in parallel and applies **context hooks** that map successful authentication to Velmios types.

```python
from velmios.core.security import (
    AuthenticationContext,
    AuthenticationPersona,
    AuthenticationResolver,
    AuthenticationType,
    DependsAuthenticationContext,
    DependsAuthenticationContextWithKratosSessionSupport,
    HTTPExceptionDetailEnricher,
    VelmiosNotAuthenticatedError,
    VelmiosSecurityError,
    depends_authentication_resolver,
    register_security_exception_handlers,
)
```

`depends_authentication_resolver_with_kratos_session` lives in `velmios.core.security.resolvers` (it is not re-exported from the security package today).

## AuthenticationContext

Frozen Pydantic model holding the authenticated subject.

| Field | Type | Notes |
|---|---|---|
| `realm_id` | `RealmId \| None` | Required for every persona except `NONE`; rejected for `NONE` (model validator). |
| `identity_id` | `KratosIdentityId \| None` | Top-level identity propagation alongside the entity-level field (added in v10.3.0). |
| `persona` | `AuthenticationPersona` | `admin`, `customer`, `public`, `system`, `partial`, or `none`. |
| `entity` | `AdminLiteEntity \| CustomerLiteEntity \| PublicUserEntity \| SystemEntity \| None` | Lite variants for admin/customer; `None` for `PARTIAL` and `NONE`. |
| `scopes` | `list[OAuth2Scope]` | From JWT `scp` when applicable; empty otherwise. |

### Typed accessors

Properties `.admin`, `.customer`, `.public_user`, `.system` raise `ValueError` when the entity is missing or of the wrong type. Use `persona_is(...)` before accessing.

### Helpers

- `persona_is(persona)` — equality check on persona.
- `is_velmios_admin_or_system()` — `True` when the context is either a Velmios-realm admin or a `SystemEntity.is_velmios_system()`. Used by use-case abstracts to gate the `allow_cross_realm_when_velmios_admin_or_system` bypass.

## AuthenticationPersona

`StrEnum` in `velmios.core.types` (re-exported from `velmios.core.security`): `CUSTOMER`, `PUBLIC`, `ADMIN`, `SYSTEM`, `PARTIAL`, `NONE`. See [Functional Types](functional-types.md#authenticationpersona).

`PARTIAL` is emitted only by the Kratos session hook when the identity is mid-registration (no `metadata_public` / `metadata_admin` and no `traits.realm_id`). Treat it as "needs onboarding" rather than "fully authenticated".

## AuthenticationType

`Flag` enum in `velmios.core.security`: `HYDRA_INTERNAL_JWT`, `HYDRA_CUSTOMER_JWT`, `KRATOS_SESSION`, `NONE`. Pass a list of these to `DependsAuthenticationContext(supported_authentication_types=...)` to restrict which mechanisms the resolver considers for a route.

## AuthenticationResolver

```python
resolver = AuthenticationResolver()
resolver.add_authentication(service, AuthenticationType.HYDRA_INTERNAL_JWT, hook)
resolver.set_authorized_personas([AuthenticationPersona.ADMIN])
resolver.set_supported_authentication_types([AuthenticationType.HYDRA_INTERNAL_JWT])
context = await resolver.authenticate(request)
```

Resolution flow (`authenticate(request)`):

1. Run every supported authentication service **in parallel** via `asyncio.gather`.
2. Walk the services in insertion order and pick the **first one without errors**; invoke its `authentication_context_hook` to build the context. Subsequent services are ignored.
3. If no service authenticated, fall back to `authorize_public(...)` (synthesizes a `PublicUserEntity` from the `realm_id` query parameter when public + `AuthenticationType.NONE` are both enabled) or `authorize_none(...)` (returns a `NONE` persona context). Otherwise raise `VelmiosNotAuthenticatedError`.
4. Apply `check_supported_personas(...)` against `_authorized_personas` and return.

### Factory dependencies

| Function | Registered mechanisms |
|---|---|
| `depends_authentication_resolver()` | Internal JWT + customer JWT |
| `depends_authentication_resolver_with_kratos_session()` | Internal JWT + customer JWT + Kratos session (`velmios.core.security.resolvers`) |

### Context hooks (high level)

- **Internal JWT** → `AuthenticationPersona.SYSTEM` + `SystemEntity` in the Velmios realm. `scopes` come from the JWT `scp` claim and `system.id` from `metadata["id"]` when present (otherwise the zero UUID).
- **Customer JWT** → `ADMIN` or `CUSTOMER` with `AdminLiteEntity` or `CustomerLiteEntity` validated from `ext`; `identity_id` set to the JWT `sub`.
- **Kratos session** → `AdminLiteEntity` when `metadata_public.realm_id == VELMIOS_REALM_ID`; otherwise `CustomerLiteEntity` checked against the optional `realm_id` query parameter. Identities missing both `metadata_public` and `traits.realm_id` resolve to `AuthenticationPersona.PARTIAL` with `entity=None` so onboarding flows can branch.

## Errors

- `VelmiosNotAuthenticatedError` — emitted by the resolver/hooks when no mechanism succeeded or when persona validation fails.
- `VelmiosSecurityError` — generic security error usable for custom hooks.

Both are mapped to HTTP **401** by `register_security_exception_handlers`. Permission failures (`PermissionsRequiredError`) and unhandled `HTTPException(403)` paths also route through the same handler, emitting:

- The OpenTelemetry counter `velmios.security.auth_failures` with `http.status_code`, `http.method`, `http.route`, `service.name`, and `auth.failure_type` labels.
- A structured `security_auth_failure` log entry.
- Span attributes `security.event=auth_failure`, `http.status_code`, `http.method`, `http.route`, and `auth.failure_type`.

Request validation errors return HTTP 422 with a structured `detail` envelope (see [Authorization dependencies](authorization-dependencies.md#error-envelopes) and the [FFU CSRF & validation reference](../../fastapi-factory-utilities/references/csrf-and-validation.md)).

## Reference

- `src/velmios/core/security/contexts.py`
- `src/velmios/core/security/enums.py`
- `src/velmios/core/security/resolvers.py`
- `src/velmios/core/security/handlers.py`
- `src/velmios/core/security/__init__.py`
