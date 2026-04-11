"""Quick start example for Velmios Core authentication and authorization."""

from http import HTTPStatus

from fastapi import Depends, FastAPI, HTTPException
from fastapi_factory_utilities.core.security.types import OAuth2Scope

from velmios.core.security import AuthenticationContext, AuthenticationType, DependsAuthenticationContext
from velmios.core.types import AuthenticationPersona

app = FastAPI()


@app.get("/my-resource")
async def get_my_resource(
    auth: AuthenticationContext = Depends(
        DependsAuthenticationContext(
            authorized_personas=[AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER],
        )
    ),
) -> dict:
    """Endpoint for Velmios admins and tenant customers (any supported JWT or session on the resolver)."""
    return {
        "realm_id": str(auth.realm_id),
        "persona": auth.persona,
    }


@app.post("/internal/sync")
async def sync_data(
    auth: AuthenticationContext = Depends(
        DependsAuthenticationContext(
            authorized_personas=[AuthenticationPersona.SYSTEM],
            supported_authentication_types=[AuthenticationType.HYDRA_INTERNAL_JWT],
        )
    ),
) -> dict:
    """Internal endpoint: internal JWT only, then enforce an OAuth2 scope on the context."""
    required_scope = OAuth2Scope("my_service.sync:execute")
    if required_scope not in auth.scopes:
        raise HTTPException(status_code=HTTPStatus.FORBIDDEN, detail="Missing required scope")
    return {"system_id": str(auth.system.id)}


@app.get("/me")
async def get_me(
    auth: AuthenticationContext = Depends(
        DependsAuthenticationContext(
            authorized_personas=[AuthenticationPersona.ADMIN, AuthenticationPersona.CUSTOMER],
            supported_authentication_types=[
                AuthenticationType.HYDRA_CUSTOMER_JWT,
                AuthenticationType.KRATOS_SESSION,
            ],
        )
    ),
) -> dict:
    """Customer JWT or Kratos session — not internal system JWT."""
    if auth.persona_is(AuthenticationPersona.ADMIN):
        admin = auth.admin
        return {"id": str(admin.id), "role": admin.role, "email": str(admin.email)}
    customer = auth.customer
    return {
        "id": str(customer.id),
        "role": customer.role,
        "realm_id": str(customer.realm_id),
    }
