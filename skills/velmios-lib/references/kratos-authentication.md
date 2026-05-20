# Kratos authentication

## When to use

- Understanding how **session cookie authentication** works in Velmios.
- Reading or writing Kratos identity traits and metadata via the Velmios admin service.
- Customizing the Kratos whoami or identity admin services.

## Overview

Velmios builds on the `fastapi-factory-utilities` Kratos framework with Velmios-specific traits, metadata, sessions, and OIDC credential DTOs.

```python
from velmios.core.services.kratos import (
    VelmiosKratosWhoamiService,
    VelmiosKratosIdentityService,
    VelmiosKratosSessionObject,
    VelmiosKratosIdentityObject,
    VelmiosKratosTraitsObject,
    VelmiosKratosPublicMetadataObject,
    VelmiosKratosAdminMetadataObject,
    VelmiosKratosOIDCCredentialsObject,
    VelmiosKratosOIDCCredentialsConfigObject,
    VelmiosKratosOIDCProviderObject,
    VelmiosKratosIdentityCredentialsObject,
    depends_velmios_kratos_whoami_service,
    depends_velmios_kratos_identity_service,
)
```

## DTOs

### VelmiosKratosTraitsObject

Velmios constrains traits to the minimal contract required for sign-in. `extra="ignore"` lets the schema evolve without breaking the resolver.

```python
class VelmiosKratosTraitsObject(KratosTraitsObject):
    model_config = ConfigDict(extra="ignore")

    email: Email
    hd: str | None = None  # optional Google Workspace domain hint for admin registrations
```

Admin and customer flows derive their realm and role from `metadata_public` instead of traits. The previous `VelmiosKratosIdentitySchemaId` and trait `schema_id` field were removed in v12.0.2.

### VelmiosKratosPublicMetadataObject

Canonical source of truth for authentication fields. Validators:

- `persona` MUST be one of `CUSTOMER`, `PUBLIC`, or `ADMIN` (never `SYSTEM`, `PARTIAL`, or `NONE`).
- `role` MUST be the matching enum for the persona (`CustomerRole`, `PublicUserRole`, `AdminRole`).
- Realm rules: `ADMIN` MUST be paired with the Velmios realm; `CUSTOMER` / `PUBLIC` MUST NOT use it.

`VelmiosKratosAdminMetadataObject` is the legacy mirror kept for backward compatibility while services migrate to `metadata_public`. Validators are identical.

### VelmiosKratosIdentityObject and VelmiosKratosSessionObject

```python
class VelmiosKratosIdentityObject(
    KratosIdentityObject[
        VelmiosKratosTraitsObject,
        VelmiosKratosPublicMetadataObject,
        VelmiosKratosAdminMetadataObject,
    ]
):
    credentials: VelmiosKratosIdentityCredentialsObject | None = None


class VelmiosKratosSessionObject(KratosSessionObject[VelmiosKratosIdentityObject]):
    """Velmios Kratos session object."""
```

`credentials.oidc.config.providers` exposes the typed OIDC provider/subject pairs registered for each identity (added in v10.3.4).

## Services

| Class | Role |
|---|---|
| `VelmiosKratosWhoamiService` | Calls Kratos `/sessions/whoami` to resolve the current session. |
| `VelmiosKratosIdentityService` | Wraps the Kratos admin identity API. `create_identity()` currently raises `NotImplementedError`. |
| `VelmiosKratosSessionAuthenticationService` (in `velmios.core.security.kratos`) | Security-layer service that authenticates requests using Kratos sessions. |

Dependencies:

| Dependency | Returns | Notes |
|---|---|---|
| `depends_velmios_kratos_whoami_service()` | `VelmiosKratosWhoamiService` | Requires the `kratos_public` AioHttp resource. |
| `depends_velmios_kratos_identity_service()` | `VelmiosKratosIdentityService` | Requires the `kratos_admin` AioHttp resource. |

The `kratos_admin` service also benefits from `delete_session(session_id)` added in `fastapi-factory-utilities` v5.1.0 — see the [Kratos service reference](../../fastapi-factory-utilities/references/kratos-service.md).

## Mapping to AuthenticationContext

The `kratos_session_authentication_context_hook` (`velmios.core.security.resolvers`) picks the effective metadata as follows:

1. Use `kratos_session.identity.metadata_public` when present.
2. Otherwise fall back to `metadata_admin` (legacy mirror).
3. When **both** are missing, return a **PARTIAL** context — `realm_id=None`, `entity=None`, but `identity_id` set from the Kratos identity id. Treat this as a "needs onboarding" state in the application.

When metadata is present:

```python
# Velmios admin (metadata_public.realm_id == VELMIOS_REALM_ID)
AuthenticationContext(
    realm_id=VELMIOS_REALM_ID,
    persona=AuthenticationPersona.ADMIN,
    entity=AdminLiteEntity(
        id=AdminId(metadata_public.id),
        realm_id=VELMIOS_REALM_ID,
        role=metadata_public.role,
        persona=AuthenticationPersona.ADMIN,
        email=session.identity.traits.email,
        identity_id=KratosIdentityId(session.identity.id),
    ),
)


# Tenant customer (metadata_public.realm_id != VELMIOS_REALM_ID)
AuthenticationContext(
    realm_id=RealmId(metadata_public.realm_id),
    persona=AuthenticationPersona.CUSTOMER,
    identity_id=KratosIdentityId(session.identity.id),
    entity=CustomerLiteEntity(
        id=CustomerId(metadata_public.id),
        realm_id=RealmId(metadata_public.realm_id),
        role=metadata_public.role,
        email=session.identity.traits.email,
        persona=AuthenticationPersona.CUSTOMER,
        identity_id=KratosIdentityId(session.identity.id),
    ),
)
```

**Cross-realm protection:** when the request carries a `realm_id` query parameter, the hook returns `None` (so the resolver tries the next mechanism or fails) whenever the parameter does not match the session's realm. This prevents tenant impersonation across realms.

**OIDC registration:** `VelmiosKratosTraitsObject.realm_id` is intentionally absent (held in `metadata_public` instead) so OIDC registration flows succeed before the customer record is created (v10.2.1). The optional `hd` field captures the Google Workspace domain hint used by admin registrations.

## Reference

- `src/velmios/core/services/kratos.py`
- `src/velmios/core/security/kratos.py`
- `src/velmios/core/security/resolvers.py`
