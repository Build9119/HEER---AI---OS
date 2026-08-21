# tenant-isolation tests

Every tenant-scoped table needs a test here proving cross-tenant reads/writes are
rejected by RLS, not just application logic. See docs/PLAN.md Phase 1 acceptance.
