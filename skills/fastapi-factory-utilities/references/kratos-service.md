# Kratos Service

Identity management and session validation against Ory Kratos.

## When to use

- Validating user sessions from cookies (`KratosGenericWhoamiService`).
- Reading, patching, or deleting identities and credentials.
- Managing identity sessions: listing, deleting a single session, deleting all sessions for an identity.
- Generating recovery codes and links for self-service flows.

## KratosGenericWhoamiService

```python
class KratosGenericWhoamiService(Generic[GenericKratosSessionObject]):
    COOKIE_NAME: str = "ory_kratos_session"

    def __init__(self, kratos_public_http_resource: AioHttpClientResource) -> None: ...

    async def whoami(self, cookie_value: str) -> GenericKratosSessionObject: ...
```

The concrete session class is read from `__orig_bases__`, so subclass with your typed session object (Velmios `VelmiosKratosSessionObject`).

```python
class CustomWhoami(KratosGenericWhoamiService[CustomSessionObject]):
    """Service for the public Kratos API."""


service = CustomWhoami(kratos_public_http_resource=public_client)
session = await service.whoami(cookie_value="<ory_kratos_session cookie>")
```

Errors:

- HTTP 401 → `KratosSessionInvalidError`
- HTTP 5xx / other → `KratosOperationError`
- Pydantic validation failure → `KratosOperationError`

## KratosIdentityGenericService

Type-safe admin client for `/admin/identities` and `/admin/sessions`.

```python
class KratosIdentityGenericService(Generic[GenericKratosIdentityObject, GenericKratosSessionObject]):
    IDENTITY_ENDPOINT: str = "/admin/identities"
    ADMIN_ENDPOINT: str = "/admin"

    def __init__(self, kratos_admin_http_resource: AioHttpClientResource) -> None: ...
```

The class infers both the identity and session DTO classes from `__orig_bases__`. Velmios subclasses are `VelmiosKratosIdentityService[VelmiosKratosIdentityObject, VelmiosKratosSessionObject]`.

### Available operations

| Method | Endpoint | Purpose |
|---|---|---|
| `get_identity(identity_id)` | `GET /admin/identities/{id}` | Fetch a single identity. |
| `update_identity(identity_id, patches)` | `PATCH /admin/identities/{id}` | JSON Patch the identity (use `KratosIdentityPatchObject`). |
| `delete_identity(identity_id)` | `DELETE /admin/identities/{id}` | Delete an identity. |
| `delete_identity_credentials(identity_id, credentials_type, identifier=None)` | `DELETE /admin/identities/{id}/credentials` | Delete password / TOTP / WebAuthn credentials; `identifier` is required for `OIDC` and `SAML`. |
| `delete_identity_sessions(identity_id)` | `DELETE /admin/identities/{id}/sessions` | Invalidate every active session of the identity. |
| `delete_session(session_id)` | `DELETE /admin/sessions/{session_id}` | Invalidate a single session (added in FFU v5.1.0). Use this when you need surgical session revocation (e.g. logout from a specific device). |
| `list_sessions(identity_id, active=True, page_size=250, page_token=None)` | `GET /admin/identities/{id}/sessions` | Paginated session listing; returns `(sessions, next_page_token)`. |
| `create_recovery_code(identity_id, flow_type, expires_in)` | `POST /admin/recovery/code` | Generate a recovery code. |
| `create_recovery_link(identity_id, expires_in)` | `POST /admin/recovery/link` | Generate a recovery link. |
| `create_identity(identity)` | n/a | Currently `NotImplementedError` — override per service. |

### Patch identity example

```python
from fastapi_factory_utilities.core.services.kratos import (
    KratosIdentityPatchObject,
    KratosIdentityPatchOpEnum,
)

patches = [
    KratosIdentityPatchObject(op=KratosIdentityPatchOpEnum.REPLACE, path="/traits/email", value="new@example.com"),
]

updated = await service.update_identity(identity_id=identity_id, patches=patches)
```

## DTOs

```python
class KratosIdentityObject(BaseModel, Generic[Traits, MetadataPublic, MetadataAdmin]):
    id: KratosIdentityId
    state: KratosIdentityStateEnum
    state_changed_at: datetime.datetime
    traits: Traits
    metadata_public: MetadataPublic | None = None
    metadata_admin: MetadataAdmin | None = None
    created_at: datetime.datetime
    updated_at: datetime.datetime
    schema_id: KratosSchemaId
    schema_url: str
    ...


class KratosSessionObject(BaseModel, Generic[Identity]):
    id: UUID
    active: bool
    authenticated_at: datetime.datetime
    expires_at: datetime.datetime
    identity: Identity
    ...
```

Since v3.x the identity / session DTOs mix in `SearchableEntity` and `ApiResponseModelAbstract`, so admin-side projections can be exposed in dynamic response models via `ApiField`. Use generic parameters to plug in service-specific traits and metadata.

### Enums

- `KratosIdentityStateEnum`: `ACTIVE`, `INACTIVE`.
- `KratosIdentityPatchOpEnum`: standard JSON Patch operations (`ADD`, `REPLACE`, `REMOVE`, ...).
- `AuthenticationMethodEnum`: `PASSWORD`, `OIDC`, `TOTP`, `WEBAUTHN`, `SAML`, `LOOKUP_SECRET`, `CODE`.

## Errors

```python
from fastapi_factory_utilities.core.services.kratos.exceptions import (
    KratosOperationError,
    KratosIdentityNotFoundError,
    KratosSessionInvalidError,
)
```

`KratosOperationError` carries the upstream HTTP `status_code` and structured kwargs (e.g. `identity_id`, `patches`) so handlers can rebuild error context.

## FastAPI integration

```python
@router.get("/me")
async def me(
    request: Request,
    whoami: VelmiosKratosWhoamiService = Depends(depends_velmios_kratos_whoami_service),
):
    cookie = request.cookies.get("ory_kratos_session")
    if not cookie:
        raise HTTPException(status_code=401, detail="No session cookie")
    try:
        session = await whoami.whoami(cookie)
    except KratosSessionInvalidError as exc:
        raise HTTPException(status_code=401, detail="Invalid session") from exc
    return {"identity_id": str(session.identity.id)}
```

## Best practices

1. Always parameterize `KratosIdentityGenericService` and `KratosGenericWhoamiService` with concrete DTOs that document your service's traits / metadata schema.
2. Use `delete_session(session_id)` for granular logout flows; reserve `delete_identity_sessions` for full invalidation.
3. Surface `KratosSessionInvalidError` as HTTP 401; let the Velmios security handler add telemetry around it (see Velmios Exception handling (`velmios-lib` in laelidona/velmios-skills)).
4. Pair `update_identity` with optimistic concurrency in your service if you serve concurrent admin clients.

## Reference

- `src/fastapi_factory_utilities/core/services/kratos/services.py`
- `src/fastapi_factory_utilities/core/services/kratos/objects.py`
- `src/fastapi_factory_utilities/core/services/kratos/enums.py`
- `src/fastapi_factory_utilities/core/services/kratos/exceptions.py`
- See also: [JWT Authentication](jwt-authentication.md), Velmios Kratos authentication (`velmios-lib` in laelidona/velmios-skills).
