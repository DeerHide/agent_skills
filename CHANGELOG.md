# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **fastapi-factory-utilities** skill: align with library **v7.2.x** (skill metadata **2.3.0**).
  - **AioPika**: `precheck` returns `MessageDeliveryOutcome`; poison is `requeue=False`; document `PREFETCH_COUNT` and `on_gate_saturated`.
  - **JWT**: `authorized_audiences` required; introspect cache keyed by issuer + NUL + `jti`, hits re-check `exp`.
  - **Audit**: default `pre_publish_hook` runs `redact(entity)`; mark PII with `Redacted()`.
  - **Config**: deny-by-default CORS, `docs.enabled`, URL-only Redis/AMQP credentials.
  - **Taskiq**: cron single-flight lock, `ensure_cron_schedule`, stream `maxlen=10_000`.
  - **RedisPlugin**, ODM CSFLE, and `PluginStatusMixin` documented.

- **commit** skill: Phase 3 now **MUST** run `pre-commit install` (pre-commit +
  commit-msg, and pre-push when configured) and verify `.git/hooks` before any
  commit; new Phase 6 gates push with re-install + optional
  `pre-commit run --all-files`. Stops assuming a present config means hooks
  are wired (common cause of CI commitlint failures).

## [2.0.2] - 2026-07-29

### Added

- **fastapi-factory-utilities** skill: [S3 plugin](skills/fastapi-factory-utilities/references/s3-plugin.md)
  reference for async MinIO / S3 via aioboto3 — multi-bucket YAML,
  `S3BucketDepends`, shared `depends_s3_client` (skill metadata **2.2.0**).

### Changed

- **fastapi-factory-utilities** skill: align content with library **v5.18.x** (skill metadata **2.1.0**).
  - **CSRF / validation**: rewrite `configure_csrf()` as zero-arg from `config.csrf` / `AppCsrfConfig`; remove false claim that `register_exception_handlers` runs in `__init__` (must call from `configure()`).
  - **Pagination**: retarget imports from deleted `core.utils.paginations` to `core.utils.api`; drop "legacy re-export" claim in query-utilities.
  - **Quick start**: wire `get_default_plugins` via builder `__init__` (base builder never calls it).
  - **ASGI**: document Granian (`build_as_granian_utils`, `ServerImplementationEnum.GRANIAN`).
  - **AioPika**: document `AbstractManagedListener`, concurrency gates, delay-retry helpers, `MessageDeliveryOutcome`.
  - **Taskiq**: document Redis key prefixes (`{name_suffix}:taskiq:…`, 5.15 BREAKING), `prune_unregistered_schedules`, heartbeat auto-schedule removal.
  - **JWT**: document introspect cache fields (`cache_enabled` / TTL / max entries, 5.9).
  - **Logging**: document OTel `trace_id`/`span_id` injection (5.17) and `ProbeAccessLogFilter` (5.10).
  - **Query utilities**: document nested sequence filters and `build_query_filter_kwargs` (5.18).
- **python** skill: `PluginAbstract` snippet uses `on_load` / `on_startup` / `on_shutdown` (was stale `setup` / `shutdown`).

### Removed

- **velmios-lib** skill: migrated to [laelidona/velmios-skills](https://github.com/laelidona/velmios-skills) (`velmios-lib/`). Install and maintain that skill from the Velmios skills repo going forward.

## [2.0.1] - 2026-06-20

### Added

- **fastapi-factory-utilities** skill: sparse fieldsets (`fields` query param) for search/list endpoints — `parse_fields_param`, `project`, `fields_query_param`, include-only projection with always-kept `id`, and `tasks[].name` list notation.

## [2.0.0] - 2026-05-20

### Added

- **fastapi-factory-utilities** skill: [API response and PUT update model](skills/fastapi-factory-utilities/references/api-response-and-update.md) reference covering `ApiField`, `ApiResponseModelAbstract`, `ApiEntityAbstract`, `UpdateableField`, `build_response_model`, `build_update_request_model`, `get_updateable_fields`, and `reconcile_update_request` (`FieldChange` / `ReconcileResult`).
- **fastapi-factory-utilities** skill: [CSRF and validation handlers](skills/fastapi-factory-utilities/references/csrf-and-validation.md) reference covering `register_exception_handlers`, `register_csrf_protect_exception_handler`, `DependsCsrfProtect`, and how Velmios layers `register_security_exception_handlers` on top.
- **velmios-lib** skill: [Use cases](skills/velmios-lib/references/use-cases.md) reference covering `UseCaseAbstract`, `AuthenticatedUseCaseAbstract`, `allow_cross_realm_when_velmios_admin_or_system`, `CreateUseCaseAbstract`, `UpdateUseCaseAbstract`, `DeleteUseCaseAbstract`, `SearchUseCaseAbstract`, lifecycle hooks (`pre_create_hook`, `post_create_hook`, `can_be_created`, `pre_update_hook`, ...), `BasicCreateUsecaseAbstract` / `BasicUpdateUsecaseAbstract`, and segmentation errors.
- **velmios-lib** skill: [Audit and events](skills/velmios-lib/references/audit-and-events.md) reference covering `GenericService`, `GenericAuditService`, `RealmIsolatedAuditEvent`, `RealmIsolatedPersistedAuditableEntity`, `realm_id` / `UseCaseName` / `metadata` propagation, `changed` diff metadata via `build_audit_metadata`, and error mapping to `AuditServiceError`.
- **velmios-lib** skill: [Application scaffolding](skills/velmios-lib/references/application.md) reference covering `VelmiosApplicationAbstract`, `VelmiosApplicationBuilderAbstract`, default plugins (OpenTelemetry / AioHttp / ODM), dual JWT config wiring, `configure_jwks_store_memory`, `velmios_configure` (CSRF + validation + security handlers), `VelmiosRootConfig`, `VelmiosInformationConfig`, `depends_self_url`, and the auto-redirect middleware.
- **velmios-lib** skill: [Exception handling](skills/velmios-lib/references/exception-handling.md) reference covering `register_security_exception_handlers`, `HTTPExceptionDetailEnricher`, the `velmios.security.auth_failures` OpenTelemetry counter, span attributes, and how `PermissionsRequiredError`, `VelmiosNotAuthenticatedError`, `VelmiosSecurityError`, and request validation map to 401 / 403 / 422.

### Changed

- **fastapi-factory-utilities** skill: `metadata.version` bumped to **2.0.0**. Description expanded to call out typed PUT updates, optional Hypercorn ASGI server, and CSRF & validation handlers. "When to use" bullets added for `ApiEntityAbstract`, `UpdateableField` / PUT reconciliation, `register_exception_handlers` / CSRF, and Hypercorn.
- **fastapi-factory-utilities** skill: [Query utilities](skills/fastapi-factory-utilities/references/query-utilities.md) reference rewritten around the `core.utils.api` re-org — `ApiEntityAbstract`, `SearchableField`, `QueryFilterNestedAbstract`, dotted nested paths, `QueryResolver.from_model` with `validation_alias` / `AliasChoices`, type coercion for `UUID`, `NewType`, `Enum`, `Flag`, `StrEnum`, and list values for `in` / `nin`. Documents the v5.0 breaking change (API entities no longer inherit `QueryAbstract`).
- **fastapi-factory-utilities** skill: [ODM plugin](skills/fastapi-factory-utilities/references/odm-plugin.md) reference updated to cover generic `PersistedEntity[Id]` mixing in `SearchableEntity` + `ApiResponseModelAbstract`, `id` → `_id` mapping, `ODMQueryBuilder` / `ODMFindQuery` operator merging, and updated repository wiring.
- **fastapi-factory-utilities** skill: [Audit service](skills/fastapi-factory-utilities/references/audit-service.md) reference updated for `UseCaseName`, `AuditEventObject` fields, `AuditableEntity` / `PersistedAuditableEntity`, `AbstractAuditPublisherService.publish` + `pre_publish_hook`, routing-key pattern `{prefix}.{domain}.{service}.{what}.{why}`, and `AuditServiceError` payload (`audit_event`, `routing_key`).
- **fastapi-factory-utilities** skill: [Repository pattern](skills/fastapi-factory-utilities/references/repository-pattern.md) reference updated to document the `PersistedAuditableEntity` flow and `AbstractRepositoryInMemory` support for auditable bounded types.
- **fastapi-factory-utilities** skill: [Application framework](skills/fastapi-factory-utilities/references/application-framework.md) reference updated for `build_as_uvicorn_utils` / `build_as_hypercorn_utils` / `build_and_serve` kwargs forwarding, optional Hypercorn ASGI server (`core.utils.hypercorn`), `register_exception_handlers(app)`, and `register_csrf_protect_exception_handler(app)`.
- **fastapi-factory-utilities** skill: [JWT authentication](skills/fastapi-factory-utilities/references/jwt-authentication.md) reference updated to move `audience` to `JWTBearerAuthenticationConfig`, document `ExpiredJWTError`, configurable bearer extraction strategies (header / cookie), invalid-token → 403, and debug-level logging for invalid-credential flows.
- **fastapi-factory-utilities** skill: [Kratos service](skills/fastapi-factory-utilities/references/kratos-service.md) reference updated for admin `delete_session(session_id)` and identity DTOs mixing `SearchableEntity` + `ApiResponseModelAbstract`.
- **fastapi-factory-utilities** skill: [AioPika](skills/fastapi-factory-utilities/references/aiopika.md) reference updated for validated `PartStr` / `AbstractName` / `RoutingKey` / `QueueName` / `ExchangeName` types, fluent builders, listener wildcard support, `AbstractListener` exclusivity override, UTF-8 JSON decoding behavior, and `connect_robust` failure wrapping.
- **fastapi-factory-utilities** skill: [Hydra service](skills/fastapi-factory-utilities/references/hydra-service.md) reference updated for `HydraTokenIntrospectObject` mixing `SearchableEntity` + `ApiResponseModelAbstract`, `ext` claim flexibility (non-string nested values), and shared parsed payload before validation.
- **velmios-lib** skill: `metadata.version` bumped to **2.0.0**. Description refreshed to highlight use-case abstracts, composable permissions, and centralized security exception handling. "When to use" bullets expanded for `PARTIAL` persona, lite entities, resource APIs, use-case abstracts, feature flags, realm-aware audit events, application scaffolding, and realm boundary rules.
- **velmios-lib** skill: [Entities](skills/velmios-lib/references/entities.md) reference rewritten to remove the non-lite `AdminEntity` / `CustomerEntity` (gone since v12.0.0) and document `AdminLiteEntity` / `CustomerLiteEntity` built on `AuthenticatedUserLiteEntityAbstract` with `ApiEntityAbstract`, `identity_id`, `email` (computed `username` on admin), realm validators, and `PublicUserEntity` GUEST-by-default behavior.
- **velmios-lib** skill: [Permissions](skills/velmios-lib/references/permissions.md) reference redone around `PermissionRequirement` (`PermissionLeaf`, `AndRequirement`, `OrRequirement`, `ContextPredicateRequirement`, `AlwaysAllowedRequirement`, `predicate()`); `Permission` is no longer a `str` subclass; `AbstractDependsPermissionsRequired` accepts either `required_permissions` or `required_requirement`.
- **velmios-lib** skill: [Authentication](skills/velmios-lib/references/authentication.md) reference updated with `PARTIAL` persona, `identity_id`, `is_velmios_admin_or_system()`, `register_security_exception_handlers` + `HTTPExceptionDetailEnricher`, parallel-asyncio resolver flow, and the 422 validation envelope.
- **velmios-lib** skill: [Authorization dependencies](skills/velmios-lib/references/authorization-dependencies.md) reference updated to add `DependsAuthenticationContextWithKratosSessionSupport`, document 401 / 403 telemetry, and remove leftover references to `DependsAuthorizedPersona` / `DependsSystemHasScope`.
- **velmios-lib** skill: [Kratos authentication](skills/velmios-lib/references/kratos-authentication.md) reference rewritten with `metadata_public` (with `metadata_admin` fallback), optional `realm_id` during OIDC, optional `hd`, relaxed admin trait requirements, removed `VelmiosKratosIdentitySchemaId`, and the surfacing of identity ids on `AuthenticationContext.identity_id`.
- **velmios-lib** skill: [JWT authentication](skills/velmios-lib/references/jwt-authentication.md) reference updated for Hydra `ext` accepting non-string nested claims and dual stack wiring via `JWTBearerAuthenticationConfigBuilder(key="internal"|"customer")` + `DependsJWTBearerAuthenticationConfig.import_to_state`.
- **velmios-lib** skill: [Features and resource APIs](skills/velmios-lib/references/features-and-resource-apis.md) reference rewritten to cover `CRUDResourceAPIAbstract`, `ResourceApiReadOperations`, `ResourceApiCUDOperations`, `FeaturesUpdateModel`, `FeaturesUpdateUseCase`, `FeaturesService.validate_features_update_payload`, `serialize_features_item`, `depends_features_service`, `FeatureDeclaration`, `FeatureGlobalOverride`, `DependsFeaturesService.register_features`, `UpdateableField` on entity fields, and `Location` header behavior.
- **velmios-lib** skill: [Functional types](skills/velmios-lib/references/functional-types.md) reference updated with `FeatureGlobalOverride`, the `FeatureForRealmEntityId` family, and the `AuthenticationPersona` StrEnum exported from `velmios.core.types`.
- **velmios-lib** skill: [Safe URL types](skills/velmios-lib/references/safe-url-types.md) reference corrected to reflect host-based subdomain rules (`portal.`, `auth.`, `api.`) for `VelmiosPortalSafeUrl` / `VelmiosAuthSafeUrl` / `VelmiosApiSafeUrl`.
- Repository [README](README.md): skill list expanded to include `commit`, `fastapi-factory-utilities`, `jira-cli`, `python`, `release`, `story-driven-development`, `velmios-lib`, and `velmios-projects`; skill descriptions for `fastapi-factory-utilities` and `velmios-lib` rewritten to reflect the 2.0.0 content (PUT reconciliation / Hypercorn / composable permissions / use-case abstracts / security telemetry).

### Deprecated

### Removed

- **velmios-lib** skill: references to the removed non-lite `AdminEntity` / `CustomerEntity`, `DependsAuthorizedPersona`, `DependsSystemHasScope`, and `VelmiosKratosIdentitySchemaId`.
- **fastapi-factory-utilities** skill: implicit `QueryAbstract` inheritance from `ApiEntityAbstract` (breaking change in FFU v5.0.0); derive filters explicitly via `Entity.build_query_filter_model()`.

### Fixed

### Security

- **velmios-lib** skill: documents centralized HTTP exception handling with the `velmios.security.auth_failures` OpenTelemetry counter and span attributes, ensuring authentication / authorization failures emit consistent telemetry.
- **fastapi-factory-utilities** skill: documents 403 mapping for JWT invalid tokens and 422 envelope for request validation errors.

---

## [1.8.1] - 2026-04-11

### Added

- **fastapi-factory-utilities** skill: [Query utilities](skills/fastapi-factory-utilities/references/query-utilities.md) reference for `QueryAbstract`, `SearchableEntity`, and ODM query translation.
- **velmios-lib** skill: [Safe URL types](skills/velmios-lib/references/safe-url-types.md) and [Features and resource APIs](skills/velmios-lib/references/features-and-resource-apis.md) references.

### Changed

- **fastapi-factory-utilities** skill: `SKILL.md` and [ODM plugin](skills/fastapi-factory-utilities/references/odm-plugin.md) link to query utilities; skill metadata **1.0.1**.
- **velmios-lib** skill: align `SKILL.md`, quick start, and security/JWT/entities/functional-types/authorization/permissions docs with current library (`DependsAuthenticationContext`, dual JWT, lite entities, resource API hooks); skill metadata **1.0.1**.

### Deprecated

### Removed

### Fixed

### Security

---

## [1.8.0] - 2026-02-25

### Added

- **commit** skill: Conventional Commit guidance for tickets, versions, changelog maintenance, and commitlint integration

### Changed

- fastapi-factory-utilities JWT authentication reference: align JWT examples and wording with latest library changes

### Deprecated

### Removed

### Fixed

### Security

---

## [1.7.0] - 2026-02-19

### Added

- **release** skill: Release workflow (changelog, git state, atomic commits, SemVer, annotated tag); follows git skill conventions
- **velmios-projects** skill: Catalog of Velmios-related projects with absolute paths and summaries for cross-project discovery

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## [1.6.0] - 2026-02-08

### Added

- **agents/developper.md**: Developper agent that follows the story-driven-development skill (branch, context, scenarios, OpenAPI, TDD, implement, lint, tests, commit, PR)

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## [1.5.0] - 2026-02-08

### Added

- **jira-cli** skill: Interact with Jira from the command line using ankitpokhrel/jira-cli (create, update, list, link, comment); references for commands and install/configure
- **story-driven-development** skill: Feature implementation from user story (branch, context, scenarios, contract, TDD, quality gate, commit, push, PR); Jira ticket comments for decisions

### Changed

- jira-epics-stories SKILL.md: updated to use jira-cli instead of Jira MCP

### Removed

- jira-epics-stories reference: `references/jira-mcp-tools.md` (replaced by jira-cli skill)

---

## [1.4.0] - 2026-02-08

### Added

- **fastapi-factory-utilities** reference: `references/jwt-authentication.md` for JWT Bearer validation, JWKS store, and custom verifiers

### Changed

- fastapi-factory-utilities SKILL.md: document JWT authentication reference and "When to use" guidance
- fastapi-factory-utilities references: aiohttp, hydra-service, kratos-service, repository-pattern updates

---

## [1.3.0] - 2026-02-08

### Added

- Install script syncs **agents** to `~/.claude/agents` (e.g. `analyst.md`)

### Changed

- Install script renamed from `install_or_update_skills.sh` to `install_or_update.sh`
- README: document agents in installation, installed paths (skills and agents), and new script URL

---

## [1.2.0] - 2026-02-08

### Added

- **jira-epics-stories** skill: Writing epics and user stories with acceptance criteria; creating or updating them in Jira via Jira MCP when available
- jira-epics-stories reference: `references/jira-mcp-tools.md` for MCP server variants and tool names
- jira-epics-stories assets: `assets/templates.md` for epic and story markdown templates
- **agents/analyst.md**: Business Analyst agent with Epic & User Story Writer subagent; references jira-epics-stories skill

### Changed

- README: document jira-epics-stories in available skills table

---

## [1.1.0] - 2026-02-06

### Added

- **writing-skills** skill: Authoring Agent Skills (SKILL.md), structure, MUST/SHOULD/MAY phrasing, and checklists
- writing-skills reference: `references/checklist.md` for skill authoring

### Changed

- README: document writing-skills in available skills table

---

## [1.0.0] - 2026-02-06

### Added

- Initial skill collection for agentic software delivery
- **git** skill: Commit conventions, branch naming, semantic versioning, and pre-commit hooks
- **http-api-architecture** skill: REST patterns, caching, distributed tracing, OAuth2/OIDC, and webhooks
- **openapi** skill: OpenAPI 3.1 specification design and Spectral validation
- **openapi-testing** skill: Contract testing with Portman and Newman
- **python-architecture** skill: Clean architecture patterns for FastAPI services
- **python-docstring** skill: Python documentation standards
- **python-lint** skill: Pylint configuration and code quality
- **python-starter** skill: Python project bootstrapping
- **python-test** skill: Pytest, fixtures, mocks, and Testcontainers
- **software-architecture** skill: Clean Architecture, DDD, SOLID, and microservices
- Skill template for creating new skills
- Install script (`scripts/install_or_update.sh`) for one-line install and update alias
- Repository README with comprehensive documentation

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

[Unreleased]: https://github.com/DeerHide/agent_skills/compare/v2.0.2...HEAD
[2.0.2]: https://github.com/DeerHide/agent_skills/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/DeerHide/agent_skills/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/DeerHide/agent_skills/compare/v1.8.1...v2.0.0
[1.8.1]: https://github.com/DeerHide/agent_skills/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/DeerHide/agent_skills/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/DeerHide/agent_skills/compare/v1.6.1...v1.7.0
[1.6.0]: https://github.com/DeerHide/agent_skills/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/DeerHide/agent_skills/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/DeerHide/agent_skills/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/DeerHide/agent_skills/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/DeerHide/agent_skills/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/DeerHide/agent_skills/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/DeerHide/agent_skills/releases/tag/v1.0.0
