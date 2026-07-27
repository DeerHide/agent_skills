# API response and PUT update model

Dynamic API response models, PUT request models, and reconciliation utilities driven by the unified `ApiField` marker. Package: `fastapi_factory_utilities.core.utils.api`.

## When to use

- Generating a dedicated response schema from a domain entity.
- Generating a PUT request schema that exposes only the client-writable fields.
- Reconciling a PUT payload against a stored entity (whitelist of `UpdateableField` paths).
- Surfacing structured field-level diffs for audit metadata.

## Core abstractions

```python
from fastapi_factory_utilities.core.utils.api import (
    ApiEntityAbstract,
    ApiField,
    ApiResponseField,
    ApiResponseModelAbstract,
    ApiResponseSchemaBase,
    FieldChange,
    ReconcileResult,
    SearchableField,
    UpdateableField,
)
```

`ApiField` carries three independent boolean flags:

- `response` — field is exposed in dynamic API response schemas.
- `updateable` — field is part of the PUT request model and the reconciliation whitelist.
- `searchable` — field is exposed as a query filter on dynamic search models (see [query utilities](query-utilities.md)).

Convenience singletons:

- `ApiResponseField = ApiField()` — response-only.
- `UpdateableField = ApiField(updateable=True)` — response + updateable.
- `SearchableField = ApiField(response=False, searchable=True)` — search-only.

Stack markers in `Annotated`: `Annotated[str, ApiField(searchable=True), UpdateableField]` exposes the field in the response, makes it updateable, and includes it in the dynamic search filter.

## ApiResponseModelAbstract

```python
class Product(ApiResponseModelAbstract):
    id: Annotated[int, ApiField()]
    label: Annotated[str, UpdateableField] = "default"
    internal_note: str = "secret"
```

Class methods:

- `build_response_model() -> type[ApiResponseSchemaBase]` — generate a Pydantic model containing only the response-flagged fields. The generated class can be subclassed (e.g. to add `request_id`).
- `build_update_request_model() -> type[ApiResponseSchemaBase]` — generate the PUT body model. Every response-flagged field becomes required to enforce explicit PUT semantics; nested `ApiResponseModelAbstract` fields recurse into their own update models.
- `get_exposed_fields() -> list[str]` — flat list of response-flagged dotted paths.
- `get_updateable_fields() -> list[str]` — flat list of `updateable` dotted paths. Nested `ApiResponseModelAbstract` fields marked only with a response-flag are still walked so that updateable leaves inside them are returned.

## ApiEntityAbstract

`ApiEntityAbstract = SearchableEntity + ApiResponseModelAbstract`. Use this base for any entity that doubles as a response model and a query filter source (Velmios `RealmIsolatedEntity` does exactly this). Since v5.0.0 it **no longer inherits `QueryAbstract`** — derive the filter explicitly via `Entity.build_query_filter_model()`.

## FieldChange & ReconcileResult

```python
@dataclass(frozen=True, slots=True)
class FieldChange:
    path: str
    old_value: Any
    new_value: Any
    kind: Literal["updated", "added", "removed"]


@dataclass(frozen=True, slots=True)
class ReconcileResult(Generic[GenericModel]):
    entity_updated: GenericModel
    changed: list[FieldChange]
    ignored_paths: list[str]
    unchanged_paths: list[str]
```

- `entity_updated` — original entity merged with the whitelisted PUT payload.
- `changed` — per-path diff (path, before, after, kind).
- `ignored_paths` — PUT payload paths discarded because they were not `UpdateableField`.
- `unchanged_paths` — updateable paths submitted with the same value as the original.

## reconcile_update_request

```python
class ApiResponseModelAbstract(BaseModel):
    @classmethod
    def reconcile_update_request(
        cls,
        *,
        entity_original: GenericModel,
        put_request: BaseModel,
        strict: bool = False,
    ) -> ReconcileResult[GenericModel]: ...
```

Behavior:

1. Compute the `updateable_paths` set from `cls.get_updateable_fields()`.
2. Dump the original entity and the PUT request to dicts; flatten the request to dotted paths.
3. For each request path:
   - If not in `updateable_paths`, append to `ignored_paths` (the value is dropped).
   - Else, if it equals the original value, append to `unchanged_paths`.
   - Else, write the new value into `merged_data` by path and record a `FieldChange` (`kind=added` when the old value was `None`, `removed` when the new value is `None`, otherwise `updated`).
4. If `strict=True` and `ignored_paths` is non-empty, raise `ValueError("PUT payload includes non-updateable fields: ...")`.
5. Re-validate the merged dict through the entity's `model_validate` so type/realm validators run again.
6. Return `ReconcileResult(entity_updated, changed, ignored_paths, unchanged_paths)`.

## Integration with use cases

The reconciliation engine is wired into the Velmios `UpdateUseCaseAbstract.execute()` flow (see Velmios Use cases (`velmios-lib` in laelidona/velmios-skills)):

- The use case calls `type(entity_original).reconcile_update_request(...)` with `strict=False`.
- It surfaces `update_diff`, `ignored_update_paths`, and `unchanged_update_paths` as properties.
- `build_audit_metadata()` serializes `update_diff` (using `dataclasses.asdict`) into `metadata["changed"]` for audit consumers.

Velmios `FeatureForRealmEntity` / `FeaturesForRealmEntity` mark their settable fields with `UpdateableField` so PUT requests can only touch the `features` collection (each feature's `feature` and `enabled` keys), not the entity id or checksum.

## Strict mode

`strict=True` is useful for endpoints that explicitly reject extraneous fields (e.g. internal admin tools where the client should not be sending unsupported keys). Most public PUT endpoints stick with `strict=False` so older clients keep working when new fields appear.

## Example end-to-end

```python
from typing import Annotated
from fastapi_factory_utilities.core.plugins.odm_plugin import PersistedEntity
from fastapi_factory_utilities.core.utils.api import ApiField, UpdateableField


class UserEntity(PersistedEntity[UserEntityId]):
    email: Annotated[Email, ApiField(searchable=True), UpdateableField]
    realm_id: Annotated[RealmId, ApiField(searchable=True)]
    is_admin: Annotated[bool, ApiField(searchable=True)]


UserApiResponse = UserEntity.build_response_model()
UserPutRequest = UserEntity.build_update_request_model()


put_request = UserPutRequest.model_validate({"email": "user@example.com", "realm_id": "...", "is_admin": True})
result = UserEntity.reconcile_update_request(entity_original=user, put_request=put_request)


# result.changed  -> [{"path": "email", ...}]  if email actually changed
# result.ignored_paths  -> ["realm_id", "is_admin"]  (not updateable)
# result.unchanged_paths -> []
# result.entity_updated -> UserEntity with email replaced
```

## Best practices

1. Mark only client-writable fields with `UpdateableField`. Everything else stays response-only and never appears in PUT bodies.
2. Use `strict=True` for internal admin endpoints where unexpected payloads should be a hard error.
3. Subclass the generated response model (`UserApiResponse`) when an endpoint needs additional response fields (e.g. `request_id`).
4. Forward `result.changed` to the audit pipeline via `build_audit_metadata()` so consumers can rebuild the exact diff.
5. When nesting domain models, ensure nested types also inherit `ApiResponseModelAbstract`; mixing in plain `BaseModel` raises a clear `ValueError` at build time.

## Reference

- `src/fastapi_factory_utilities/core/utils/api/response_model.py`
- `src/fastapi_factory_utilities/core/utils/api/markers.py`
- `src/fastapi_factory_utilities/core/utils/api/searchable_entity.py`
- See also: [Query utilities](query-utilities.md), [ODM plugin](odm-plugin.md), Velmios Use cases (`velmios-lib` in laelidona/velmios-skills).
