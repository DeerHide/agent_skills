# Permissions

## When to Use

- When you need to implement **role-based permission checks** in a Velmios microservice.
- When you need to define **service-specific permissions** and map them to roles.
- When you need a FastAPI dependency that enforces permissions on an endpoint.

## Overview

The permissions module provides an abstract framework for resolving and enforcing role-based permissions. Each microservice implements its own concrete `PermissionsResolverService` to define role-to-permission mappings.

```python
from velmios.core.services.permissions import (
    Permission,
    AbstractPermissionsResolverService,
    AbstractDependsPermissionsRequired,
    PermissionsRequiredError,
    PermissionsResolverError,
)
```

## Permission Type

A validated string representing a permission identifier.

```python
Permission("velmios.my_service.my_entity:read")
Permission("velmios.my_service.my_entity:write")
Permission("velmios.my_service.my_entity:operate")
```

**Format:** Only alphanumeric characters, underscores (`_`), hyphens (`-`), dots (`.`), and colons (`:`) are allowed. Raises `ValueError` for invalid formats.

**Convention:** `namespace.service.resource:action`

## AbstractPermissionsResolverService

Abstract base class that microservices MUST extend to define their permission mappings.

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

### Implementation Example

```python
from velmios.core.services.permissions import AbstractPermissionsResolverService, Permission
from velmios.core.security import AuthenticationContext
from velmios.core.types import AdminRole, CustomerRole, PublicUserRole, SystemRole


class MyServicePermissionsResolver(AbstractPermissionsResolverService):
    def resolve_admin_role(
        self, admin_role: AdminRole, authentication_context: AuthenticationContext
    ) -> list[Permission]:
        if admin_role == AdminRole.OPERATOR:
            return [
                Permission("my_service.users:read"),
                Permission("my_service.users:write"),
                Permission("my_service.users:operate"),
            ]
        return []

    def resolve_customer_role(
        self, customer_role: CustomerRole, authentication_context: AuthenticationContext
    ) -> list[Permission]:
        base = [Permission("my_service.users:read")]
        if customer_role in (CustomerRole.OWNER, CustomerRole.MANAGER):
            base.append(Permission("my_service.users:write"))
        return base

    def resolve_public_user_role(
        self, public_user_role: PublicUserRole, authentication_context: AuthenticationContext
    ) -> list[Permission]:
        if public_user_role == PublicUserRole.USER:
            return [Permission("my_service.users:read")]
        return []  # Guests get no permissions

    def resolve_system_role(
        self, system_role: SystemRole, authentication_context: AuthenticationContext
    ) -> list[Permission]:
        return [
            Permission("my_service.users:read"),
            Permission("my_service.users:write"),
        ]
```

### resolve() Method

The `resolve()` method dispatches to the appropriate role-specific method based on `authentication_context.persona`. You do NOT need to override it.

## AbstractDependsPermissionsRequired

Abstract base class for creating FastAPI dependencies that enforce permission requirements.

```python
class AbstractDependsPermissionsRequired(ABC):
    def __init__(
        self,
        required_permissions: list[Permission],
        permissions_resolver_service: AbstractPermissionsResolverService,
    ) -> None: ...

    def check(self, authentication_context: AuthenticationContext) -> None: ...
    def __call__(self, authentication_context: AuthenticationContext) -> AuthenticationContext: ...
```

### Implementation Example

```python
from fastapi import Depends
from velmios.core.services.permissions import AbstractDependsPermissionsRequired, Permission
from velmios.core.security import AuthenticationContext, depends_authentication_context


class DependsPermissionsRequired(AbstractDependsPermissionsRequired):
    def __init__(self, required_permissions: list[Permission]):
        super().__init__(
            required_permissions=required_permissions,
            permissions_resolver_service=MyServicePermissionsResolver(),
        )

    def __call__(
        self,
        authentication_context: AuthenticationContext = Depends(depends_authentication_context),
    ) -> AuthenticationContext:
        return super().__call__(authentication_context=authentication_context)


# Usage in endpoint
@app.get("/users")
async def list_users(
    auth: AuthenticationContext = Depends(
        DependsPermissionsRequired([Permission("my_service.users:read")])
    ),
) -> list:
    return []
```

### check() Method

The `check()` method:
1. Resolves the context permissions using the resolver service.
2. Verifies ALL required permissions are present in the resolved set.
3. Raises `PermissionsRequiredError` if any permission is missing.

## Error Types

### PermissionsRequiredError

Raised when the authentication context lacks required permissions.

```python
class PermissionsRequiredError(FastAPIFactoryUtilitiesError):
    def __init__(
        self,
        required_permissions: list[Permission],
        context_permissions: list[Permission],
        persona: AuthenticationPersona,
        realm_id: RealmId,
    ) -> None: ...
```

Contains diagnostic information: what was required, what was available, persona, and realm.

### PermissionsResolverError

Raised when permission resolution fails (e.g., missing entity, unknown persona).

## Best Practices

1. Create one `PermissionsResolverService` per microservice.
2. Follow the permission naming convention: `namespace.service.resource:action`.
3. Use `AbstractDependsPermissionsRequired` to create a reusable dependency class per service.
4. Catch `PermissionsRequiredError` in error handlers to return appropriate HTTP 403 responses.
5. The `authentication_context` parameter in resolver methods gives access to the full entity, allowing context-dependent permission logic (e.g., different permissions per realm).

## Reference

- `src/velmios/core/services/permissions.py`
