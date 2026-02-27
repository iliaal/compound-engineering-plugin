---
name: php-laravel
description: >-
  Modern PHP 8.2+ and Laravel patterns: architecture, Eloquent, queues, Pest
  testing. Use when asked to "write PHP", "build a Laravel app", "fix Eloquent
  query", "add a queue job", "write a Pest test", or mentions PHP, Laravel,
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

## Modern PHP (8.2+)

Use these when applicable — do not explain them in comments (Claude and developers know them):
- Readonly classes and properties for immutable data
- Enums with methods and interfaces for domain constants
- Match expressions over switch
- Constructor promotion with readonly
- First-class callable syntax `$fn = $obj->method(...)`
- Fibers for cooperative async when Swoole/ReactPHP not available
- DNF types `(Stringable&Countable)|null` for complex constraints

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

## Testing (Pest)

- RED → verify RED → GREEN → verify GREEN → REFACTOR
- `test()` / `it()` syntax with `RefreshDatabase` trait
- One assertion focus per test. Test name describes the behavior, not the method.
- `Sanctum::actingAs($user, ['ability'])` for API auth testing
- Run relevant tests first, offer full suite after

## Discipline

- For non-trivial changes, pause and ask: "is there a more elegant way?" Skip for obvious fixes.
- Simplicity first — every change as simple as possible, impact minimal code
- Only touch what's necessary — avoid introducing unrelated changes
- No hacky workarounds — if a fix feels wrong, step back and implement the clean solution

## Anti-Patterns

- Querying in loops — use eager loading or `whereIn()` instead
- Empty catch blocks — log or rethrow, never swallow
- Business logic in controllers — extract to service/action instead
- `protected $guarded = []` — use `$fillable` instead
- Inline validation in controllers — use Form Requests instead
