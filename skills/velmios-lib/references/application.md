# Velmios application

## When to use

- Bootstrapping a **Velmios microservice** with the standard plugin set, dual JWT bearer configs, and JWKS store.
- Registering Velmios **security, CSRF, and validation** exception handlers in one go.
- Resolving the **self URL**, **API URL**, **portal URL**, or **auth URL** for the running service.

## Overview

`velmios.core.app` provides the application-level primitives wrapped on top of `fastapi-factory-utilities`:

```python
from velmios.core.app import (
    VelmiosApplicationAbstract,
    VelmiosApplicationBuilderAbstract,
    VelmiosRootConfig,
    VelmiosInformationConfig,
    VelmiosCredentialsConfig,
    VelmiosAppCredentialsConfig,
    depends_velmios_information,
    depends_velmios_credentials,
    depends_velmios_app_credentials,
    depends_self_url,
    AutoRedirectStrictSlashesMiddleware,
)
```

## VelmiosApplicationAbstract

Subclass for every Velmios microservice. Defaults:

- `PACKAGE_NAME = "velmios.app"`
- `CONFIG_CLASS = VelmiosRootConfig`
- Constructor kwargs (popped before delegating to `ApplicationAbstract`):
  - `enabled_jwks_store_memory: bool = True`
  - `jwks_store_memory: JWKStoreMemory | None`
  - `jwt_bearer_authentication_config_internal: JWTBearerAuthenticationConfig | None`
  - `jwt_bearer_authentication_config_customer: JWTBearerAuthenticationConfig | None`
  - `jwt_introspect_service_internal: VelmiosInternalHydraIntrospectService | None`
  - `jwt_introspect_service_customer: VelmiosCustomerHydraIntrospectService | None`

### Configuration entry points

| Method | Responsibility |
|---|---|
| `configure_jwt_bearer_authentication()` | Builds internal and customer `JWTBearerAuthenticationConfig` (one per `key="internal"` / `key="customer"`) and imports them onto `app.state` via `DependsJWTBearerAuthenticationConfig.import_to_state`. |
| `velmios_configure()` | Calls `configure_csrf()`, `configure_jwt_bearer_authentication()`, then registers the CSRF, generic, and security exception handlers. |
| `configure_jwks_store_memory()` | When enabled, builds the in-memory JWKS store via `configure_velmios_jwks_store_memory(self)` and imports it via `DependsHydraJWKStoreMemory.import_to_state`. |
| `get_http_exception_detail_enricher()` | Optional service-specific hook returning `(Request, HTTPException, detail) -> detail` to enrich 4xx response bodies (defaults to `None`). |

`configure`, `on_startup`, and `on_shutdown` remain abstract — each service implements its concrete startup pipeline (typical: call `velmios_configure()` from `configure()` and `await self.configure_jwks_store_memory()` from `on_startup()`).

### Exception handler registration

`velmios_configure()` wires the following handlers:

1. `register_csrf_protect_exception_handler(app)` — CSRF rejections → HTTP 403 with structured detail (see [FFU CSRF & validation reference](../../fastapi-factory-utilities/references/csrf-and-validation.md)).
2. `register_exception_handlers(app)` — request validation → HTTP 422.
3. `register_security_exception_handlers(app, http_exception_detail_enricher=self.get_http_exception_detail_enricher())` — Velmios security exceptions, permission failures, and global `HTTPException` routing with telemetry.

See [Exception handling](exception-handling.md) for the full envelope, status codes, and telemetry contract.

## VelmiosApplicationBuilderAbstract

Builder used to assemble the application and plugin list.

- `get_default_http_clients_keys()` returns the canonical Hydra clients: `hydra_internal_public`, `hydra_internal_admin`, `hydra_customer_public`, `hydra_customer_admin`. Subclasses append the Kratos clients (`kratos_public`, `kratos_admin`) and any service-specific keys via `additional_http_clients`.
- `get_velmios_default_plugins(additional_plugins=None, additional_http_clients=None)` returns `[OpenTelemetryPlugin(), AioHttpClientPlugin(keys=...), ODMPlugin(), *additional_plugins]`.
- `get_default_plugins()` is abstract — implement it to call `get_velmios_default_plugins(...)` with service-specific keys/plugins.
- `jwks_store_memory(enabled=True)` toggles the in-memory JWKS store; the builder forwards the value to the application via `enabled_jwks_store_memory`.

```python
class MyAppBuilder(VelmiosApplicationBuilderAbstract[MyApp]):
    def get_default_plugins(self):
        return self.get_velmios_default_plugins(
            additional_http_clients=["kratos_public", "kratos_admin", "my_service_http"],
        )
```

## VelmiosRootConfig

Extends `RootConfig` from FFU:

```python
class VelmiosRootConfig(RootConfig):
    credentials: VelmiosCredentialsConfig
    velmios: VelmiosInformationConfig


class VelmiosInformationConfig(BaseModel):
    api_url: HttpUrl
    auth_url: HttpUrl
    portal_url: HttpUrl


class VelmiosAppCredentialsConfig(BaseModel):
    client_id: HydraClientId
    client_secret: HydraClientSecret
```

Use `depends_velmios_information`, `depends_velmios_credentials`, and `depends_velmios_app_credentials` to inject the parsed config slices into request handlers.

`depends_self_url(root_config)` returns the canonical self URL:

```python
HttpUrl(f"{api_url}/{root_path}")
```

Use it when generating links/redirects (e.g. login flows) so the URL respects ingress configuration and the application root path.

## Auto-redirect middleware

`AutoRedirectStrictSlashesMiddleware` (registered by Velmios applications) normalizes trailing slashes for HTTP redirects. Combine with the FFU `register_csrf_protect_exception_handler` to ensure browser redirects keep the CSRF state intact.

## Reference

- `src/velmios/core/app/applications.py`
- `src/velmios/core/app/configs.py`
- `src/velmios/core/app/middlewares.py`
- `src/velmios/core/security/jwt/stores.py`
- `src/velmios/core/security/handlers.py`
- See also: [Exception handling](exception-handling.md), [JWT authentication](jwt-authentication.md), [FFU application framework](../../fastapi-factory-utilities/references/application-framework.md).
