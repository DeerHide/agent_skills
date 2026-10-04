# Taskiq Scheduled Tasks

The Taskiq plugin provides background task processing and scheduling with Redis backend.

## When to Use

Use Taskiq plugin when:
- Processing background tasks asynchronously
- Scheduling recurring tasks (cron jobs)
- Distributing work across multiple workers
- Decoupling long-running operations from HTTP requests
- Building task queues with Redis backend
- Executing tasks that don't need immediate response

## TaskiqPlugin

The plugin integrates Taskiq with FastAPI for distributed task processing.

### Configuration

```python
from fastapi_factory_utilities.core.plugins.taskiq_plugin import TaskiqPlugin
from fastapi_factory_utilities.core.plugins.redis_plugin import RedisCredentialsConfig

# With automatic Redis config from application.yaml (`redis.url`)
plugin = TaskiqPlugin(name_suffix="my_app")

# With custom Redis config (own pool keys still live under name_suffix)
redis_config = RedisCredentialsConfig(url="redis://localhost:6379/0")
plugin = TaskiqPlugin(
    name_suffix="my_app",
    redis_credentials_config=redis_config,
)
```

`TaskiqPlugin` defaults `stream_maxlen=10_000` (approximate) on `RedisStreamBroker` so Valkey streams are trimmed on publish.

### Register Hook

You can provide a hook to register tasks when the plugin loads:

```python
def register_tasks(scheduler: SchedulerComponent) -> None:
    async def my_task(value: int) -> int:
        return value * 2

    scheduler.register_task(my_task, "my_task")

plugin = TaskiqPlugin(
    name_suffix="my_app",
    register_hook=register_tasks,
)
```

## SchedulerComponent

The scheduler component manages task registration and execution.

### Register Tasks

```python
from fastapi_factory_utilities.core.plugins.taskiq_plugin.schedulers import SchedulerComponent

scheduler = SchedulerComponent(name_suffix="my_app")
scheduler.configure(redis_connection_string="redis://localhost:6379", app=fastapi_app)

async def process_order(order_id: str) -> dict:
    # Process order logic
    return {"status": "processed", "order_id": order_id}

scheduler.register_task(process_order, "process_order")
```

### Execute Tasks

```python
# Get registered task
task = scheduler.get_task("process_order")

# Execute asynchronously
result = await task.kiq(order_id="12345")

# Wait for result
final_result = await result.wait_result()
```

### Scheduled Tasks

Tasks can be scheduled using `ListRedisScheduleSource`:

```python
from taskiq.scheduler.scheduled_task import ScheduledTask
from taskiq import ScheduleSource

# Create a scheduled task
scheduled_task = ScheduledTask(
    task_name="process_order",
    labels={"order_id": "12345"},
    cron="0 * * * *",  # Every hour
)

# Add to schedule source (handled automatically by plugin)
```

## Usage in Application

### Plugin Setup

```python
from fastapi_factory_utilities.core.plugins.taskiq_plugin import TaskiqPlugin

class MyAppBuilder(ApplicationGenericBuilder[MyApp]):
    def get_default_plugins(self):
        def register_tasks(scheduler):
            async def cleanup_task():
                # Cleanup logic
                pass

            scheduler.register_task(cleanup_task, "cleanup")

        return [
            TaskiqPlugin(
                name_suffix="my_app",
                register_hook=register_tasks,
            ),
        ]
```

### Access Scheduler

```python
from fastapi import Request, Depends
from fastapi_factory_utilities.core.plugins.taskiq_plugin import (
    depends_scheduler_component,
)

@router.post("/process")
async def process(
    request: Request,
    scheduler = Depends(depends_scheduler_component),
):
    task = scheduler.get_task("process_order")
    result = await task.kiq(order_id="12345")
    return {"task_id": result.task_id}
```

## Redis Configuration

The plugin uses Redis for:
- **Stream Broker** - Task queue with consumer groups
- **Result Backend** - Task result storage
- **Schedule Source** - Scheduled task storage

### Key prefixes (BREAKING in FFU 5.15.0)

All Taskiq Redis keys are namespaced under `name_suffix`:

| Purpose | Key pattern |
|---|---|
| Result backend | `{name_suffix}:taskiq:result` |
| Stream broker | `{name_suffix}:taskiq:stream` |
| Consumer group | `{name_suffix}:taskiq:consumers` |
| Schedule source | `{name_suffix}:taskiq:schedule` |
| Cron lock | `{name_suffix}:taskiq:cron-lock:{task_name}:{YYYYMMDDHHMM}` |

Use a stable, per-service `name_suffix` so Valkey/Redis ACLs of the form `~{svc}:*` cover the service. Changing `name_suffix` without migrating schedule keys orphans pending schedules.

The Redis plugin is a **separate** pool (`RedisPlugin`). Taskiq owns its own broker/result connections; do not share the plugin client as the Taskiq backend.

### YAML Configuration

```yaml
redis:
  url: "${REDIS_URL:redis://localhost:6379/0}"
```

## Prune stale schedules (FFU ≥ 5.14)

After registration / startup, call `prune_unregistered_schedules()` to delete persisted cron entries whose task name is no longer registered:

```python
removed = await scheduler.prune_unregistered_schedules()
```

Register or refresh a cron with a stable id (`schedule_id == task_name`):

```python
await scheduler.ensure_cron_schedule("cleanup", "0 * * * *")
```

Idempotent across pods: a matching row is a no-op; legacy random-id rows and cron-expression changes are deleted then re-inserted.

## Cron single-flight (FFU ≥ 7.0)

API + worker (and multi-replica) pods each run a scheduler loop. Duplicate kicks in the same UTC minute are suppressed two ways:

1. `MinuteGuardSchedulerLoop` refuses a second kick in the same UTC minute (upstream Taskiq's 60s wall-clock guard can fire twice around a minute boundary).
2. Redis `SET NX` lock `{name_suffix}:taskiq:cron-lock:{task_name}:{YYYYMMDDHHMM}` with TTL 70s. The lock key uses the scheduler tick (`pending_ticks`), not wall clock at send time. If the Redis client is missing, the lock **fails open** (the kick proceeds).

`SchedulerComponent` no longer auto-schedules a task named `heartbeat`. Register and schedule heartbeat yourself if you need it.

## Task Lifecycle

1. **Registration** - Tasks are registered during plugin `on_load()`
2. **Startup** - Scheduler and receiver start during `on_startup()`
3. **Execution** - Tasks execute via Redis streams
4. **Shutdown** - Scheduler stops during `on_shutdown()`

## Error Handling

The Taskiq plugin can encounter errors during task registration, execution, and Redis operations.

### Task Execution Errors

```python
from taskiq.exceptions import TaskExecutionError

async def process_order(order_id: str) -> dict:
    try:
        # Process order logic
        result = await process_order_logic(order_id)
        return {"status": "processed", "order_id": order_id}
    except ValueError as e:
        # Handle validation errors
        logger.error("Invalid order data", error=e, order_id=order_id)
        raise TaskExecutionError(f"Invalid order: {e}")
    except Exception as e:
        # Handle unexpected errors
        logger.error("Order processing failed", error=e, order_id=order_id)
        raise

# Task errors are automatically logged and can be monitored
```

### Redis Connection Errors

```python
from redis.exceptions import ConnectionError, TimeoutError

# Connection errors are handled by Taskiq:
# - Tasks are queued and retried when connection is restored
# - Application continues operating even if Redis is unavailable
# - Monitor logs for connection errors

# To handle Redis unavailability:
try:
    task = scheduler.get_task("process_order")
    result = await task.kiq(order_id="12345")
except ConnectionError as e:
    # Handle Redis connection failure
    logger.error("Redis connection error", error=e)
    # Fallback or retry logic
    raise
except TimeoutError as e:
    # Handle Redis timeout
    logger.error("Redis timeout", error=e)
    raise
```

### Task Registration Errors

```python
def register_tasks(scheduler: SchedulerComponent) -> None:
    try:
        async def my_task(value: int) -> int:
            return value * 2

        scheduler.register_task(my_task, "my_task")
    except Exception as e:
        # Handle task registration errors
        logger.error("Failed to register task", error=e, task_name="my_task")
        raise
```

### Result Retrieval Errors

```python
from taskiq.exceptions import ResultTimeoutError

try:
    task = scheduler.get_task("process_order")
    result = await task.kiq(order_id="12345")

    # Wait for result with timeout
    final_result = await result.wait_result(timeout=30)
except ResultTimeoutError:
    # Handle result timeout
    logger.warning("Task result timeout", task_id=result.task_id)
    # Check task status or retry
except Exception as e:
    # Handle other result errors
    logger.error("Failed to get task result", error=e)
    raise
```

### Scheduled Task Errors

```python
# Scheduled task errors are logged automatically
# Monitor scheduled task execution:
# - Check logs for scheduled task failures
# - Set up alerts for recurring task errors
# - Verify cron expressions are correct

# Handle scheduled task errors in task implementation:
async def scheduled_cleanup():
    try:
        await cleanup_old_data()
    except Exception as e:
        # Log and handle errors
        logger.error("Scheduled cleanup failed", error=e)
        # Don't raise - allow next scheduled run to retry
```

## Best Practices

1. **Name Suffix**: Use a stable per-service `name_suffix` (Redis key ACL boundary)
2. **Task Naming**: Use descriptive task names; `ensure_cron_schedule` uses `task_name` as `schedule_id`
3. **Prune**: Call `prune_unregistered_schedules()` after deploy when dropping or renaming tasks
4. **Error Handling**: Handle task failures gracefully
5. **Result Timeout**: Configure appropriate result expiration times
6. **Consumer Groups**: Use consumer groups for task distribution
7. **Stream bound**: Leave `stream_maxlen` at 10_000 unless a service has a measured reason to raise it

## Reference

- `src/fastapi_factory_utilities/core/plugins/taskiq_plugin/` - Plugin implementation
- `src/fastapi_factory_utilities/core/plugins/taskiq_plugin/schedulers.py` - SchedulerComponent, MinuteGuardSchedulerLoop
- `src/fastapi_factory_utilities/core/plugins/taskiq_plugin/plugins.py` - TaskiqPlugin
