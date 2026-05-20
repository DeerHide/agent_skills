# Functional and related scalar types

## When to use

- Strongly-typed `uuid.UUID` identifiers for Velmios domains.
- `AuthenticationPersona` in route signatures, models, and entity validators.
- Stable string keys for **features** and **Kratos** linkage.
- Code-declared global overrides for feature flags.

## UUID-based identifiers (`NewType`)

```python
from velmios.core.types import (
    RealmId,
    CustomerId,
    AdminId,
    SystemId,
    PublicUserId,
    FeatureForRealmEntityId,
    KratosIdentityId,
)
```

| Type | Purpose |
|---|---|
| `RealmId` | Tenant or platform realm. Reserved Velmios realm: `00000000-0000-0000-0000-000000000000`. |
| `CustomerId` | Customer user id (tenant realm). |
| `AdminId` | Admin user id (Velmios realm). |
| `SystemId` | System / M2M principal id. |
| `PublicUserId` | Public end-user id. |
| `FeatureForRealmEntityId` | Primary key for the persisted **features per realm** aggregate. |
| `KratosIdentityId` | Ory Kratos identity id (`NewType` over `uuid.UUID`). |

All seven identifiers are `NewType` wrappers over `uuid.UUID`, so `QueryResolver` (from `fastapi-factory-utilities`) automatically coerces them from query strings when they appear on a `QueryAbstract` filter model.

## AuthenticationPersona

`StrEnum` in `velmios.core.types` re-exported from `velmios.core.security`:

| Member | Value | Description |
|---|---|---|
| `CUSTOMER` | `customer` | Customer of the Velmios platform. |
| `PUBLIC` | `public` | Public end-user of a customer realm. |
| `ADMIN` | `admin` | Velmios platform administrator. |
| `SYSTEM` | `system` | Velmios system / M2M principal. |
| `PARTIAL` | `partial` | Incomplete Kratos registration; missing `metadata_public` and `traits.realm_id`. |
| `NONE` | `none` | Explicit anonymous context (allowed only when configured on the resolver). |

The validator on `AuthenticationContext` requires `realm_id` for every persona except `NONE` (where `realm_id` MUST be `None`).

## Feature string type

`Feature` — validated `str` subclass for feature keys:

- Length: 3 to 64 characters.
- Allowed characters: `a-z`, `0-9`, `_`, `-`, `.`, `:`.
- Values are normalized to lowercase by the validator.

```python
from velmios.core.types import Feature

flag = Feature("my_component:beta_flag")  # accepted
Feature("BadFeature!")  # raises ValueError
```

## FeatureGlobalOverride

Code-declared override applied by `FeaturesService` before the per-realm stored value:

```python
from velmios.core.types import FeatureGlobalOverride

FeatureGlobalOverride.NONE             # no override; per-realm value wins
FeatureGlobalOverride.FORCE_ENABLED    # service-wide ON
FeatureGlobalOverride.FORCE_DISABLED   # service-wide OFF
```

`FeatureGlobalOverride.NONE` is the default. Non-`NONE` overrides:

- Cause `FeaturesService.is_enabled(...)` to short-circuit to the override.
- Cause `FeaturesUpdateUseCase` / `FeaturesAPI.update` to reject PUT requests that try to change the field (HTTP 403).
- Are returned to clients on each `FeatureForRealmItem.global_override`.

See [Features and resource APIs](features-and-resource-apis.md) for the full registration flow with `FeatureDeclaration`.

## Usage

```python
import uuid

from velmios.core.types import RealmId, CustomerId, Feature

realm_id = RealmId(uuid.uuid4())
customer_id = CustomerId(uuid.uuid4())
feature = Feature("my_component:beta_flag")
```

## Constants

```python
from velmios.core.constants import VELMIOS_REALM_ID
```

- Tenant `CustomerLiteEntity` and `PublicUserEntity` MUST NOT use the Velmios realm id.
- `AdminLiteEntity` and `SystemEntity(role=SystemRole.SYSTEM)` MUST use it.

## Reference

- `src/velmios/core/types/functionals.py`
- `src/velmios/core/types/persona.py`
- `src/velmios/core/types/feature.py`
- `src/velmios/core/types/kratos.py`
- `src/velmios/core/constants.py`
