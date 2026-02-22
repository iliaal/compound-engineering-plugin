---
name: php-laravel
description: >-
  Modern PHP 8.4 and Laravel patterns: architecture, Eloquent, queues, PHPUnit
  testing. Use when asked to "write PHP", "build a Laravel app", "fix Eloquent
  query", "add a queue job", "write a PHPUnit test", or mentions PHP, Laravel,
  Eloquent, Blade, artisan, or migrations.
---

# PHP & Laravel Development

## Code Style

- `declare(strict_types=1)` in every file
- Happy path last — handle errors/guards first, success at the end. Use early returns; avoid `else`.
- Comments only explain *why*, never *what*. Never comment tests. If code needs a "what" comment, rename or restructure instead.
- No single-letter variables — `$exception` not `$e`, `$request` not `$r`
- `?string` not `string|null`. Always specify `void`. Import classnames everywhere, never inline FQN.
- Validation uses array notation `['required', 'email']` for easier custom rule classes
- Static analysis: run PHPStan at level 8+ (`phpstan analyse --level=8`). Aim for level 9 on new projects. Use `@phpstan-type` and `@phpstan-param` for generic collection types.

## Modern PHP (8.4)

Use these when applicable — do not explain them in comments (Claude and developers know them):
- Readonly classes and properties for immutable data
- Enums with methods and interfaces for domain constants
- Match expressions over switch
- Constructor promotion with readonly
- First-class callable syntax `$fn = $obj->method(...)`
- Fibers for cooperative async when Swoole/ReactPHP not available
- DNF types `(Stringable&Countable)|null` for complex constraints
- Property hooks: `public string $name { get => strtoupper($this->name); set => trim($value); }`
- Asymmetric visibility: `public private(set) string $name` — public read, private write
- `new` without parentheses in chains: `new MyService()->handle()`
- `array_find()`, `array_any()`, `array_all()` — native array search/check without closures wrapping Collection

## Laravel Architecture

- **Fat models, thin controllers** — controllers only: validate, call service/action, return response
- **Service classes** for business logic with readonly DI: `__construct(private readonly PaymentService $payments)`
- **Action classes** (single-purpose invokable) for operations that cross service boundaries
- **Form Requests** for all validation — never validate inline in controllers
- **Events + Listeners** for side effects (notifications, logging, cache invalidation). Do not put side effects in services.
- Feature folder organization over type-based when project exceeds ~20 models

## Eloquent

- `Model::preventLazyLoading(!app()->isProduction())` — catch N+1 during development
- Select only needed columns: `Post::with(['user:id,name'])->select(['id', 'title', 'user_id'])`
- Bulk operations at database level: `Post::where('status', 'draft')->update([...])` — do not load into memory to update
- `increment()`/`decrement()` for counters in a single query
- Composite indexes for common query combinations
- Chunking for large datasets (`chunk(1000)`), lazy collections for memory-constrained processing
- `$guarded = []` is a mass assignment vulnerability — always use explicit `$fillable`

## API Resources

- `whenLoaded()` for relationships — prevents N+1 in responses
- `when()` / `mergeWhen()` for permission-based field inclusion
- `whenPivotLoaded()` for pivot data
- `withResponse()` for custom headers, `with()` for metadata (version, pagination)

## Queues & Jobs

- Job batching with `Bus::batch([...])->then()->catch()->finally()->dispatch()`
- Job chaining for sequential ops: `Bus::chain([new Step1, new Step2])->dispatch()`
- Rate limiting: `Redis::throttle('api')->allow(10)->every(60)->then(fn() => ...)`
- `ShouldBeUnique` interface to prevent duplicate processing
- Always handle failures — implement `failed()` method on jobs

## Testing (PHPUnit)

- RED → verify RED → GREEN → verify GREEN → REFACTOR
- Extend `TestCase`, use `RefreshDatabase` trait
- One assertion focus per test. Test name describes the behavior, not the method.
- `Sanctum::actingAs($user, ['ability'])` for API auth testing
- Run relevant tests first, offer full suite after

## Discipline

- For non-trivial changes, pause and ask: "is there a more elegant way?" Skip for obvious fixes.
- Simplicity first — every change as simple as possible, impact minimal code
- Only touch what's necessary — avoid introducing unrelated changes
- No hacky workarounds — if a fix feels wrong, step back and implement the clean solution

## Production Performance

- **OPcache**: enable in production (`opcache.enable=1`), set `opcache.memory_consumption=256`, `opcache.max_accelerated_files=20000`. Validate with `opcache_get_status()`.
- **JIT**: enable with `opcache.jit_buffer_size=100M`, `opcache.jit=1255` (tracing). Biggest gains on CPU-bound code (math, loops), minimal impact on I/O-bound Laravel requests.
- **Preloading**: `opcache.preload=preload.php` — preload framework classes and hot app classes. Use `composer dumpautoload --classmap-authoritative` in production.
- **Laravel-specific**: `php artisan config:cache && php artisan route:cache && php artisan view:cache && php artisan event:cache` — run on every deploy. `composer install --optimize-autoloader --no-dev` for production.

## Anti-Patterns

- Querying in loops — use eager loading or `whereIn()` instead
- Empty catch blocks — log or rethrow, never swallow
- Business logic in controllers — extract to service/action instead
- `protected $guarded = []` — use `$fillable` instead
- Inline validation in controllers — use Form Requests instead

## References

- [laravel-ecosystem.md](./references/laravel-ecosystem.md) — Notifications, Task Scheduling, Custom Casts
