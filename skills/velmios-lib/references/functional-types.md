# Functional and related scalar types

## When to use

- Strongly-typed **`uuid.UUID`** identifiers for Velmios domains.
- **`AuthenticationPersona`** in route signatures and models.
- Stable string keys for **features** and **Kratos** linkage.

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
| `FeatureForRealmEntityId` | Primary key for persisted **features per realm** aggregate. |
| `KratosIdentityId` | Ory Kratos identity id (`NewType` over `uuid.UUID`). |

## AuthenticationPersona

`StrEnum`: `customer`, `public`, `admin`, `system`, `none`. Defined in **`velmios.core.types`** and re-exported from **`velmios.core.security`** for convenience.

## Feature string type

**`Feature`** — validated `str` subclass for feature keys (length and character class constraints). Use on **`FeatureForRealmEntity`** and related APIs.

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

Tenant customers MUST NOT use the Velmios realm id; admins and Velmios system roles MUST use it where required by entity validators.

## Reference

- `src/velmios/core/types/functionals.py`
- `src/velmios/core/types/persona.py`
- `src/velmios/core/types/feature.py`
- `src/velmios/core/types/kratos.py`
- `src/velmios/core/constants.py`
