---
name: testing-laravel
description: >-
  Writes Laravel tests using PHPUnit. Use when "write tests", "add tests",
  "phpunit", "laravel test", "feature test", "unit test", "mock", "factory",
  or testing controllers, models, services, actions, jobs, artisan commands,
  or API endpoints.
---

# Testing Laravel

Use PHPUnit with Laravel's testing helpers. Every test file starts with `declare(strict_types=1)`.

## Test Classification

- **Feature tests** (`tests/Feature/`): HTTP requests through the full stack — routes, controllers, middleware, validation, database. Use `$this->getJson()`, `$this->postJson()`, etc.
- **Unit tests** (`tests/Unit/`): Isolated logic — services, actions, value objects, helpers. No HTTP, minimal database.

Default to feature tests for anything touching routes, controllers, or models. Use unit tests for pure logic and action classes.

## Critical Rules

- `use RefreshDatabase` trait in every test class that touches the database
- Model factories for all test data — use factories instead of raw `DB::table()` inserts
- One behavior per test method. Name with `test_` prefix: `test_user_can_update_own_profile`
- Assert both response status AND side effects (DB state, dispatched jobs, sent notifications)
- `actingAs($user)` for auth — use this instead of manually setting sessions or tokens
- `postJson()` / `getJson()` for API endpoints — sets proper Accept headers and returns JSON assertions
- Fake facades BEFORE the action: `Queue::fake()` then act then `Queue::assertPushed(...)`
- `assertDatabaseHas` / `assertDatabaseMissing` to verify persistence — use these instead of re-querying
- Resolve action classes from the container with `resolve()` so DI works; use `swap()` to inject mocks
- **Tests expose bugs, not the reverse**: If a test uncovers broken or buggy behavior, highlight the issue and propose a fix to the source code. Never adjust the test to match incorrect behavior.

## PHPUnit Essentials

```php
<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\{User, Post};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class PostTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_create_post(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->postJson('/api/posts', ['title' => 'New Post', 'body' => 'Content']);

        $response->assertCreated()
            ->assertJson(['data' => ['title' => 'New Post']]);

        $this->assertDatabaseHas('posts', [
            'title' => 'New Post',
            'user_id' => $user->id,
        ]);
    }
}
```

Data providers for boundary/validation testing:

```php
#[DataProvider('titleLengthProvider')]
public function test_validates_title_length(string $title, bool $valid): void
{
    $user = User::factory()->create();
    $response = $this->actingAs($user)
        ->postJson('/api/posts', ['title' => $title, 'body' => 'Content']);

    $valid ? $response->assertCreated() : $response->assertUnprocessable();
}

public static function titleLengthProvider(): array
{
    return [
        'too short' => ['AB', false],
        'minimum valid' => ['ABC', true],
        'maximum valid' => [str_repeat('A', 255), true],
        'too long' => [str_repeat('A', 256), false],
    ];
}
```

See [feature testing patterns](references/feature-testing.md) for auth, validation, API, console, and DB assertions.

See [mocking and faking](references/mocking-and-faking.md) for facade fakes (Queue, Event, Notification, Mail, Storage, Http), action mocking with `swap()`, and Mockery.

See [factories](references/factories.md) for states, relationships, sequences, and afterCreating hooks.

## Running Tests

For large test suites, call PHPUnit directly to avoid artisan's memory overhead:

```bash
./vendor/bin/phpunit                              # all tests (direct, lower memory)
./vendor/bin/phpunit --filter=PostTest             # by name
./vendor/bin/phpunit --processes=auto              # parallel (PHPUnit 11+)
./vendor/bin/phpunit --coverage-text --min=80      # with coverage threshold

php artisan test                                   # small suites or quick runs
php -d memory_limit=1G artisan test                # if artisan needed on large suites
```
