# Features and resource APIs

## When to use

- Exposing **realm-scoped feature flags** with search filters aligned to `fastapi-factory-utilities` **query utilities**.
- Subclassing Velmios **abstract resource API** types to add CRUD or read-only HTTP surfaces with consistent auth and use-case hooks.

## Features models (`velmios.core.entities.features`)

- **`FeatureForRealmEntity`** — `SearchableEntity` + response metadata; fields such as **`feature`**, **`enabled`**, **`updated_at`** participate in **`build_query_filter_model()`**.
- **`FeaturesForRealmEntity`** — `PersistedEntity[FeatureForRealmEntityId]` holding **`realm_id`**, list of **`FeatureForRealmEntity`**, and **`configuration_checksum`**.
- **`FeaturesForRealmQueryFilter`** — concrete query filter type from **`FeaturesForRealmEntity.build_query_filter_model()`**.

These types integrate **`SearchableField`** from `fastapi_factory_utilities.core.utils.queries` so ODM search can reuse the same filter shapes as HTTP (see [Query utilities](../../fastapi-factory-utilities/references/query-utilities.md)).

## Features HTTP API (`velmios.core.api.features`)

**`FeaturesAPI`** subclasses **`RResourceAPIAbstract`** with read/search operations only. Concrete apps must supply:

- **`depends_authentication_context_search_permission`** — callable used as FastAPI **`Depends`** for the search route (override on the subclass or via **`dependency_overrides`** in tests).

- **`depends_search_use_case`** — injects the **`FeaturesSearchUseCase`** implementation.

Response bundle types **`FeaturesItem`**, **`FeaturesItems`** are derived from **`build_response_model()`** on the entity.

## Abstract resource APIs (`velmios.core.abstracts`)

Key exports from **`velmios.core.abstracts`** include:

| Symbol | Role |
|---|---|
| **`RResourceAPIAbstract`** | Read/search HTTP API base |
| **`CRUDResourceAPIAbstract`**, **`CUDResourceAPIAbstract`** | Full or partial write APIs |
| **`ResourceApiReadOperations`**, **`ResourceApiCUDOperations`** | Declarative operation sets |
| **`RealmIsolatedEntity`**, **`RealmIsolatedPersistedEntity`** | Realm-scoped domain shapes |
| **`RealmIsolatedQueryFilterAbstract`**, **`add_realm_id_to_query_filters`** | Enforce tenant realm on queries |
| **`GenericService`**, **`ServiceAbstract`**, service search/CUD/get-by-id bases | Service layer patterns |
| **`SearchUseCaseAbstract`**, **`CreateUseCaseAbstract`**, … | Use case layer entry points |

Resource API classes declare **class-level** `depends_authentication_context_*_permission` callables for **search**, **create**, **update**, and **delete** so applications wire auth once per API surface.

## Where to read code

- `src/velmios/core/abstracts/api.py` — HTTP resource base classes and dependency hook contract.
- `src/velmios/core/api/features.py` — reference **`FeaturesAPI`** subclass pattern.
- `src/velmios/core/usecases/generic/features/search.py` — example search use case type referenced by **`FeaturesAPI`**.
