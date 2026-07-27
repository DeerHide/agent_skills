# Hydra Service

OAuth2 and OpenID Connect operations against Ory Hydra: token introspection, JWKS fetching, and client credentials grants.

## When to use

- Validating OAuth2 access tokens via introspection.
- Populating a JWKS store with Hydra public keys.
- Implementing service-to-service authentication with the client credentials grant.
- Inspecting `ext` claims attached to tokens (Hydra-issued).

## HydraIntrospectGenericService

```python
class HydraIntrospectGenericService(Generic[HydraIntrospectGeneric]):
    def __init__(
        self,
        identifier: str,
        config: JWTBearerAuthenticationConfig,
        hydra_admin_http_resource: AioHttpClientResource,
        hydra_public_http_resource: AioHttpClientResource,
    ) -> None: ...

    def get_issuer(self) -> OAuth2Issuer: ...

    async def introspect(self, token: HydraAccessToken) -> HydraIntrospectGeneric: ...
    async def get_wellknown_jwks(self) -> list[PyJWK]: ...
```

`HydraIntrospectService = HydraIntrospectGenericService[HydraTokenIntrospectObject]` is the default specialization. Subclass it when you need typed access to additional fields under `ext`.

### Introspection

```python
service = HydraIntrospectService(
    identifier="hydra_internal",
    config=jwt_config,
    hydra_admin_http_resource=admin_client,
    hydra_public_http_resource=public_client,
)


introspect = await service.introspect(token=HydraAccessToken(token))

if not introspect.active:
    raise HydraTokenInvalidError("Token is not active")
```

The default `HydraTokenIntrospectObject` is now `SearchableEntity + ApiResponseModelAbstract` (every field is `ApiField(searchable=True)`), so introspection results can be exposed in dynamic API response models directly.

`ext` is typed as `dict[str, Any] | None` — since FFU v5.0.2 it accepts non-string nested values (lists, nested dicts) without rejecting the payload. This matches Velmios customer tokens where `ext` carries the discriminated lite-entity payload.

### JWKS

```python
from fastapi_factory_utilities.core.security.jwt import JWKStoreMemory

jwks = await service.get_wellknown_jwks()

store = JWKStoreMemory()
for jwk in jwks:
    await store.add_jwk(issuer=jwt_config.issuer, jwk=jwk)
```

Or use the convenience helper that wraps the same flow over multiple services:

```python
from fastapi_factory_utilities.core.security.jwt import (
    configure_jwks_in_memory_store_from_hydra_introspect_services,
)


store = await configure_jwks_in_memory_store_from_hydra_introspect_services(
    introspect_service_list=[internal_service, customer_service],
)
```

Velmios `configure_velmios_jwks_store_memory` performs this under the hood when the application enables the in-memory JWKS store.

## HydraOAuth2ClientCredentialsService

OAuth2 client credentials grant.

```python
from fastapi_factory_utilities.core.services.hydra import (
    HydraOAuth2ClientCredentialsService,
    HydraClientId,
    HydraClientSecret,
)


service = HydraOAuth2ClientCredentialsService(
    identifier="hydra_client_credentials",
    hydra_public_http_resource=public_client,
    application_config=app_config,
)


token = await service.oauth2_client_credentials(
    client_id=HydraClientId("internal-worker"),
    client_secret=HydraClientSecret("..."),
    scopes=["api:read", "api:write"],
    audience="velmios-internal",
)
```

`application_config` carries the default audience and timeouts. The service reuses the public HTTP resource so connection pooling is shared with the rest of the application.

## DTOs

```python
class HydraTokenIntrospectObject(SearchableEntity, ApiResponseModelAbstract, BaseModel):
    model_config = ConfigDict(extra="ignore")

    active: Annotated[bool, ApiField(searchable=True)]
    aud: Annotated[list[str], ApiField(searchable=True)]
    client_id: Annotated[str, ApiField(searchable=True)]
    exp: Annotated[int, ApiField(searchable=True)]
    ext: Annotated[dict[str, Any] | None, ApiField(searchable=True)] = None
    iat: Annotated[int, ApiField(searchable=True)]
    iss: Annotated[str, ApiField(searchable=True)]
    nbf: Annotated[int, ApiField(searchable=True)]
    obfuscated_subject: Annotated[str | None, ApiField(searchable=True)] = None
    scope: Annotated[str, ApiField(searchable=True)]
    sub: Annotated[str, ApiField(searchable=True)]
    token_type: Annotated[str, ApiField(searchable=True)]
    token_use: Annotated[str, ApiField(searchable=True)]
    username: Annotated[str | None, ApiField(searchable=True)] = None
```

The introspection payload is parsed once and shared between every consumer (no double-parsing for downstream verifiers); this happens before payload validation so additional checks (audience match, custom claims) read the same dict.

## Errors

```python
from fastapi_factory_utilities.core.services.hydra.exceptions import (
    HydraOperationError,
    HydraTokenInvalidError,
)


try:
    introspect = await service.introspect(token)
except HydraTokenInvalidError:
    raise HTTPException(status_code=403, detail="Invalid token")
except HydraOperationError as exc:
    logger.error("Hydra operation failed", error=exc, status_code=exc.status_code)
    raise
```

## Integration with AioHttp

Both services accept `AioHttpClientResource` instances. Configure the plugin with the right keys (typically `hydra_internal_public`, `hydra_internal_admin`, `hydra_customer_public`, `hydra_customer_admin` for Velmios services) and inject them via `AioHttpResourceDepends`.

## Best practices

1. Always check `introspect.active` before trusting any other field; Hydra returns the token's metadata even when it is expired or revoked.
2. Reuse one JWKS store across internal and customer stacks; both Hydra deployments contribute their public keys.
3. Validate the introspected audience matches your service before granting access; the discriminator should never rely on the client alone.
4. Wire `HydraOAuth2ClientCredentialsService` with the public Hydra endpoint of the upstream cluster (not the admin endpoint) to keep credentials surface area minimal.

## Reference

- `src/fastapi_factory_utilities/core/services/hydra/services.py`
- `src/fastapi_factory_utilities/core/services/hydra/objects.py`
- `src/fastapi_factory_utilities/core/services/hydra/exceptions.py`
- See also: [JWT authentication](jwt-authentication.md), [AioHttp HTTP client](aiohttp.md), Velmios JWT authentication (`velmios-lib` in laelidona/velmios-skills).
