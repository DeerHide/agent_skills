# Authentication

## When to use

- Understanding how a request becomes an **`AuthenticationContext`**.
- Configuring **`AuthenticationResolver`** with JWT and optional Kratos session authentication.
- Reading **persona**, **realm**, **entity**, and **scopes** on the context.

## Overview

Velmios resolves HTTP requests to an immutable **`AuthenticationContext`** using **`AuthenticationResolver`**, which runs registered **`AuthenticationAbstract`** implementations (from `fastapi_factory_utilities`) and **context hooks** that map successful auth to Velmios types.

```python
from velmios.core.security import AuthenticationContext, depends_authentication_resolver
from velmios.core.types import AuthenticationPersona
```

## AuthenticationContext

Pydantic model (`frozen=True`) holding the authenticated subject.

| Field | Type | Notes |
|---|---|---|
| `realm_id` | `RealmId \| None` | `None` only for `AuthenticationPersona.NONE` per validators |
| `persona` | `AuthenticationPersona` | `admin`, `customer`, `public`, `system`, `none` |
| `entity` | `AdminLiteEntity \| CustomerLiteEntity \| PublicUserEntity \| SystemEntity \| None` | **Lite** variants for admin/customer from JWT or Kratos hooks |
| `scopes` | `list[OAuth2Scope]` | From JWT payloads when applicable |

### Typed accessors

Properties **`.admin`**, **`.customer`**, **`.public_user`**, **`.system`** raise **`ValueError`** if the entity is missing or not of that type. Use **`persona_is(AuthenticationPersona.…)`** before accessing.

### Helpers

- **`persona_is(persona)`** — equality check on persona.
- **`is_velmios_admin_or_system()`** — Velmios-realm admin or Velmios system process.

## AuthenticationPersona

`StrEnum` in **`velmios.core.types`**: `CUSTOMER`, `PUBLIC`, `ADMIN`, `SYSTEM`, `NONE`. Also re-exported from **`velmios.core.security`** for convenience.

## AuthenticationType

`Flag` enum in **`velmios.core.security`**: `HYDRA_INTERNAL_JWT`, `HYDRA_CUSTOMER_JWT`, `KRATOS_SESSION`, `NONE`. Used to limit which mechanisms a route or dependency considers.

## AuthenticationResolver

- Register authentications with **`add_authentication`**, ordered by insertion.
- **`authenticate(request)`** tries supported types; the **first successful** authentication (per resolver logic) wins, then **persona** is checked against **`_authorized_personas`** when configured.
- **`set_authorized_personas`** / **`set_supported_authentication_types`** are invoked by **`DependsAuthenticationContext`** before **`authenticate`**.

### Factory dependencies

| Function | Registered mechanisms |
|---|---|
| **`depends_authentication_resolver()`** | Internal JWT + customer JWT |
| **`depends_authentication_resolver_with_kratos_session()`** | Internal JWT + customer JWT + Kratos session (`velmios.core.security.resolvers`; not re-exported from `velmios.core.security` yet) |

### Context hooks (high level)

- **Internal JWT** → `SYSTEM` + **`SystemEntity`** in Velmios realm; **`scopes`** from token `scp`.
- **Customer JWT** → **`ADMIN`** or **`CUSTOMER`** with **`AdminLiteEntity`** / **`CustomerLiteEntity`** from payload extension; scopes from `scp`.
- **Kratos session** → **`AdminLiteEntity`** if identity realm is Velmios; else **`CustomerLiteEntity`** with cross-check against optional `realm_id` query parameter.

## Errors

- **`VelmiosNotAuthenticatedError`** — no successful authentication when none/public/none shortcuts apply. Applications should translate to HTTP **401** where appropriate.
- Resolver and hooks may raise **`VelmiosNotAuthenticatedError`** for malformed tokens or policy violations.

## Reference

- `src/velmios/core/security/contexts.py`
- `src/velmios/core/security/enums.py`
- `src/velmios/core/security/resolvers.py`
