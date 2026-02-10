# Role Enums

## When to Use

- When you need to reference **user roles** for authorization logic.
- When defining entity fields or permission resolver mappings.
- When checking a user's role within an `AuthenticationContext`.

## Overview

Role enums are `StrEnum` types that define the possible roles for each persona in the Velmios platform.

```python
from velmios.core.types import AdminRole, CustomerRole, PublicUserRole, SystemRole
```

## Enum Definitions

### AdminRole

Roles for Velmios platform administrators. Admins MUST belong to the Velmios realm.

| Value | String | Description |
|---|---|---|
| `OPERATOR` | `"operator"` | Platform operator with full admin privileges |

### CustomerRole

Roles for tenant customers. Customers MUST NOT belong to the Velmios realm.

| Value | String | Description |
|---|---|---|
| `OWNER` | `"owner"` | Tenant owner with full control |
| `MANAGER` | `"manager"` | Tenant manager with elevated privileges |
| `MEMBER` | `"member"` | Standard tenant member |

### PublicUserRole

Roles for public-facing end users.

| Value | String | Description |
|---|---|---|
| `USER` | `"user"` | Authenticated public user (has an identity) |
| `GUEST` | `"guest"` | Unauthenticated guest user (no identity, `id` is `None`) |

### SystemRole

Roles for machine-to-machine system entities.

| Value | String | Description |
|---|---|---|
| `SYSTEM` | `"system"` | Velmios platform system process (Velmios realm only) |
| `CUSTOMER` | `"customer"` | Tenant system process (non-Velmios realm only) |

## Realm Constraints

IMPORTANT: Roles and realms are tightly coupled:

- `AdminRole` entities MUST have `realm_id == VELMIOS_REALM_ID`.
- `CustomerRole` entities MUST have `realm_id != VELMIOS_REALM_ID`.
- `SystemRole.SYSTEM` MUST have `realm_id == VELMIOS_REALM_ID`.
- `SystemRole.CUSTOMER` MUST have `realm_id != VELMIOS_REALM_ID`.

These constraints are enforced by entity validators and MUST NOT be bypassed.

## Reference

- `src/velmios/core/types/role.py`
