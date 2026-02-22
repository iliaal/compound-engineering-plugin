---
name: react-frontend
description: React, TypeScript, and Next.js patterns for frontend development. Use when building React components, managing state, fetching data, optimizing performance, or working with Next.js App Router. Covers React 18-19, hooks, Server Components, and type-safe patterns.
---

# React Frontend

## Component TypeScript

- Extend native elements with `ComponentPropsWithoutRef<'button'>`, add custom props via intersection
- Use `React.ReactNode` for children, `React.ReactElement` for single element, render prop `(data: T) => ReactNode`
- Discriminated unions for variant props — TypeScript narrows automatically in branches
- Generic components: `<T>` with `keyof T` for column keys, `T extends { id: string }` for constraints
- Event types: `React.MouseEvent<HTMLButtonElement>`, `FormEvent<HTMLFormElement>`, `ChangeEvent<HTMLInputElement>`
- `as const` for custom hook tuple returns
- `useRef<HTMLInputElement>(null)` for DOM (use `?.`), `useRef<number>(0)` for mutable values
- Explicit `useState<User | null>(null)` for unions/null
- useReducer actions as discriminated unions: `{ type: 'set'; payload: number } | { type: 'reset' }`
- useContext null guard: throw in custom `useX()` hook if context is null

## Effects Decision Tree

Effects are escape hatches — most logic should NOT use effects.

| Need | Solution |
|------|----------|
| Derived value from props/state | Calculate during render (useMemo if expensive) |
| Reset state on prop change | `key` prop on component |
| Respond to user event | Event handler |
| Notify parent of state change | Call onChange in event handler, or fully controlled component |
| Chain of state updates | Calculate all next state in one event handler |
| Sync with external system | Effect with cleanup |

**Effect rules:**
- Never suppress the linter — fix the code instead
- Use updater functions (`setItems(prev => [...prev, item])`) to remove state dependencies
- Move objects/functions inside effects to stabilize dependencies
- `useEffectEvent` for non-reactive values (e.g., theme in a connection effect)
- Always return cleanup for subscriptions, connections, listeners
- Data fetching: use `ignore` flag pattern or React Query

## State Management

```
Local UI state       → useState, useReducer
Shared client state  → Zustand (simple) | Redux Toolkit (complex)
Atomic/granular      → Jotai
Server/remote data   → React Query (TanStack Query)
URL state            → nuqs, router search params
Form state           → React Hook Form
```

**Key patterns:**
- Zustand: `create<State>()(devtools(persist((set) => ({...}))))` — use slices for scale, selective subscriptions to prevent re-renders
- React Query: query keys factory (`['users', 'detail', id] as const`), `staleTime`/`gcTime`, optimistic updates with `onMutate`/`onError` rollback
- Separate client state (Zustand) from server state (React Query) — never duplicate server data in client store
- Colocate state close to where it's used; don't over-globalize

## Performance

**Critical — eliminate waterfalls:**
- `Promise.all()` for independent async operations
- Move `await` into branches where actually needed
- Suspense boundaries to stream slow content

**Critical — bundle size:**
- Import directly from modules, avoid barrel files (`index.ts` re-exports)
- `next/dynamic` or `React.lazy()` for heavy components
- Defer third-party scripts (analytics, logging) until after hydration
- Preload on hover/focus for perceived speed

**Re-render optimization:**
- Derive state during render, not in effects
- Subscribe to derived booleans, not raw objects (`state.items.length > 0` not `state.items`)
- Functional setState for stable callbacks: `setCount(c => c + 1)`
- Lazy state init: `useState(() => expensiveComputation())`
- `useTransition` for non-urgent updates (search filtering)
- `useDeferredValue` for expensive derived UI
- Use ternary (`condition ? <A /> : <B />`), not `&&` for conditionals
- `React.memo` only for expensive subtrees with stable props
- Hoist static JSX outside components

**React Compiler** (React 19): auto-memoizes — write idiomatic React, remove manual `useMemo`/`useCallback`/`memo`. Install `babel-plugin-react-compiler`, keep components pure.

## React 19

- **ref as prop** — `forwardRef` deprecated. Accept `ref?: React.Ref<HTMLElement>` as regular prop
- **useActionState** — replaces `useFormState`: `const [state, formAction, isPending] = useActionState(action, initialState)`
- **use()** — unwrap Promise or Context during render (not in callbacks/effects). Enables conditional context reads
- **useOptimistic** — `const [optimistic, addOptimistic] = useOptimistic(state, mergeFn)` for instant UI feedback
- **useFormStatus** — `const { pending } = useFormStatus()` in child of `<form action={...}>`
- **Server Components** — default in App Router. Async, access DB/secrets directly. No hooks, no event handlers
- **Server Actions** — `'use server'` directive. Validate inputs (Zod), `revalidateTag`/`revalidatePath` after mutations

## Next.js App Router

**File conventions:** `page.tsx` (route UI), `layout.tsx` (shared wrapper), `loading.tsx` (Suspense), `error.tsx` (error boundary), `not-found.tsx` (404), `route.ts` (API endpoint)

**Rendering modes:** Server Components (default) | Client (`'use client'`) | Static (build) | Dynamic (request) | Streaming (progressive)

**Decision:** Server Component unless it needs hooks, event handlers, or browser APIs. Split: server parent + client child.

**Routing patterns:**
- Route groups `(name)` — organize without affecting URL
- Parallel routes `@slot` — independent loading states in same layout
- Intercepting routes `(.)` — modal overlays with full-page fallback

**Caching:**
- `fetch(url, { cache: 'force-cache' })` — static
- `fetch(url, { next: { revalidate: 60 } })` — ISR
- `fetch(url, { cache: 'no-store' })` — dynamic
- Tag-based: `fetch(url, { next: { tags: ['products'] } })` then `revalidateTag('products')`

**Data fetching:** Fetch in Server Components where data is used. Use Suspense boundaries for slow queries. `React.cache()` for per-request dedup. `generateStaticParams` for static generation. `generateMetadata` for dynamic SEO.

## Discipline

- For non-trivial changes, pause and ask: "is there a more elegant way?" Skip for obvious fixes.
- Simplicity first — every change as simple as possible, impact minimal code
- Only touch what's necessary — avoid introducing unrelated changes
- No hacky workarounds — if a fix feels wrong, step back and implement the clean solution
