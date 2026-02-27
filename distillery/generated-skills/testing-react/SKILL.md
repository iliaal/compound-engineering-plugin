---
name: testing-react
description: Writes React/TypeScript tests using Vitest and React Testing Library. Use when "write react tests", "vitest", "component test", "hook test", "RTL", "testing library", "snapshot test", or testing React components, hooks, and utilities.
---

## Test Classification

| Type | Tool | Target | File pattern |
|------|------|--------|-------------|
| Unit | Vitest | Pure functions, utilities, services | Co-located `*.test.ts` |
| Component | Vitest + RTL | React components | Co-located `*.test.tsx` |
| Hook | Vitest + RTL | Custom hooks | Co-located `*.test.ts` |
| E2E | Playwright | User flows, critical paths | Separate `e2e/` directory |

Default to component tests for React components. Unit tests for pure functions and service classes. See [e2e-testing](references/e2e-testing.md) for Playwright patterns.

## Setup

Vitest config: `environment: 'jsdom'`, `globals: true`, `setupFiles` pointing to a file that imports `@testing-library/jest-dom/vitest`. Use `@vitejs/plugin-react` and mirror path aliases from `tsconfig.json`.

## Critical Rules

- **Query priority**: `getByRole` > `getByLabelText` > `getByPlaceholderText` > `getByText` > `getByTestId`. Use `data-testid` only when no accessible query works.
- **Mock boundaries**: Mock API services, navigation, and external providers. Render child components and UI libraries real for integration confidence.
- **One behavior per test** with AAA structure. Name tests `should <behavior> when <condition>`.
- **Async**: Use `findBy*` for async elements, `waitFor` after state-triggering actions, `vi.useFakeTimers()` for debounce/timer logic.
- **User events**: Prefer `userEvent` over `fireEvent` for realistic interactions.
- **Cleanup**: `vi.clearAllMocks()` in `beforeEach`. Recreate test state per test instead of sharing mutable variables.
- **Incremental workflow**: When testing a directory, process one file at a time (simplest first). Run and verify each before proceeding.
- **Tests expose bugs, not the reverse**: If a test uncovers broken or buggy behavior, highlight the issue and propose a fix to the source code. Never adjust the test to match incorrect behavior.

## Component Test

```tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

vi.mock('@/api/client');

describe('UserForm', () => {
  beforeEach(() => { vi.clearAllMocks(); });

  it('should submit valid form data', async () => {
    const onSubmit = vi.fn();
    render(<UserForm onSubmit={onSubmit} />);

    await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com');
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith(
        expect.objectContaining({ email: 'test@example.com' }),
      );
    });
  });
});
```

## Hook Test

```typescript
import { renderHook, act } from '@testing-library/react';

it('should debounce value updates', () => {
  vi.useFakeTimers();
  const { result, rerender } = renderHook(
    ({ value }) => useDebounce(value, 300),
    { initialProps: { value: 'initial' } },
  );
  rerender({ value: 'updated' });
  expect(result.current).toBe('initial');
  act(() => { vi.advanceTimersByTime(300); });
  expect(result.current).toBe('updated');
  vi.useRealTimers();
});
```

## Mocking Patterns

```typescript
// Service mock — mock the module, not the transport layer
vi.mock('@/server-api/me/me.service', () => ({
  MeService: { retrieveMe: vi.fn() },
}));

// QueryClient wrapper for components using TanStack Query
const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};
render(<Component />, { wrapper: createWrapper() });
```

## Running Tests

```bash
npx vitest                         # Watch mode
npx vitest run                     # Single run (CI)
npx vitest run src/features/       # Test specific directory
npx vitest --coverage              # Coverage report
```
