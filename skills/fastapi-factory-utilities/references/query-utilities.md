# HTTP query utilities and API field markers

Typed parsing of query-string filters, sorting, and pagination for list/search endpoints, plus the unified `ApiField` markers that drive response, update, and search introspection. Package: `fastapi_factory_utilities.core.utils.api`.

## When to use

- Building `GET` search endpoints with optional filters, operators, and sort parameters.
- Deriving filter models from domain models with `SearchableEntity` and `SearchableField`.
- Translating parsed queries to MongoDB / Beanie `find` arguments via the ODM plugin.
- Combining response, update, and search behaviors on one model through the unified `ApiField` marker.

## Module layout (v3.x+)

Since v3.x / 4.4.4 the previously split `core.utils.api`, `core.utils.queries`, and `core.utils.paginations` are consolidated under `fastapi_factory_utilities.core.utils.api`. The old `queries` / `paginations` packages are **gone** — import pagination and query symbols only from `core.utils.api`. A single `ApiField` marker now drives behavior; convenience singletons remain for ergonomics:

- `ApiResponseField = ApiField()` — response-only.
- `UpdateableField = ApiField(updateable=True)` — response + PUT updateable.
- `SearchableField = ApiField(response=False, searchable=True)` — search-only.

Compose with `Annotated[T, ApiField(...), ApiField(...)]`; flags are OR-merged.

## Main exports

| Symbol | Role |
|---|---|
| `ApiField` | Unified marker carrying `response` / `updateable` / `searchable` flags. |
| `ApiResponseField`, `UpdateableField`, `SearchableField` | Convenience singletons. |
| `ApiResponseModelAbstract` | Abstract base producing dynamic response, PUT request, and reconciliation helpers (see [API response & update](api-response-and-update.md)). |
| `ApiResponseSchemaBase` | Pydantic v2 base class for generated response models (`extra="ignore"`). |
| `FieldChange`, `ReconcileResult` | Outputs from `reconcile_update_request`. |
| `SearchableEntity` | Base for filter generation from `ApiField(searchable=True)` markers. |
| `ApiEntityAbstract` | `SearchableEntity + ApiResponseModelAbstract` convenience base. |
| `QueryAbstract` | Root query model: pagination (`page`, `page_size`, computed `offset`), `sorts`, and filter fields. |
| `QueryFilterAbstract` | Backward-compatible alias for `QueryAbstract`. |
| `QueryFilterNestedAbstract` | Nested filter segment without pagination or sorts. |
| `QueryField`, `QueryFieldName`, `QueryFieldOperation`, `QuerySort`, `RawQueryFieldName`, `RawQuerySort` | Field operations and sort tokens. |
| `QueryFieldOperatorEnum`, `QuerySortDirectionEnum` | Operators and sort direction. |
| `QueryResolver` | Maps raw query parameters into a concrete `QueryAbstract` subclass. |
| `build_query_filter_kwargs` | Re-nests dotted `QueryResolver.fields` into kwargs for `model_construct` (FFU ≥ 5.18). |
| `PaginationPageOffset`, `PaginationSize`, `resolve_offset` | Pagination value objects and helper. |
| `FIELDS_QUERY_PARAM`, `parse_fields_param`, `project`, `fields_query_param` | Sparse fieldset projection for search/list responses (`?fields=`). |
| `has_response_flag`, `has_updateable_flag`, `has_searchable_flag` | Inspect `ApiField` metadata tuples. |

## URL parameter patterns

- Equality: `?field=value`
- Operators: `field[gt]`, `field[lt]`, `field[gte]`, `field[lte]`, `field[eq]`, `field[neq]`, `field[in]`, `field[nin]`, `field[contains]`, `field[not_contains]`, `field[starts_with]`, `field[ends_with]`.
- Nested / dotted keys: `?object1.field1=value1` (nested `BaseModel` fields on `QueryAbstract`, `Field(validation_alias=...)`, or `QueryResolver.add_authorized_field("object1.field1", ...)`).
- Sort: `?sort=name`, `?sort=-name&sort=+age`.
- Pagination: `?page=0&page_size=50` (defaults defined by `PaginationPageOffset` / `PaginationSize`).
- Sparse fieldsets (search/list endpoints only): `?fields=name,tasks[].name`, `?fields=name&fields=tasks[].name`.

## SearchableEntity pattern

```python
from typing import Annotated
from fastapi_factory_utilities.core.utils.api import ApiField, SearchableEntity


class Address(SearchableEntity):
    city: Annotated[str, ApiField(response=False, searchable=True)]


class User(SearchableEntity):
    name: Annotated[str, ApiField(response=False, searchable=True)]
    address: Annotated[Address, ApiField(response=False, searchable=True)]


class UserQueryFilter(User.build_query_filter_model()):
    """Concrete root filter (subclassing keeps a stable class name in OpenAPI)."""
```

- `build_query_filter_model()` returns a `QueryAbstract` subclass.
- `build_nested_query_filter_model(building=...)` returns a `QueryFilterNestedAbstract` segment used by nested entities; circular graphs raise a `ValueError`.
- Optional nested containers (`Annotated[Address | None, ApiField(searchable=True)] = None`) are preserved as optional in the generated filter.

## QueryResolver — query string to typed `QueryField`

```python
resolver = QueryResolver(raise_on_unauthorized_field=True)
resolver.from_model(UserQueryFilter)
resolver.resolve(request)

query = UserQueryFilter.model_construct(
    page=page,
    page_size=page_size,
    sorts=resolver.sorts,
    **{str(name): field for name, field in resolver.fields.items()},
)
```

Highlights:

- `from_model(cls)` registers authorized field paths by walking the filter model. Nested `BaseModel` fields, `validation_alias` (string or `AliasChoices`), and `populate_by_name=True` are all supported. Cycles are skipped.
- `add_authorized_field(QueryFieldName("foo.bar"), field_type=UUID)` registers ad-hoc dotted keys.
- `resolve(request)` parses query parameters in request order; duplicate keys for `in` / `nin` collect into lists, others keep the last value.
- Type coercion handled in `_coerce_scalar` / `_coerce_value`:
  - Builtins (`str`, `int`, `float`, `bool`).
  - `uuid.UUID`.
  - `typing.NewType` chains (e.g. Velmios `RealmId`).
  - `enum.Flag` / `IntFlag` accepting bitmask integers (`"3"`), name lookups (`"READ"`), or combined tokens (`"READ|WRITE"`, `"READ,WRITE"`, `"READ+WRITE"`).
  - `enum.Enum` / `StrEnum` accepting member name or value; `IntEnum` also coerces from base-10 strings.
  - Anything else: pydantic `TypeAdapter(field_type).validate_python(item)` as a fallback.
- `EXCLUDED_FIELDS = ["page", "page_size", "sort", "sorts"]` — these never become filters; pagination is parsed alongside query resolution.
- `raise_on_unauthorized_field=False` silently drops unknown fields/sort tokens instead of raising.

## QueryField and operations

`QueryField[T]` carries a list of `QueryFieldOperation(operator, value)` where `value` is `T` for scalar operators and `list[T]` for `in` / `nin`. Operators include `EQ`, `NEQ`, `GT`, `LT`, `GTE`, `LTE`, `IN`, `NIN`, `CONTAINS`, `NOT_CONTAINS`, `STARTS_WITH`, `ENDS_WITH`. Sorts (`QuerySort`) carry a direction (`ASC` / `DESC`).

## ODM translation

`fastapi_factory_utilities.core.plugins.odm_plugin.queries` provides `ODMQueryBuilder` / `ODMFindQuery` which translate a `QueryAbstract` instance into MongoDB match documents and Beanie `find` kwargs (operator merge rules, `id` → `_id`, regex options for string operators). See [ODM plugin](odm-plugin.md).

## Pagination

`PaginationPageOffset` and `PaginationSize` are value objects with sane defaults. `resolve_offset(page, page_size)` computes the row offset for repositories. Resource APIs that accept arbitrary query params should parse pagination separately (e.g. `_pagination_from_request_or_422` in Velmios `core.abstracts.api`) and return HTTP 422 on invalid `page` / `page_size`.

## Sparse fieldsets (`fields` param)

Search/list endpoints built on `QueryAbstract` / `QueryResolver` may accept an optional **`fields`** query parameter to reduce response payload size. This is **include-only**: only listed fields are returned, and **`id` is always kept** on each search result item. Single-item GET endpoints do not use this param.

Both URL forms are supported:

- Comma-separated: `?fields=name,tasks[].name`
- Repeated: `?fields=name&fields=tasks[].name`

The `[]` list notation is optional sugar (`tasks[].name` and `tasks.name` behave the same).

Projection runs **after** the response model strips internal/non-exposed fields, so it is purely subtractive and cannot leak hidden data.

```python
from fastapi import Depends
from starlette.responses import JSONResponse

from fastapi_factory_utilities.core.utils.api import fields_query_param, project

# Inside a search/list route (alongside QueryResolver wiring):
async def list_resources(
    request: Request,
    fields: list[str] = Depends(fields_query_param),
    # ... resolve QueryAbstract via QueryResolver ...
) -> ResourceListResponse | JSONResponse:
    items = [ResourceApi(**entity.model_dump()).model_dump(mode="json") for entity in entities]
    if fields:
        return JSONResponse({"items": project(items, fields), "size": len(items)})
    return ResourceListResponse(items=items, size=len(items))
```

Conflicting paths (e.g. `address` and `address.city` together) raise `ValueError` from `build_path_tree`; map that to HTTP 422/400 in the route or exception handler.

Unknown field paths are silently ignored in v1 (no schema validation against `get_exposed_fields()`).

## Breaking change in v5.0.0

`ApiEntityAbstract` (and any class that extends only `ApiResponseModelAbstract` + `SearchableEntity`) **no longer inherits `QueryAbstract`**. Entities are no longer accidentally pagination-aware; build the filter model explicitly via `Entity.build_query_filter_model()` and assign it to a named class for typing/OpenAPI.

## Nested sequence filters (FFU ≥ 5.18)

`SearchableEntity.build_query_filter_model()` descends into homogeneous sequences of nested models (`list[Address]`, etc.) via `nested_basemodel_for_annotation(..., descend_sequences=True)`. Query dotted paths can therefore target fields inside list elements.

When constructing a filter instance from `QueryResolver.fields`, use `build_query_filter_kwargs(FilterModel, resolver.fields)` before `FilterModel.model_construct(**kwargs)` — dotted keys must be re-nested or Pydantic silently drops them.

## Reference (source)

- `src/fastapi_factory_utilities/core/utils/api/__init__.py`
- `src/fastapi_factory_utilities/core/utils/api/markers.py`
- `src/fastapi_factory_utilities/core/utils/api/query_abstract.py`
- `src/fastapi_factory_utilities/core/utils/api/query_resolver.py`
- `src/fastapi_factory_utilities/core/utils/api/query_types.py`
- `src/fastapi_factory_utilities/core/utils/api/searchable_entity.py`
- `src/fastapi_factory_utilities/core/utils/api/pagination.py`
- `src/fastapi_factory_utilities/core/utils/api/projection.py`
- `src/fastapi_factory_utilities/core/utils/pydantic_path_fields.py`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/queries.py`
