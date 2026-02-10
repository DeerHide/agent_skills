# Functional Types

## When to Use

- When you need a **strongly-typed UUID identifier** for a Velmios domain concept.
- When defining Pydantic models, entity fields, or function signatures that accept realm, user, or system identifiers.
- When you want compile-time and runtime distinction between different UUID-based identifiers.

## Overview

Functional types are `NewType` wrappers around `uuid.UUID`. They provide semantic meaning and type safety without runtime overhead beyond standard UUID validation.

```python
from velmios.core.types import RealmId, CustomerId, AdminId, SystemId, PublicUserId
```

## Type Definitions

| Type | Base | Purpose |
|---|---|---|
| `RealmId` | `uuid.UUID` | Tenant realm identifier. The reserved Velmios realm is `00000000-0000-0000-0000-000000000000`. |
| `CustomerId` | `uuid.UUID` | Customer user identifier (tenant realm only). |
| `AdminId` | `uuid.UUID` | Admin user identifier (Velmios realm only). |
| `SystemId` | `uuid.UUID` | System process identifier for machine-to-machine calls. |
| `PublicUserId` | `uuid.UUID` | Public user identifier (guest or authenticated end-user). |

## Usage

```python
import uuid
from velmios.core.types import RealmId, CustomerId

realm_id = RealmId(uuid.uuid4())
customer_id = CustomerId(uuid.uuid4())
```

These types are accepted directly by Pydantic models and FastAPI path/query parameters.

## Constants

The reserved Velmios realm ID is available as a constant:

```python
from velmios.core.constants import VELMIOS_REALM_ID
# VELMIOS_REALM_ID == RealmId(uuid.UUID("00000000-0000-0000-0000-000000000000"))
```

IMPORTANT: The Velmios realm ID is reserved for platform-level operations (admins, system entities). Tenant customers MUST NOT use this realm ID.

## Reference

- `src/velmios/core/types/functionals.py`
- `src/velmios/core/constants.py`
