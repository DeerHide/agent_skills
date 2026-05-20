# Entities

## When to use

- Representing an **authenticated user** (admin, customer, public) or **system process** on `AuthenticationContext`.
- Reading lite entity fields (`id`, `realm_id`, `email`, `identity_id`, `role`, `persona`) from JWT or Kratos hooks.
- Modeling **realm-scoped feature flags** for storage and HTTP exposure.

## Overview

Velmios entities are Pydantic models that mix in `ApiEntityAbstract` from `fastapi-factory-utilities` so they double as response and query-filter models. They enforce realm boundary rules via field/model validators.

```python
from velmios.core.entities import (
    AdminLiteEntity,
    CustomerLiteEntity,
    PublicUserEntity,
    SystemEntity,
    FeatureForRealmEntity,
    FeaturesForRealmEntity,
    FeaturesForRealmQueryFilter,
)
```

IMPORTANT: Since `velmios_lib` 12.0.0 the non-lite `AdminEntity`, `CustomerEntity`, and `AuthenticatedUserEntityAbstract` are no longer exported. Use the lite variants below; if your service needs richer profile data, store it in its own persisted entity and combine it with the lite entity from the authentication context.

## AuthenticatedUserLiteEntityAbstract

Abstract base for authenticated human users (admins and customers) built on `ApiEntityAbstract`.

```python
class AuthenticatedUserLiteEntityAbstract(ApiEntityAbstract, ABC, Generic[GenericId]):
    model_config = ConfigDict(extra="ignore", arbitrary_types_allowed=True)

    id: Annotated[GenericId, ApiField(searchable=True)]
    realm_id: Annotated[RealmId, ApiField(searchable=True)]
    email: Annotated[Email, ApiField(updateable=True, searchable=True)]
```

`extra="ignore"` lets the JWT/Kratos hooks pass through extra payload fields without raising. `email` is `UpdateableField` so the future profile-update path can target it via `reconcile_update_request` (see the [FFU PUT update reference](../../fastapi-factory-utilities/references/api-response-and-update.md)).

## AdminLiteEntity

```python
class AdminLiteEntity(AuthenticatedUserLiteEntityAbstract[AdminId]):
    role: Annotated[AdminRole, ApiField(searchable=True)]
    persona: Annotated[Literal[AuthenticationPersona.ADMIN], ApiField(searchable=True)]
    identity_id: Annotated[KratosIdentityId, ApiField(searchable=True)]

    @computed_field
    @property
    def username(self) -> Username:
        return Username(self.email.split("@")[0])
```

**Realm rule:** `realm_id` MUST equal `VELMIOS_REALM_ID`. Raises `ValueError("Realm ID mismatch")` otherwise.

The admin `username` is derived from the email local part (no separate stored field).

## CustomerLiteEntity

```python
class CustomerLiteEntity(AuthenticatedUserLiteEntityAbstract[CustomerId]):
    role: Annotated[CustomerRole, ApiField(searchable=True)]
    persona: Annotated[Literal[AuthenticationPersona.CUSTOMER], ApiField(searchable=True)]
    identity_id: Annotated[KratosIdentityId, ApiField(searchable=True)]
```

**Realm rule:** `realm_id` MUST NOT equal `VELMIOS_REALM_ID`. Raises `ValueError("Realm ID cannot be the Velmios realm ID")` otherwise.

## PublicUserEntity

Represents a public-facing end user. Supports both authenticated and guest states.

```python
class PublicUserEntity(ApiEntityAbstract):
    id: PublicUserId | None = None
    persona: Literal[AuthenticationPersona.PUBLIC]
    realm_id: RealmId
    identity_id: KratosIdentityId | None = None
    username: Username | None = None
    email: Email | None = None
    phone: PhoneNumber | None = None
    country: Country | None = None
    first_name: Name | None = None
    last_name: Name | None = None
    birthday: date | None = None
    terms_of_service: bool | None = None
    role: PublicUserRole = PublicUserRole.GUEST
```

Behavioural rules (`model_validator`):

- When `id is None`, `role` is forced to `PublicUserRole.GUEST`.
- When `id` is set, all of `username`, `email`, `phone`, `country`, `first_name`, `last_name`, `birthday`, and `terms_of_service` MUST be provided. Raises `ValueError("All fields are required for a public user authenticated.")` otherwise.
- `realm_id` MUST NOT equal `VELMIOS_REALM_ID`.

The guest variant is what `AuthenticationResolver.authorize_public` constructs from the `realm_id` query parameter when public access is enabled.

## SystemEntity

Represents a system process for machine-to-machine communication.

```python
class SystemEntity(ApiEntityAbstract):
    id: SystemId
    persona: Literal[AuthenticationPersona.SYSTEM]
    realm_id: RealmId
    role: SystemRole
```

Realm/role rules (`model_validator`):

- `SystemRole.SYSTEM` MUST be paired with `realm_id == VELMIOS_REALM_ID`.
- `SystemRole.CUSTOMER` MUST be paired with `realm_id != VELMIOS_REALM_ID`.

Helper: `is_velmios_system() -> bool` returns `True` when the entity is the Velmios platform system process. `AuthenticationContext.is_velmios_admin_or_system()` uses this signal alongside the admin / Velmios realm check.

## Feature aggregates

Realm-scoped feature toggles. Both classes inherit `ApiEntityAbstract` / `SearchableEntity` and use `UpdateableField` so the PUT reconciliation pipeline targets only intended fields.

```python
class FeatureForRealmEntity(ApiEntityAbstract, SearchableEntity):
    feature: Annotated[Feature, ApiField(searchable=True), UpdateableField]
    enabled: Annotated[bool, ApiField(searchable=True), UpdateableField]
    updated_at: Annotated[datetime, ApiField(searchable=True)]


class FeaturesForRealmEntity(PersistedEntity[FeatureForRealmEntityId], SearchableEntity):
    realm_id: Annotated[RealmId, ApiField(searchable=True)]
    features: Annotated[
        list[FeatureForRealmEntity],
        ApiField(searchable=True),
        UpdateableField,
    ] = Field(default_factory=list)
    configuration_checksum: Annotated[str, ApiField(searchable=True)]


class FeaturesForRealmQueryFilter(FeaturesForRealmEntity.build_query_filter_model()):
    """Dynamic query filter built from the entity."""
```

- `FeatureForRealmEntity.__eq__` / `__hash__` compare on `feature` key alone so set operations dedupe correctly.
- `configuration_checksum` is recomputed by `FeaturesService` whenever supported features / defaults / overrides change; out-of-date documents are realigned at startup.

See [Features and resource APIs](features-and-resource-apis.md) for HTTP and use-case wiring.

## Realm-isolated persisted abstracts

`velmios.core.abstracts` exposes the realm-isolated bases that every persisted entity in a Velmios service should extend:

- `RealmIsolatedEntity` — adds `realm_id` and a `SearchableField` marker; mix into transient response models.
- `RealmIsolatedPersistedEntity[Id]` — `PersistedEntity[Id]` + `RealmIsolatedEntity`; preserves the generic id type parameter.
- `RealmIsolatedPersistedAuditableEntity[Id]` — same as above but auditable (`PersistedAuditableEntity` mixin) so `GenericAuditService` can publish realm-aware audit events. See [Audit and events](audit-and-events.md).

## Reference

- `src/velmios/core/entities/__init__.py`
- `src/velmios/core/entities/abstracts.py`
- `src/velmios/core/entities/admin.py`
- `src/velmios/core/entities/customer.py`
- `src/velmios/core/entities/public_user.py`
- `src/velmios/core/entities/system.py`
- `src/velmios/core/entities/features.py`
- `src/velmios/core/abstracts/entities.py`
