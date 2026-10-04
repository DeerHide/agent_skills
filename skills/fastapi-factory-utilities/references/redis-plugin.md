# Redis Plugin

Standalone async Redis / Valkey client. Own connection pool, separate from `TaskiqPlugin`.

## When to use

- Caching, locks, or other Redis keys that are **not** Taskiq broker/result keys.
- Per-service Valkey ACL grants of the form `~{svc}:*`.
- HTTP routes and Taskiq workers that need `depends_redis` / `depends_redis_plugin`.

Do not use this plugin as Taskiq's broker backend. Taskiq opens its own Redis connections under `{name_suffix}:taskiq:*`.

## RedisPlugin

```python
from fastapi_factory_utilities.core.plugins.redis_plugin import (
    RedisPlugin,
    RedisCredentialsConfig,
    RedisPluginNotStartedError,
    depends_redis,
    depends_redis_plugin,
)

plugin = RedisPlugin(name_suffix="customers-backend")

plugin = RedisPlugin(
    name_suffix="customers-backend",
    redis_credentials_config=RedisCredentialsConfig(url="redis://localhost:6379/0"),
)
```

- `name_suffix` is required and non-empty. It is the key namespace prefix.
- Credentials default to the `redis:` YAML section via `build_redis_credentials_config` (`url: str` only).
- `on_load` resolves credentials. `on_startup` creates `redis.asyncio.Redis.from_url(..., decode_responses=True)`, pings, writes client + plugin onto application state, and reports CACHE readiness.
- `client` raises `RedisPluginNotStartedError` if read before `on_startup`.

### YAML

```yaml
redis:
  url: "${REDIS_URL:redis://localhost:6379/0}"
```

## Key builder (ACL boundary)

Consumers MUST write every key through `build_key` so the grant `~{svc}:*` covers them:

```python
plugin.build_key("session", session_id)  # customers-backend:session:<id>
```

Raises `ValueError` when no parts are given or any part is empty. The plugin does not set TTL, serialization, or fail-open policy.

## Dependency injection

```python
from fastapi import Depends
from fastapi_factory_utilities.core.plugins.redis_plugin import depends_redis, depends_redis_plugin


@router.get("/cache/{key}")
async def get_cached(
    key: str,
    redis=Depends(depends_redis),
    plugin=Depends(depends_redis_plugin),
):
    return await redis.get(plugin.build_key("cache", key))
```

Both depends work on HTTP routes and Taskiq workers (`TaskiqDepends`). Missing plugin → `PluginNotRegisteredError`.

## Status

`PluginStatusMixin` registers `ComponentTypeEnum.CACHE`, identifier `Redis`. A failed ping at startup marks the component unhealthy and re-raises.

## Extra

Install the `redis` extra. Importing the plugin without it raises `MissingExtraError`.

## Reference

- `src/fastapi_factory_utilities/core/plugins/redis_plugin/plugins.py`
- `src/fastapi_factory_utilities/core/plugins/redis_plugin/configs.py`
- `src/fastapi_factory_utilities/core/plugins/redis_plugin/depends.py`
- `src/fastapi_factory_utilities/core/plugins/redis_plugin/builder.py`
- See also: [Taskiq](taskiq.md), [Status service](status-service.md).
