# Permissions

## When to use

- Implementing **role-based permission checks** in a Velmios microservice.
- Composing **AND / OR** permission expressions or **request-aware predicates**.
- Defining a FastAPI dependency that enforces permissions and surfaces diagnostics on failure.

## Overview

`velmios.core.services.permissions` provides a composable permission system. Each microservice implements a concrete `PermissionsResolverService` to map roles to permissions, then declares per-route requirements either as a flat list (legacy `required_permissions` AND mode) or as a composable `PermissionRequirement` tree (`&` / `|` / `predicate(...)`).

```python
from velmios.core.services.permissions import (
    Permission,
    PermissionRequirement,
    AbstractPermissionsResolverService,
    AbstractDependsPermissionsRequired,
    PermissionsRequiredError,
    PermissionsResolverError,
    PermissionPredicateError,
    predicate,
)
```

`Permission` is **no longer a `str` subclass** since v11.0.0; compare with other `Permission` instances and use `Permission.value` (or `str(permission)`) when you need the raw string.

## Permission

Validated permission identifier.

```python
Permission("velmios.my_service.my_entity:read")
Permission("velmios.my_service.my_entity:read") | Permission("velmios.my_service.my_entity:admin")
Permission("velmios.my_service.my_entity:read") & Permission("velmios.my_service.my_entity:write")
```

- **Format:** alphanumeric, underscores (`_`), hyphens (`-`), dots (`.`), and colons (`:`). Invalid input raises `ValueError`.
- **Convention:** `namespace.service.resource:action`.
- `Permission.__hash__` / `__eq__` ensure permissions work as keys in `set[Permission]`.

## PermissionRequirement

Abstract base of the requirement tree. Five built-in nodes are available, but you normally compose them with operators or `predicate(...)`:

| Node | Purpose |
|---|---|
| `AlwaysAllowedRequirement` | Always true (also the default for empty legacy permission lists). |
| `PermissionLeaf` | Requires a single permission to be in the resolved context set. |
| `AndRequirement` | Logical AND of two requirements. |
| `OrRequirement` | Logical OR of two requirements. |
| `ContextPredicateRequirement` | Sync callable `(AuthenticationContext, Request | None) -> bool` for ad-hoc checks. |

### Composing requirements

```python
from velmios.core.services.permissions import Permission, predicate
from velmios.core.types import AuthenticationPersona


def caller_is_self_or_admin(auth_ctx, request):
    target_id = request.path_params.get("user_id") if request else None
    return auth_ctx.persona == AuthenticationPersona.ADMIN or (
        target_id is not None and str(auth_ctx.entity.id) == target_id
    )


read_or_admin = (
    Permission("my_service.users:read")
    | Permission("my_service.users:admin")
)

read_with_self_guard = read_or_admin & predicate("caller_is_self_or_admin", caller_is_self_or_admin)
```

`predicate(name, callable)` wraps a sync function. Predicate exceptions become `PermissionPredicateError`, which the dependency re-raises as `PermissionsRequiredError` with `required_expression` diagnostics.

### Inspecting the tree

- `requirement.describe()` returns the parenthesized expression string (also used as `required_expression` on errors).
- `collect_permissions_from_requirement(requirement)` flattens leaves in pre-order (deduplicated, order preserved) — useful for documentation or `required_permissions` on logs.

## AbstractPermissionsResolverService

Subclass per microservice to map roles to leaf permissions.

```python
class AbstractPermissionsResolverService(ABC):
    @abstractmethod
    def resolve_admin_role(self, admin_role: AdminRole, authentication_context: AuthenticationContext) -> list[Permission]: ...

    @abstractmethod
    def resolve_customer_role(self, customer_role: CustomerRole, authentication_context: AuthenticationContext) -> list[Permission]: ...

    @abstractmethod
    def resolve_public_user_role(self, public_user_role: PublicUserRole, authentication_context: AuthenticationContext) -> list[Permission]: ...

    @abstractmethod
    def resolve_system_role(self, system_role: SystemRole, authentication_context: AuthenticationContext) -> list[Permission]: ...

    def resolve(self, authentication_context: AuthenticationContext) -> list[Permission]: ...
```

`resolve()` dispatches by `authentication_context.persona`. It raises `PermissionsResolverError` when the context has no entity or an unknown persona. The `authentication_context` argument is forwarded to every role resolver so concrete services can do realm-aware logic.

### Implementation example

```python
from velmios.core.services.permissions import AbstractPermissionsResolverService, Permission
from velmios.core.security import AuthenticationContext
from velmios.core.types import AdminRole, CustomerRole, PublicUserRole, SystemRole


class MyServicePermissionsResolver(AbstractPermissionsResolverService):
    def resolve_admin_role(self, admin_role, authentication_context):
        if admin_role == AdminRole.OPERATOR:
            return [
                Permission("my_service.users:read"),
                Permission("my_service.users:write"),
                Permission("my_service.users:operate"),
            ]
        return []

    def resolve_customer_role(self, customer_role, authentication_context):
        base = [Permission("my_service.users:read")]
        if customer_role in (CustomerRole.OWNER, CustomerRole.MANAGER):
            base.append(Permission("my_service.users:write"))
        return base

    def resolve_public_user_role(self, public_user_role, authentication_context):
        if public_user_role == PublicUserRole.USER:
            return [Permission("my_service.users:read")]
        return []

    def resolve_system_role(self, system_role, authentication_context):
        return [Permission("my_service.users:read"), Permission("my_service.users:write")]
```

## AbstractDependsPermissionsRequired

Base class for FastAPI dependencies that enforce a requirement and return the authenticated context.

```python
class AbstractDependsPermissionsRequired(ABC):
    def __init__(
        self,
        required_permissions: list[Permission] | None = None,
        permissions_resolver_service: AbstractPermissionsResolverService | None = None,
        *,
        required_requirement: PermissionRequirement | None = None,
    ) -> None: ...

    def check(self, authentication_context: AuthenticationContext, request: Request | None = None) -> None: ...
    def __call__(self, authentication_context: AuthenticationContext, request: Request | None = None) -> AuthenticationContext: ...
```

Rules:

- Either pass `required_permissions` (flat list, AND-folded) **or** `required_requirement` (composable tree); passing both raises `ValueError`.
- `permissions_resolver_service` is required in both modes.
- Empty legacy lists become `AlwaysAllowedRequirement` (no-op check).

### Wiring a per-service dependency

```python
from fastapi import Depends, Request
from velmios.core.services.permissions import AbstractDependsPermissionsRequired, Permission, predicate
from velmios.core.security import (
    AuthenticationContext,
    AuthenticationType,
    DependsAuthenticationContext,
)
from velmios.core.types import AuthenticationPersona


class DependsPermissionsRequired(AbstractDependsPermissionsRequired):
    def __init__(self, *, required_permissions=None, required_requirement=None):
        super().__init__(
            required_permissions=required_permissions,
            permissions_resolver_service=MyServicePermissionsResolver(),
            required_requirement=required_requirement,
        )

    def __call__(
        self,
        request: Request,
        authentication_context: AuthenticationContext = Depends(
            DependsAuthenticationContext(
                authorized_personas=[AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER],
                supported_authentication_types=[
                    AuthenticationType.HYDRA_CUSTOMER_JWT,
                    AuthenticationType.KRATOS_SESSION,
                ],
            )
        ),
    ) -> AuthenticationContext:
        return super().__call__(authentication_context=authentication_context, request=request)
```

### Usage in routes

```python
@app.get("/users")
async def list_users(
    auth: AuthenticationContext = Depends(
        DependsPermissionsRequired(required_permissions=[Permission("my_service.users:read")])
    ),
) -> list:
    return []


@app.put("/users/{user_id}")
async def update_user(
    user_id: str,
    auth: AuthenticationContext = Depends(
        DependsPermissionsRequired(
            required_requirement=(
                Permission("my_service.users:write")
                & predicate("caller_is_self_or_admin", caller_is_self_or_admin)
            )
        )
    ),
) -> dict:
    return {"user_id": user_id}
```

`check()`:

1. Resolves the context permissions via the resolver service.
2. Evaluates the requirement tree (`AlwaysAllowed` / leaves / AND / OR / predicate).
3. Raises `PermissionsRequiredError` when the requirement fails or a predicate explodes.

## Error types

### PermissionsRequiredError

Raised when the resolved permission set or a predicate does not satisfy the requirement.

```python
PermissionsRequiredError(
    required_permissions=[...],
    context_permissions=[...],
    persona=...,
    realm_id=...,
    required_expression="(my_service.users:write & predicate(caller_is_self_or_admin))",
)
```

The Velmios HTTP exception handler (`register_security_exception_handlers`, see [Exception handling](exception-handling.md)) maps this to HTTP 403 with the standard error envelope and the OTel `velmios.security.auth_failures` counter.

### PermissionsResolverError

Raised by the resolver service when the authentication context has no entity, an unknown persona, or another consistency error.

### PermissionPredicateError

Raised internally when a `ContextPredicateRequirement` callable throws; reused as the `__cause__` of the resulting `PermissionsRequiredError`.

## Best practices

1. One `PermissionsResolverService` per microservice. Keep role-to-permission maps centralized.
2. Use `Permission("namespace.service.resource:action")` consistently.
3. Prefer composing requirements with `&` / `|` / `predicate(...)` over re-checking inside route bodies.
4. Use `predicate(...)` for cross-cutting checks that need the `Request` (path params, host-aware logic).
5. Let `register_security_exception_handlers` map `PermissionsRequiredError` to HTTP 403 and emit telemetry — do not catch it in routes.

## Reference

- `src/velmios/core/services/permissions.py`
- `src/velmios/core/security/handlers.py`
