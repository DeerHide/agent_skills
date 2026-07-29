# Application Framework

The application framework provides the foundation for building microservices with a plugin-based architecture. It handles FastAPI lifespan, plugin lifecycle, configuration loading, and ASGI server selection (Uvicorn, Hypercorn, or Granian).

## When to use

- Building FastAPI microservices that need structured initialization.
- Creating plugin-based architectures for extensibility.
- Managing application lifecycle (startup, shutdown).
- Loading configuration from YAML files with environment overrides.
- Choosing between Uvicorn, Hypercorn, and Granian for the ASGI server.
- Registering shared CSRF and validation exception handlers.

## ApplicationAbstract

Subclass for every microservice.

```python
class ApplicationAbstract(ABC):
    PACKAGE_NAME: ClassVar[str]
    CONFIG_CLASS: ClassVar[type[RootConfig]] = RootConfig
    CONFIG_FILENAME: ClassVar[str] = "application.yaml"
    ODM_DOCUMENT_MODELS: ClassVar[list[type[Document]]]

    def __init__(self, root_config: RootConfig, plugins: list[PluginAbstract], fastapi_builder: FastAPIBuilder): ...

    def setup(self) -> None:
        """Build the FastAPI app, register `status_service` / `config` / `application` on state, call `configure()`, then load plugins."""

    @asynccontextmanager
    async def fastapi_lifespan(self, fastapi: FastAPI) -> AsyncGenerator[None, None]: ...
```

Lifespan order on startup: `plugin.on_startup()` (in declaration order) → `application.on_startup()`. On shutdown the reverse: `application.on_shutdown()` → `plugin.on_shutdown()`.

### Required class variables

- `PACKAGE_NAME: ClassVar[str]` — used to locate `{PACKAGE_NAME}/application.yaml`.
- `CONFIG_CLASS: ClassVar[type[RootConfig]]` — root config schema (defaults to `RootConfig`).
- `ODM_DOCUMENT_MODELS: ClassVar[list[type[Document]]]` — Beanie document models loaded by the ODM plugin.

### Lifecycle methods (abstract)

```python
@abstractmethod
def configure(self) -> None: ...

@abstractmethod
async def on_startup(self) -> None: ...

@abstractmethod
async def on_shutdown(self) -> None: ...
```

### Helper methods

- `configure_csrf()` — reads `config.csrf` (`secret`, `cookie_samesite`, `cookie_secure`), wires `fastapi-csrf-protect`, and registers `CsrfProtect` on `app.state` via `DependsCsrfProtect.import_to_state`. Must be called from your `configure()` implementation when CSRF is required.
- `add_to_state(key, value)` — schedule a value to be added to `app.state` once the ASGI app is built. Reused for plugin resources.
- `get_asgi_app()`, `get_config()`, `get_status_service()` — accessors.

### Exception handler helpers

```python
from fastapi_factory_utilities.core.app import (
    register_exception_handlers,
    register_csrf_protect_exception_handler,
)


register_exception_handlers(app)                    # RequestValidationError → 422
register_csrf_protect_exception_handler(app)        # CsrfProtectError → 403
```

The validation handler logs `Validation error` and returns `{"detail": exc.errors()}` (HTTP 422). The CSRF handler logs `CSRF error` and returns `{"detail": "CSRF token is invalid"}` (HTTP 403). See [CSRF and validation](csrf-and-validation.md) for the full envelope contract.

## ApplicationGenericBuilder

Builder pattern for constructing applications with type safety.

```python
class MyAppBuilder(ApplicationGenericBuilder[MyApp]):
    def get_default_plugins(self) -> list[PluginAbstract]:
        return [ODMPlugin(), OpenTelemetryPlugin()]

    def __init__(self, plugins: list[PluginAbstract] | None = None) -> None:
        super().__init__(plugins=plugins or self.get_default_plugins())
```

### Methods

- `add_plugin_to_activate(plugin)` — append a plugin.
- `add_config(config)` — provide a pre-built `RootConfig`.
- `add_fastapi_builder(fastapi_builder)` — replace the default `FastAPIBuilder`.
- `set_server_implementation(ServerImplementationEnum.UVICORN | HYPERCORN | GRANIAN)` — pick the ASGI server (`ServerImplementationEnum` lives in `core.app.builder`).
- `build(**kwargs)` — instantiate the application; extra kwargs are forwarded to the application constructor (used by Velmios for JWT configs / introspect services).
- `build_as_uvicorn_utils(**kwargs)` / `build_as_hypercorn_utils(**kwargs)` / `build_as_granian_utils(**kwargs)` — build the application and wrap it in the matching server utility (`UvicornUtils` / `HypercornUtils` / `GranianUtils`).
- `build_and_serve(**kwargs)` — convenience: build, configure logging from `root_config.logging`, and serve with the selected ASGI server. `KeyboardInterrupt` is swallowed for clean local shutdowns.
- `configure_logging(mode, logging_config)` — call `setup_log(...)` directly.

The builder's `build_*` methods forward `**kwargs`, so application classes accept additional initializer parameters (e.g. Velmios `jwt_bearer_authentication_config_internal`).

### ASGI server utilities

Uvicorn / Hypercorn / Granian utilities expose:

- `add_ssl_certificates(ssl_keyfile=..., ssl_certfile=..., ssl_keyfile_password=...)`
- `serve()` — start the server.

They read host, port, workers, and reload flag from `config.server` and `config.development`. Hypercorn maps these onto `hypercorn.config.Config`; Uvicorn onto `uvicorn.Config`; Granian onto Granian's embed server (`core.utils.granian`). Granian warns and ignores `workers > 1` and `reload` (embed limitations). `clean_uvicorn_logger()` / `clean_hypercorn_logger()` integrate the server's logger with structlog.

## PluginAbstract

Base class for all plugins. The plugin lifecycle is:

1. `on_load()` — synchronous initialization (validate configuration, register dependencies, add to application state).
2. `on_startup()` — asynchronous initialization (connect to external services, start background tasks).
3. `on_shutdown()` — cleanup (close connections, stop background tasks).

```python
class MyPlugin(PluginAbstract):
    def on_load(self) -> None:
        config = self._application.get_config()
        ...

    async def on_startup(self) -> None: ...

    async def on_shutdown(self) -> None: ...
```

`self._add_to_state(key, value)` schedules a value to be added to the ASGI app state once available.

## Complete example

```python
from fastapi_factory_utilities.core.app import (
    ApplicationAbstract,
    ApplicationGenericBuilder,
    RootConfig,
    register_csrf_protect_exception_handler,
    register_exception_handlers,
)
from fastapi_factory_utilities.core.app.builder import ServerImplementationEnum
from fastapi_factory_utilities.core.plugins.odm_plugin import ODMPlugin
from fastapi_factory_utilities.core.plugins.opentelemetry_plugin import OpenTelemetryPlugin


class MyAppConfig(RootConfig):
    """Add service-specific config fields here."""


class MyApp(ApplicationAbstract):
    CONFIG_CLASS = MyAppConfig
    PACKAGE_NAME = "my_app"
    ODM_DOCUMENT_MODELS = []

    def configure(self) -> None:
        self.configure_csrf()
        register_csrf_protect_exception_handler(self.get_asgi_app())
        register_exception_handlers(self.get_asgi_app())

    async def on_startup(self) -> None: ...

    async def on_shutdown(self) -> None: ...


class MyAppBuilder(ApplicationGenericBuilder[MyApp]):
    def get_default_plugins(self) -> list:
        return [ODMPlugin(), OpenTelemetryPlugin()]

    def __init__(self, plugins: list | None = None) -> None:
        # Base builder does not call get_default_plugins — wire them here.
        if plugins is None:
            plugins = self.get_default_plugins()
        super().__init__(plugins=plugins)


if __name__ == "__main__":
    MyAppBuilder().set_server_implementation(ServerImplementationEnum.HYPERCORN).build_and_serve()
```

## Best practices

1. Keep `configure()` lightweight (routes, middleware, CSRF, handlers). Do heavy lifting in `on_startup()` so the FastAPI lifespan reports startup errors clearly.
2. Always register both `register_exception_handlers(app)` and `register_csrf_protect_exception_handler(app)` when CSRF is enabled — neither is auto-registered by `ApplicationAbstract`.
3. Pick the server implementation per environment (Hypercorn for HTTP/2 / HTTP/3, Granian for embed/Rust, Uvicorn for legacy stacks). The choice is opaque to the rest of the app.
4. Use `add_to_state(...)` for resources needed across dependencies (status service, JWT store, audit publishers).
5. Plugin order matters: load `ODMPlugin` before repositories, and `OpenTelemetryPlugin` early so spans cover the rest of startup.
6. Always override builder `__init__` (or pass `plugins=` / `add_plugin_to_activate`) so default plugins are actually activated.

## Reference

- `src/fastapi_factory_utilities/core/app/application.py`
- `src/fastapi_factory_utilities/core/app/builder.py`
- `src/fastapi_factory_utilities/core/app/handlers.py`
- `src/fastapi_factory_utilities/core/app/csrf.py`
- `src/fastapi_factory_utilities/core/app/fastapi_builder.py`
- `src/fastapi_factory_utilities/core/utils/uvicorn.py`
- `src/fastapi_factory_utilities/core/utils/hypercorn.py`
- `src/fastapi_factory_utilities/core/utils/granian.py`
- `src/fastapi_factory_utilities/core/plugins/__init__.py`
- See also: [CSRF and validation](csrf-and-validation.md).
