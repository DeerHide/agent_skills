# Features and resource APIs

## When to use

- Exposing **realm-scoped feature flags** with search filters and PUT updates.
- Subclassing Velmios **abstract resource APIs** to ship realm-isolated read or CRUD HTTP surfaces.
- Declaring supported features and per-feature global overrides at application startup.

## Resource API bases

Velmios resource API classes live in `velmios.core.abstracts` and combine an `APIRouter` with a use-case layer.

| Class | Routes (default) |
|---|---|
| `RResourceAPIAbstract[Entity, Id, Item, ItemsModel, QueryFilter]` | `GET /{entity_id}`, `GET /` (search). Restrict via `api_read_operations`. |
| `CUDResourceAPIAbstract[Id, Create, Update, Item]` | `POST /` (create), `PUT /{entity_id}` (update), `DELETE /{entity_id}`. Restrict via `api_cud_operations`. |
| `CRUDResourceAPIAbstract[Entity, Id, Create, Update, Item, ItemsModel, QueryFilter]` | Read + CUD combined. |
| `ItemsModelAbstract[Item]` | Standard `{items, total, page, page_size}` envelope. |
| `ResourceApiReadOperations` / `ResourceApiCUDOperations` | `Flag` enums to opt out of routes. |

Each subclass declares **class-level callables** that FastAPI injects via `Depends`:

- `depends_authentication_context_search_permission`
- `depends_authentication_context_create_permission`
- `depends_authentication_context_update_permission`
- `depends_authentication_context_delete_permission`
- `depends_search_use_case`, `depends_create_use_case`, `depends_update_use_case`, `depends_delete_use_case`

Concrete services wire these to dependencies that return `AuthenticationContext` (typically `DependsAuthenticationContext(...)` or `AbstractDependsPermissionsRequired` subclasses) and instances of the relevant use-case abstracts.

### Resource API error mapping

The CUD endpoints already translate use-case errors to HTTP statuses (in `abstracts/api.py`):

| Use-case error class | HTTP |
|---|---|
| `USE_CASE_NOT_FOUND_ERROR` | **404** |
| `USE_CASE_NOT_ALLOWED_ERROR` | **403** |
| `USE_CASE_SEGMENTATION_ERROR` | **403** |
| `USE_CASE_ERROR` | **500** |

Invalid JSON bodies and invalid `page` / `page_size` query parameters return HTTP **422** with a structured `detail` array (`{"loc", "msg", "type", "field"}`). The `Location` header on `POST` is set to `"{collection_path}/{entity.id}"`; on `PUT` it is `"/{entity_id}"`. See [Use cases](use-cases.md) and [Exception handling](exception-handling.md).

### Realm-isolated entity contracts

Read and CUD endpoints accept any entity that satisfies the `RealmIsolatedEntity` / `RealmIsolatedPersistedEntity` contracts:

- `RealmIsolatedEntity` — adds `realm_id` (searchable).
- `RealmIsolatedPersistedEntity[Id]` — adds persistence (id, revision_id, timestamps) on top.
- `RealmIsolatedPersistedAuditableEntity[Id]` — auditable variant, required for `GenericAuditService`.
- `RealmIsolatedQueryFilterAbstract` + `add_realm_id_to_query_filters(...)` — automatically constrains list queries to the caller's realm unless `allow_cross_realm_when_velmios_admin_or_system` permits otherwise.

## Features API

`velmios.core.api.features.FeaturesAPI` is the canonical example. Since v12.3 it extends `CRUDResourceAPIAbstract` but only registers a partial set of routes:

```python
class FeaturesAPI(
    CRUDResourceAPIAbstract[
        FeaturesForRealmEntity,
        FeatureForRealmEntityId,
        BaseModel,                # unused create model
        FeaturesUpdateModel,
        FeaturesItem,
        FeaturesItems,
        FeaturesForRealmQueryFilter,
    ]
):
    api_read_operations = ResourceApiReadOperations.SEARCH | ResourceApiReadOperations.GET_BY_ID
    api_cud_operations = ResourceApiCUDOperations.UPDATE

    depends_authentication_context_search_permission: Callable[..., AuthenticationContext]
    depends_authentication_context_update_permission: Callable[..., AuthenticationContext]
    depends_search_use_case: Callable[..., FeaturesSearchUseCase]
    depends_update_use_case: Callable[..., FeaturesUpdateUseCase]
    depends_features_service: Callable[..., FeaturesService] = _depends_unconfigured
```

HTTP create and delete are intentionally unsupported (the create flow runs internally during realm seeding). The class also exposes a `depends_features_service` hook that the read/update endpoints use to enrich each `FeatureForRealmItem` with the code-declared `global_override`.

### Response and request models

```python
class FeatureForRealmItem(BaseModel):
    feature: Feature
    enabled: bool
    updated_at: datetime
    global_override: FeatureGlobalOverride = FeatureGlobalOverride.NONE


class FeaturesItem(BaseModel):
    id: FeatureForRealmEntityId | None = None
    realm_id: RealmId
    features: list[FeatureForRealmItem] = Field(default_factory=list)
    configuration_checksum: str


class FeaturesUpdateModel(BaseModel):
    model_config = ConfigDict(extra="forbid")
    features: list[FeatureForRealmEntity] = Field(min_length=1)
```

`serialize_features_item(entity, features_service)` builds `FeaturesItem` from the persisted entity and merges in the current `FeatureGlobalOverride` for each row.

### PUT semantics

`FeaturesAPI.update(...)`:

1. Parses the request body as `FeaturesUpdateModel` (HTTP 422 on JSON / validation errors).
2. Calls `FeaturesService.validate_features_update_payload(...)`:
   - Returns 422 when payloads contain `Missing required features: ...` or `Duplicate features: ...`.
   - Returns 403 (`FORBIDDEN`) when payloads contain unsupported feature keys.
3. Constructs a `FeaturesForRealmEntity` for the caller's realm, runs `FeaturesUpdateUseCase`, and maps errors to 404 / 403 / 500.
4. Sets a `Location: /{entity_id}` header on success and returns the enriched `FeaturesItem`.

### FeaturesUpdateUseCase

Extends `BasicUpdateUsecaseAbstract` (`velmios.core.usecases.generic.features.update`):

- `can_be_updated`: validates the payload through `FeaturesService.validate_features_update_payload` and rejects updates that touch globally forced features (`FeaturesService.is_globally_forced`).
- `pre_update_hook`: refreshes `updated_at` on every `FeatureForRealmEntity` before persistence.

Expose it through `depends_features_update_use_case` (default factory) or wire your own.

## Declaring supported features

`DependsFeaturesService` builds the `FeaturesService` from a single declaration call:

```python
from velmios.core.services.features.services import DependsFeaturesService, FeatureDeclaration
from velmios.core.types import Feature, FeatureGlobalOverride

features_dependency = DependsFeaturesService()
features_dependency.register_features([
    FeatureDeclaration(feature=Feature("billing:invoices"), default_enabled=True),
    FeatureDeclaration(
        feature=Feature("billing:legacy_export"),
        default_enabled=False,
        global_override=FeatureGlobalOverride.FORCE_DISABLED,
    ),
])
```

Behavior:

- `create_features_for_realm` seeds every registered feature with its declared default (fallback `False`).
- `realign_features_for_realm` adds missing supported flags, removes unsupported ones, and refreshes `configuration_checksum`.
- `is_enabled(realm_id, feature)` short-circuits to `True` / `False` for `FORCE_ENABLED` / `FORCE_DISABLED`; otherwise it reads the per-realm row.
- `validate_features_update_payload(...)` rejects duplicates, unsupported, or missing keys.
- `configuration_checksum` mixes supported features, defaults, and overrides so the realignment job picks up code changes.

Helpers `add_supported_feature(s)` and `add_default_feature(s)` remain for incremental wiring but `register_features([...])` is the recommended single-shot path.

## When to subclass which API

| Need | Use |
|---|---|
| Pure read API for an entity | `RResourceAPIAbstract` with a search-capable use case. |
| Full CRUD with create/update/delete + search | `CRUDResourceAPIAbstract` with all four use cases. |
| Partial CRUD (e.g. features) | `CRUDResourceAPIAbstract` + `api_read_operations` / `api_cud_operations` flags. |
| CUD endpoints without read | `CUDResourceAPIAbstract`. |

Pair each API with the matching service abstract from `velmios.core.abstracts.services` (`GenericService` for non-audited persistence; `GenericAuditService` for audit-enabled flows — see [Audit and events](audit-and-events.md)).

## Reference

- `src/velmios/core/abstracts/api.py`
- `src/velmios/core/api/features.py`
- `src/velmios/core/services/features/services.py`
- `src/velmios/core/usecases/generic/features/update.py`
- `src/velmios/core/usecases/generic/features/search.py`
