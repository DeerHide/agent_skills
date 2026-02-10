"""Quick start example for velmios_core authentication and authorization."""

import uuid

from fastapi import Depends, FastAPI

from velmios.core.security import (
    AuthenticationContext,
    AuthenticationPersona,
    DependsAuthorizedPersona,
    DependsSystemHasScope,
)
from velmios.core.types import RealmId

app = FastAPI()


# Endpoint restricted to admins and customers
@app.get("/my-resource")
async def get_my_resource(
    auth: AuthenticationContext = Depends(
        DependsAuthorizedPersona(
            [AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER]
        )
    ),
) -> dict:
    """Endpoint accessible only by admins and customers."""
    return {
        "realm_id": str(auth.realm_id),
        "persona": auth.persona,
    }


# Endpoint restricted to system-to-system calls with a specific scope
@app.post("/internal/sync")
async def sync_data(
    auth: AuthenticationContext = Depends(
        DependsSystemHasScope(required_scope="my_service.sync:execute")
    ),
) -> dict:
    """Internal endpoint requiring a specific OAuth2 scope."""
    return {"system_id": str(auth.system.id)}


# Using AuthenticationContext properties to access typed entities
@app.get("/me")
async def get_me(
    auth: AuthenticationContext = Depends(
        DependsAuthorizedPersona(
            [AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER]
        )
    ),
) -> dict:
    """Return current user info based on persona."""
    if auth.persona_is(AuthenticationPersona.ADMIN):
        admin = auth.admin
        return {"id": str(admin.id), "role": admin.role, "email": str(admin.email)}
    else:
        customer = auth.customer
        return {
            "id": str(customer.id),
            "role": customer.role,
            "realm_id": str(customer.realm_id),
        }
