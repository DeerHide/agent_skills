# Entities

## When to Use

- When you need to represent an **authenticated user** or **system process** in domain logic.
- When constructing or consuming an `AuthenticationContext`.
- When implementing business rules that depend on user persona and realm.

## Overview

Entities are Pydantic `BaseModel` subclasses representing the four persona types in the Velmios platform. They enforce realm boundary rules via field validators.

```python
from velmios.core.entities import AdminEntity, CustomerEntity, PublicUserEntity, SystemEntity
```

## Entity Reference

### AdminEntity

Represents a Velmios platform administrator. Extends `AuthenticatedUserEntityAbstract`.

```python
from velmios.core.entities import AdminEntity
from velmios.core.types import AdminId, AdminRole, RealmId, Email, Username, PhoneNumber, Name, Country
from velmios.core.constants import VELMIOS_REALM_ID

admin = AdminEntity(
    id=AdminId(uuid.uuid4()),
    realm_id=VELMIOS_REALM_ID,  # MUST be Velmios realm
    role=AdminRole.OPERATOR,
    username=Username("admin_user"),
    email=Email("admin@velmios.com"),
    phone=PhoneNumber("+14155550100"),
    country=Country("US"),
    first_name=Name("Jane"),
    last_name=Name("Doe"),
    birthday=date(1990, 1, 1),
    terms_of_service=True,
)
```

**Fields:** `id: AdminId`, `role: AdminRole`, plus all `AuthenticatedUserEntityAbstract` fields.

**Realm rule:** `realm_id` MUST equal `VELMIOS_REALM_ID`. Raises `ValueError` otherwise.

### CustomerEntity

Represents a tenant customer. Extends `AuthenticatedUserEntityAbstract`.

```python
from velmios.core.entities import CustomerEntity
from velmios.core.types import CustomerId, CustomerRole, RealmId

customer = CustomerEntity(
    id=CustomerId(uuid.uuid4()),
    realm_id=RealmId(uuid.uuid4()),  # MUST NOT be Velmios realm
    role=CustomerRole.OWNER,
    # ... all AuthenticatedUserEntityAbstract fields
)
```

**Fields:** `id: CustomerId`, `role: CustomerRole`, plus all `AuthenticatedUserEntityAbstract` fields.

**Realm rule:** `realm_id` MUST NOT equal `VELMIOS_REALM_ID`. Raises `ValueError` otherwise.

### PublicUserEntity

Represents a public-facing end user. Supports both authenticated and guest states.

```python
from velmios.core.entities import PublicUserEntity
from velmios.core.types import RealmId, PublicUserRole

# Guest user (unauthenticated)
guest = PublicUserEntity(
    realm_id=RealmId(uuid.uuid4()),
    role=PublicUserRole.GUEST,
)

# Authenticated user (all fields required)
user = PublicUserEntity(
    id=PublicUserId(uuid.uuid4()),
    realm_id=RealmId(uuid.uuid4()),
    role=PublicUserRole.USER,
    username=Username("public_user"),
    email=Email("user@example.com"),
    phone=PhoneNumber("+14155550200"),
    country=Country("CA"),
    first_name=Name("John"),
    last_name=Name("Smith"),
    birthday=date(1995, 6, 15),
    terms_of_service=True,
)
```

**Fields:** All fields are optional except `realm_id` and `role`.

**Rules:**
- When `id` is `None`, role is automatically set to `GUEST`.
- When `id` is set, ALL fields (`username`, `email`, `phone`, `country`, `first_name`, `last_name`, `birthday`, `terms_of_service`) MUST be provided. Raises `ValueError` otherwise.

### SystemEntity

Represents a system process for machine-to-machine communication.

```python
from velmios.core.entities import SystemEntity
from velmios.core.types import SystemId, SystemRole, RealmId
from velmios.core.constants import VELMIOS_REALM_ID

# Velmios system process
system = SystemEntity(
    id=SystemId(uuid.uuid4()),
    realm_id=VELMIOS_REALM_ID,
    role=SystemRole.SYSTEM,
)

# Tenant system process
tenant_system = SystemEntity(
    id=SystemId(uuid.uuid4()),
    realm_id=RealmId(uuid.uuid4()),  # Non-Velmios realm
    role=SystemRole.CUSTOMER,
)
```

**Fields:** `id: SystemId`, `realm_id: RealmId`, `role: SystemRole`.

**Realm rules:**
- `SystemRole.SYSTEM` MUST have `realm_id == VELMIOS_REALM_ID`.
- `SystemRole.CUSTOMER` MUST have `realm_id != VELMIOS_REALM_ID`.

**Helper method:** `is_velmios_system() -> bool` returns `True` if the entity is a Velmios platform system process.

## AuthenticatedUserEntityAbstract

Abstract base class for entities that represent authenticated human users (`AdminEntity`, `CustomerEntity`).

**Fields:**

| Field | Type | Description |
|---|---|---|
| `realm_id` | `RealmId` | Tenant realm identifier |
| `username` | `Username` | Validated username (3-32 chars) |
| `email` | `Email` | Validated email address |
| `phone` | `PhoneNumber` | E.164 phone number |
| `country` | `Country` | ISO 3166-1 country code |
| `first_name` | `Name` | Validated first name |
| `last_name` | `Name` | Validated last name |
| `birthday` | `date` | Date of birth |
| `terms_of_service` | `bool` | Terms of service acceptance |

## Reference

- `src/velmios/core/entities/abstracts.py`
- `src/velmios/core/entities/admin.py`
- `src/velmios/core/entities/customer.py`
- `src/velmios/core/entities/public_user.py`
- `src/velmios/core/entities/system.py`
