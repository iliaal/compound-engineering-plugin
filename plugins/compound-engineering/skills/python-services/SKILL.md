---
name: python-services
description: Python patterns for CLI tools, async parallelism, and backend services. Use when building CLI apps, async/parallel Python, FastAPI services, background jobs, or configuring Python project tooling (uv, ruff, ty).
---

# Python Services & CLI

## Modern Tooling

| Tool | Replaces | Purpose |
|------|----------|---------|
| **uv** | pip, virtualenv, pyenv, pipx | Package/dependency management |
| **ruff** | flake8, black, isort | Linting + formatting |
| **ty** | mypy, pyright | Type checking (Astral, faster) |

- `uv init --package myproject` for distributable packages, `uv init` for apps
- `uv add <pkg>`, `uv add --group dev <pkg>`, never edit pyproject.toml deps manually
- `uv run <cmd>` instead of activating venvs
- `uv.lock` goes in version control
- Use `[dependency-groups]` (PEP 735) for dev/test/docs, not `[project.optional-dependencies]`
- PEP 723 inline metadata for standalone scripts with deps
- `ruff check --fix . && ruff format .` for lint+format in one pass

## CLI Tools

**Entry points** in pyproject.toml:
```toml
[project.scripts]
my-tool = "my_package.cli:main"
```

**Click** (recommended for complex CLIs):
```python
import click

@click.group()
@click.version_option()
def cli(): ...

@cli.command()
@click.argument("name")
@click.option("--count", default=1, type=int)
def greet(name: str, count: int):
    for _ in range(count):
        click.echo(f"Hello, {name}!")

def main():
    cli()
```

**argparse** for simple CLIs — subparsers for subcommands, `parser.add_argument("--output", "-o")`.

Use `src/` layout. Include `py.typed` for type hints. `importlib.resources.files()` for package data access.

## Parallelism

| Workload | Approach |
|----------|----------|
| Many concurrent I/O calls | `asyncio` (gather, create_task) |
| CPU-bound computation | `multiprocessing.Pool` or `concurrent.futures.ProcessPoolExecutor` |
| Mixed I/O + CPU | `asyncio.to_thread()` to offload blocking work |
| Simple scripts, few connections | Stay synchronous |

**Key rule:** Stay fully sync or fully async within a call path.

**asyncio patterns:**
- `asyncio.gather(*tasks)` for concurrent I/O — use `return_exceptions=True` for partial failure tolerance
- `asyncio.Semaphore(n)` to limit concurrency (rate limiting external APIs)
- `asyncio.wait_for(coro, timeout=N)` for timeouts
- `asyncio.Queue` for producer-consumer
- `asyncio.Lock` when coroutines share mutable state
- Never block the event loop: `asyncio.to_thread(sync_fn)` for sync libs, `aiohttp`/`httpx.AsyncClient` for HTTP
- Handle `CancelledError` — always re-raise after cleanup
- Async generators (`async for`) for streaming/pagination

**multiprocessing** for CPU-bound:
```python
from concurrent.futures import ProcessPoolExecutor
with ProcessPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(cpu_task, items))
```

## FastAPI Services

**Project structure:**
```
app/
├── api/v1/endpoints/    # Route handlers
├── core/                # config.py, security.py, database.py
├── models/              # SQLAlchemy models
├── schemas/             # Pydantic request/response
├── services/            # Business logic
├── repositories/        # Data access (generic CRUD base)
└── main.py              # Lifespan, middleware, router includes
```

**Lifespan** for startup/shutdown: `@asynccontextmanager async def lifespan(app):`

**Configuration** — `pydantic_settings.BaseSettings` with `model_config = {"env_file": ".env"}`. Required fields = no default (fails fast at boot). `env_nested_delimiter = "__"` for grouped config. `secrets_dir` for Docker/K8s mounted secrets.

**Dependency injection** — `Depends(get_db)` for sessions, `Depends(get_current_user)` for auth. Override in tests: `app.dependency_overrides[get_db] = mock_db`.

**Async DB** — SQLAlchemy `AsyncSession` with `asyncpg`. Session-per-request via `async with AsyncSessionLocal() as session: yield session`.

**Repository pattern** — Generic `BaseRepository[ModelType, CreateSchema, UpdateSchema]` with get/get_multi/create/update/delete. Service layer holds business logic, routes stay thin.

## Background Jobs

- Return job ID immediately, process async. Client polls `/jobs/{id}` for status
- **Celery**: `@app.task(bind=True, max_retries=3, autoretry_for=(ConnectionError,))` — exponential backoff: `raise self.retry(countdown=2**self.request.retries * 60)`
- **Alternatives**: Dramatiq (modern Celery), RQ (simple Redis), cloud-native (SQS+Lambda, Cloud Tasks)
- **Idempotency is mandatory** — tasks may retry. Use idempotency keys for external calls, check-before-write, upsert patterns
- Dead letter queue for permanently failed tasks after max retries
- Task workflows: `chain(a.s(), b.s())` for sequential, `group(...)` for parallel, `chord(group, callback)` for fan-out/fan-in

## Resilience

**Retries with tenacity:**
```python
from tenacity import retry, stop_after_attempt, wait_exponential_jitter, retry_if_exception_type

@retry(
    retry=retry_if_exception_type((ConnectionError, TimeoutError)),
    stop=stop_after_attempt(5) | stop_after_delay(60),
    wait=wait_exponential_jitter(initial=1, max=30),
    before_sleep=log_retry_attempt,
)
def call_api(url: str) -> dict: ...
```

- Retry only transient errors: network, 429/502/503/504. Never retry 4xx (except 429), auth errors, validation errors
- Every network call needs a timeout
- `@fail_safe(default=[])` decorator for non-critical paths — return cached/default on failure
- Stack decorators: `@traced @with_timeout(30) @retry(...)` — separate infra from business logic

## Observability

- **structlog** for JSON structured logging. Configure once at startup with `JSONRenderer`, `TimeStamper`, `merge_contextvars`
- **Correlation IDs** — generate at ingress (`X-Correlation-ID` header), bind to `contextvars`, propagate to downstream calls
- **Log levels**: DEBUG=diagnostics, INFO=operations, WARNING=anomalies handled, ERROR=failures needing attention. Never log expected behavior at ERROR
- **Prometheus metrics** — track latency (Histogram), traffic (Counter), errors (Counter), saturation (Gauge). Keep label cardinality bounded (no user IDs)
- **OpenTelemetry** for distributed tracing across services

## Discipline

- For non-trivial changes, pause and ask: "is there a more elegant way?" Skip for obvious fixes.
- Simplicity first — every change as simple as possible, impact minimal code
- Only touch what's necessary — avoid introducing unrelated changes
- No hacky workarounds — if a fix feels wrong, step back and implement the clean solution

## Error Handling

- Validate inputs at boundaries before expensive ops. Report all errors at once when possible
- Use specific exceptions: `ValueError`, `TypeError`, `KeyError`, not bare `Exception`
- `raise ServiceError("upload failed") from e` — always chain to preserve debug trail
- Convert external data to domain types (enums, Pydantic models) at system boundaries
- Batch processing: `BatchResult(succeeded={}, failed={})` — don't let one item abort the batch
- Pydantic `BaseModel` with `field_validator` for complex input validation
