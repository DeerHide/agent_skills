# HTTP query utilities

Typed parsing of query-string filters, sorting, and pagination for list/search endpoints. Package: `fastapi_factory_utilities.core.utils.queries`.

## When to use

- Building `GET` search endpoints with optional filters, operators, and sort parameters.
- Deriving filter models from domain models with `SearchableEntity` and `SearchableField`.
- Translating parsed queries to MongoDB/Beanie `find` arguments via the ODM plugin.

## Main exports

| Symbol | Role |
|--------|------|
| `QueryAbstract` | Root query model: pagination (`page`, `page_size`, computed `offset`), `sorts`, and filter fields. |
| `QueryFilterAbstract` | Alias for `QueryAbstract` (backward compatibility). |
| `QueryFilterNestedAbstract` | Nested filter segment without pagination or sorts. |
| `QueryField`, `QueryFieldName`, `QueryFieldOperation`, `QuerySort`, `RawQueryFieldName`, `RawQuerySort` | Field operations and sort tokens. |
| `QueryFieldOperatorEnum`, `QuerySortDirectionEnum` | Operators and sort direction. |
| `QueryResolver` | Maps raw query parameters into a concrete `QueryAbstract` subclass. |
| `SearchableEntity`, `SearchableField`, `SearchableMarker` | Mark searchable fields on a model; `build_query_filter_model()` returns a `QueryAbstract` subclass for filters. |

## URL parameter patterns

Typical patterns (see the library package `__init__.py` for the authoritative list):

- Equality: `?field=value`
- Nested or dotted field names: model nested `BaseModel` fields, `Field(validation_alias=...)`, or `QueryResolver.add_authorized_field`.
- Operators: `field[gt]`, `field[lt]`, `field[gte]`, `field[lte]`, `field[eq]`, `field[neq]`, `field[in]`, `field[nin]`, `field[contains]`, `field[not_contains]`, `field[starts_with]`, `field[ends_with]`.
- Sort: `?sort=name`, `?sort=-name&sort=+age`.

Pagination integrates with `core.utils.paginations`.

## SearchableEntity pattern

1. Subclass `SearchableEntity` and mark fields with `Annotated[..., SearchableField, ...]` (often combined with response metadata types in HTTP layers).
2. `YourEntity.build_query_filter_model()` yields a filter type subclassing `QueryAbstract` (you may subclass that type with `pass`).
3. Wire `QueryResolver` (or equivalent) so FastAPI resolves incoming query strings into that model.

Nested searchable entities become nested filter segments; optional nested containers are supported.

## ODM integration

`fastapi_factory_utilities.core.plugins.odm_plugin.queries` translates `QueryAbstract` into MongoDB match documents and Beanie `find` kwargs (operator merge rules, `id` → `_id`, regex options). Use alongside repositories or services that run Beanie queries.

## Reference (source)

- `src/fastapi_factory_utilities/core/utils/queries/`
- `src/fastapi_factory_utilities/core/plugins/odm_plugin/queries.py`
