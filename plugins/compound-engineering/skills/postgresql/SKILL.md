---
name: postgresql
description: >-
  PostgreSQL schema design, query optimization, indexing, and administration.
  Use when writing schemas, queries, migrations, or mentions PostgreSQL,
  Postgres, JSONB, partitioning, RLS, CTEs, window functions, EXPLAIN ANALYZE,
  or connection pooling.
---

# PostgreSQL

## Data Type Defaults

| Need | Use | Avoid |
|------|-----|-------|
| Primary key | `BIGINT GENERATED ALWAYS AS IDENTITY` | `SERIAL`, `BIGSERIAL` |
| Timestamps | `TIMESTAMPTZ` | `TIMESTAMP` (loses timezone) |
| Text | `TEXT` | `VARCHAR(n)` unless constraint needed |
| Money | `NUMERIC(precision, scale)` | `MONEY`, `FLOAT` |
| Boolean | `BOOLEAN` with `NOT NULL DEFAULT` | nullable booleans |
| JSON | `JSONB` | `JSON` (no indexing), text JSON |
| UUID | `gen_random_uuid()` (PG13+) | `uuid-ossp` extension |
| IP addresses | `INET` / `CIDR` | text |
| Ranges | `TSTZRANGE`, `INT4RANGE`, etc. | pair of columns |

## Schema Rules

- Every FK column gets an index (PG does NOT auto-create these)
- `NOT NULL` on every column unless NULL has business meaning
- `CHECK` constraints for domain rules at DB level
- `EXCLUDE` constraints for range overlaps: `EXCLUDE USING gist (room WITH =, during WITH &&)`
- Default `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`
- Separate `updated_at` with trigger, never trust app layer alone
- Use `BIGINT` PKs — cheaper JOINs than UUID, better index locality

## Index Strategy

| Type | Use When |
|------|----------|
| B-tree (default) | Equality, range, sorting, `LIKE 'prefix%'` |
| GIN | JSONB (`@>`, `?`, `?&`), arrays, full-text (`tsvector`) |
| GiST | Geometry, ranges, full-text (smaller but slower than GIN) |
| BRIN | Large tables with natural ordering (timestamps, serial IDs) |

**Index rules:**
- Composite: most selective column first, max 3-4 columns
- Partial: `WHERE status = 'active'` — smaller, faster
- Covering: `INCLUDE (col)` — avoids heap lookup
- Expression: `ON (lower(email))` — for function-based WHERE
- Drop unused indexes: `SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0`

## JSONB Patterns

```sql
-- GIN index for containment queries
CREATE INDEX ON items USING gin (metadata);
SELECT * FROM items WHERE metadata @> '{"status": "active"}';

-- Expression index for specific key access
CREATE INDEX ON items ((metadata->>'category'));
SELECT * FROM items WHERE metadata->>'category' = 'electronics';
```

Prefer typed columns over JSONB for frequently queried, well-structured data. Use JSONB for truly dynamic/variable attributes.

## Query Optimization

- Always `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` before optimizing
- Sequential scan on large table → add index or check `WHERE` for function wrapping
- High `rows removed by filter` → index doesn't match predicate
- `CTE` is an optimization fence before PG12; use `MATERIALIZED`/`NOT MATERIALIZED` hints (PG12+)
- Prefer `EXISTS` over `IN` for correlated subqueries
- Use `LATERAL JOIN` when subquery needs outer row reference
- Cursor pagination (`WHERE id > $last ORDER BY id LIMIT $n`) over `OFFSET`

## Partitioning

Use when table exceeds ~100M rows or needs TTL purge:
- `RANGE` — time-series (by month/year), most common
- `LIST` — categorical (by region, tenant)
- `HASH` — even distribution when no natural key

Partition key must be in every unique/PK constraint. Create indexes on partitions, not parent.

## Transactions & Locking

- Keep transactions short — long txns block vacuum and bloat tables
- `SELECT ... FOR UPDATE SKIP LOCKED` — job queue / work claiming pattern
- Advisory locks for application-level mutual exclusion: `pg_advisory_xact_lock(key)`
- Check blocked queries: `SELECT * FROM pg_stat_activity WHERE wait_event_type = 'Lock'`

## Full-Text Search

```sql
-- Weighted tsvector column with trigger
ALTER TABLE articles ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(title,'')), 'A') ||
    setweight(to_tsvector('english', coalesce(body,'')), 'B')
  ) STORED;
CREATE INDEX ON articles USING gin (search_vector);
SELECT * FROM articles WHERE search_vector @@ websearch_to_tsquery('english', $1);
```

## Performance Tuning

Key `postgresql.conf` parameters (adjust for available RAM):
- `shared_buffers` = 25% of RAM
- `effective_cache_size` = 75% of RAM
- `work_mem` = RAM / max_connections / 4 (start 4-16MB)
- `maintenance_work_mem` = 256MB-1GB
- `random_page_cost` = 1.1 for SSD (default 4.0 is for HDD)

## Connection Pooling

Always pool in production. Direct connections cost ~10MB each.
- PgBouncer in `transaction` mode for most workloads
- `statement` mode if no session-level features (prepared statements, temp tables, advisory locks)

## Maintenance

- `pg_stat_statements` extension — find slow queries by total time, not just duration
- `pg_stat_user_tables` — check `n_dead_tup` for vacuum needs
- `autovacuum` tuning: lower thresholds for hot tables
- Monitor cache hit ratio: `SELECT sum(heap_blks_hit) / sum(heap_blks_hit + heap_blks_read) FROM pg_statio_user_tables` — should be > 99%

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| `SERIAL` / `BIGSERIAL` for PKs | `BIGINT GENERATED ALWAYS AS IDENTITY` |
| No FK indexes | Add index on every FK column |
| `OFFSET` pagination | Cursor-based: `WHERE id > $last` |
| `SELECT *` | List needed columns |
| `TIMESTAMP` without timezone | `TIMESTAMPTZ` |
| Functions in WHERE (`lower(col)`) | Expression index or citext extension |
| Storing structured data as text | `JSONB` with GIN index |
| Long-running transactions | Keep txns short, use `idle_in_transaction_session_timeout` |
