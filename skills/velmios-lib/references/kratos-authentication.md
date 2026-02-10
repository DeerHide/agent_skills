# Kratos Authentication

## When to Use

- When you need to understand how **user session authentication** works in Velmios.
- When working with Ory Kratos identity traits, metadata, or session objects.
- When customizing the Kratos whoami or identity services.

## Overview

The Kratos authentication module provides Velmios-specific extensions to the `fastapi-factory-utilities` Kratos framework. It handles session cookie authentication, identity resolution, and maps Kratos sessions to Velmios entities.

```python
from velmios.core.services.kratos import (
    VelmiosKratosWhoamiService,
    VelmiosKratosIdentityService,
    VelmiosKratosSessionObject,
    VelmiosKratosIdentityObject,
    VelmiosKratosTraitsObject,
    VelmiosKratosPublicMetadataObject,
)
```

## Kratos Objects

### VelmiosKratosTraitsObject

Kratos identity traits with Velmios validated types.

```python
class VelmiosKratosTraitsObject(KratosTraitsObject):
    realm_id: RealmId
    email: Email
    username: Username
    phone: PhoneNumber
    country: Country
    first_name: Name
    last_name: Name
    birthday: date
    terms_of_service: bool
```

### VelmiosKratosPublicMetadataObject

Public metadata stored on Kratos identities.

```python
class VelmiosKratosPublicMetadataObject(MetadataObject):
    id: CustomerId | AdminId | PublicUserId
    realm_id: RealmId
    persona: AuthenticationPersona
    role: Union[PublicUserRole, AdminRole, CustomerRole]
```

**Validation rules:**
- `persona` MUST be `CUSTOMER`, `PUBLIC`, or `ADMIN` (not `SYSTEM`).
- Role type MUST match persona: `CustomerRole` for `CUSTOMER`, `PublicUserRole` for `PUBLIC`, `AdminRole` for `ADMIN`.
- Realm rules apply: `ADMIN` requires Velmios realm; `CUSTOMER` and `PUBLIC` require non-Velmios realm.

### VelmiosKratosSessionObject

Wraps a Kratos session with the Velmios identity type.

```python
class VelmiosKratosSessionObject(KratosSessionObject[VelmiosKratosIdentityObject]): ...
```

## Services

### VelmiosKratosWhoamiService

Calls the Kratos public API `/sessions/whoami` to resolve the current session.

```python
class VelmiosKratosWhoamiService(KratosGenericWhoamiService[VelmiosKratosSessionObject]): ...
```

### VelmiosKratosIdentityService

Calls the Kratos admin API for identity management.

```python
class VelmiosKratosIdentityService(
    KratosIdentityGenericService[VelmiosKratosIdentityObject, VelmiosKratosSessionObject]
): ...
```

NOTE: `create_identity()` raises `NotImplementedError` - identity creation is not yet implemented.

### VelmiosKratosSessionAuthenticationService

Security layer service that authenticates requests using Kratos sessions.

```python
from velmios.core.security.kratos import VelmiosKratosSessionAuthenticationService

class VelmiosKratosSessionAuthenticationService(
    KratosSessionAuthenticationService[VelmiosKratosSessionObject]
): ...
```

## Dependency Wiring

| Dependency | Returns | Description |
|---|---|---|
| `depends_velmios_kratos_whoami_service()` | `VelmiosKratosWhoamiService` | Requires `kratos_public` AioHttp resource |
| `depends_velmios_kratos_identity_service()` | `VelmiosKratosIdentityService` | Requires `kratos_admin` AioHttp resource |

These dependencies use `AioHttpResourceDepends` with keys `"kratos_public"` and `"kratos_admin"` to resolve the HTTP client resources from the `fastapi-factory-utilities` AioHttp plugin.

## Kratos to AuthenticationContext Mapping

When Kratos session authentication succeeds, the `kratos_session_authentication_context_hook` creates:

**Velmios realm session (admin):**
```python
AuthenticationContext(
    realm_id=VELMIOS_REALM_ID,
    persona=AuthenticationPersona.ADMIN,
    entity=AdminEntity(
        id=AdminId(session.identity.id),
        realm_id=VELMIOS_REALM_ID,
        role=session.identity.metadata_public.role,
        # ... traits fields
    ),
)
```

**Tenant realm session (customer):**
```python
AuthenticationContext(
    realm_id=RealmId(session.identity.traits.realm_id),
    persona=AuthenticationPersona.CUSTOMER,
    entity=CustomerEntity(
        id=CustomerId(session.identity.id),
        realm_id=RealmId(session.identity.traits.realm_id),
        role=session.identity.metadata_public.role,
        # ... traits fields
    ),
)
```

**Cross-realm protection:** If the `realm_id` query parameter does not match the session's realm, the hook returns `None` (authentication fails), preventing cross-realm impersonation.

## Reference

- `src/velmios/core/services/kratos.py`
- `src/velmios/core/security/kratos.py`
- `src/velmios/core/security/resolvers.py` (hooks)
