# Async/Await Patterns

## Async Functions

- Use `async def` for all I/O operations (database, HTTP, message queues, etc.)
- Use `async def` for functions that call other async functions
- Prefer async context managers (`async with`) for resource management

## Context Managers

Use `asynccontextmanager` for async context managers:

```python
from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

@asynccontextmanager
async def fastapi_lifespan(self, fastapi: FastAPI) -> AsyncGenerator[None, None]:
    await self.startup_plugins()
    await self.on_startup()
    try:
        yield
    finally:
        await self.on_shutdown()
        await self.shutdown_plugins()
```

## Parallel Operations

Use `asyncio.TaskGroup` (Python 3.11+) for parallel async operations:

```python
from asyncio import TaskGroup

async with TaskGroup() as tg:
    tg.create_task(self._verify(jwt_raw=jwt_raw), name="verify_jwt")
    task_decode: Task[Any] = tg.create_task(self._decode_jwt(jwt_raw=jwt_raw), name="decode_jwt")
```

## Async Generators

Use `AsyncGenerator` for async generator functions:

```python
from collections.abc import AsyncGenerator

async def fetch_items() -> AsyncGenerator[Item, None]:
    async for item in database.fetch():
        yield item
```

## Exception Handling

Handle exceptions in async code properly, ensuring resources are cleaned up:

```python
async def operation(self) -> None:
    try:
        await self._perform_operation()
    except SpecificError as e:
        await self._cleanup()
        raise
```
