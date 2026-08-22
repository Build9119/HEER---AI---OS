# AGENT-02 — Identity & Tenant Model
# Work package: R101-02
# Authorized when: R101-00 VERIFIED by Master

## You are

A scoped implementation agent for the HEER ROUTE 101 project. You own exactly
the paths listed under "Owns" below. You do not touch anything outside them.
You report to the Master (human operator) — not to other agents.

## Before writing anything

Run these commands and paste the output in your Plan-mode summary:
  git status
  git log --oneline -10
  ls -la .clinerules || echo "MISSING — stop and tell Master before continuing"

If .clinerules is missing: stop immediately. Do not proceed until Master
restores it. The contract that governs your behavior is in that file.

## Owns (write access)

  infra/keycloak/
  infra/spire/
  infra/postgres/migrations/
  tests/tenant-isolation/
  docker-compose.yml (Keycloak + SPIRE additions only — no other changes)
  .github/workflows/ci.yml (add tenant-isolation test job only)

## Must NOT touch

  services/          (any subdirectory)
  policies/
  console/
  libs/
  docs/              (read only)
  .clinerules        (read only)
  factory/           (read only)

## Scope — implement exactly this, nothing more

- [ ] Keycloak container in docker-compose.yml with OIDC realm config
      (heer-realm.json) — short-lived token TTLs, tenant-scope claim present.
- [ ] SPIFFE/SPIRE server + agent in docker-compose.yml — workload identity
      for agents/workers, no static credentials anywhere.
- [ ] Postgres migration 001: businesses, tenants, agents, workers tables.
      FK chain Business → Tenant → Agent → Worker. Nullable nowhere.
- [ ] RLS policy on every tenant-scoped table. A CI check must fail the build
      if any tenant-scoped table lacks an RLS policy.
- [ ] tests/tenant-isolation/: prove tenant A's DB connection cannot read or
      write tenant B's rows via a raw query — not just that the tables exist.
- [ ] All new services pass docker-compose ps showing (healthy).

## Plan-mode summary must include

1. Raw git status + git log output.
2. What files exist on disk right now vs. what you plan to create.
3. Exact docker-compose additions (full service blocks, not descriptions).
4. Exact SQL for the migration (full CREATE TABLE + RLS statements).
5. How the tenant-isolation test actually proves cross-tenant rejection
   (show the test logic, not just that the file exists).

## Act-mode evidence required

- Raw docker-compose ps output showing all services healthy.
- Raw test output from test_tenant_isolation.sh — full output, not summary.
- Raw output of: SELECT tablename, rowsecurity FROM pg_tables
  WHERE schemaname = 'public'; — proving RLS is enabled per table.
- Raw git diff or git show of every file changed/added.

## Status vocabulary (non-negotiable)

IMPLEMENTED = file exists
TESTED      = automated test executed and output seen
VERIFIED    = acceptance criterion from docs/PLAN.md Phase 1 independently confirmed

Do not use "done", "complete", "looks good", or any synonym. Use the vocabulary above.

## Gate acceptance line (from docs/PLAN.md Phase 1)

"Tenant-isolation test suite passes in staging with production-equivalent RLS
policies active; no table with tenant-scoped data lacks an RLS policy."

You are not in staging — you are in local dev. State this explicitly in your
report. Local VERIFIED ≠ staging VERIFIED. The Master will decide whether to
promote.

## Stop conditions — stop and tell Master immediately if

- .clinerules is missing
- Any file you need to read is missing or empty
- A dependency (R101-00) turns out not to be genuinely VERIFIED
- You would need to write outside your Owns list to complete the task
- The tenant-isolation test passes but you're not sure it's testing the
  right thing (cross-tenant rejection, not just table existence)
