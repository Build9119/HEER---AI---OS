# AGENT-08 — Audit & Governance Correlation
# Work package: R101-08
# Authorized when: R101-02 VERIFIED by Master
# (can run in parallel with AGENT-03 and AGENT-07)

## Owns

  services/audit/
  docker-compose.yml (audit consumer + ClickHouse/Postgres additions only)
  .github/workflows/ci.yml (add audit test job only)

## Must NOT touch

  services/policy-engine/   services/ai-registry/   services/mission-engine/
  services/exceptions-node/   services/learning-loop/   services/voice-interface/
  console/   infra/spire/   libs/   docs/   .clinerules   factory/

## Scope

- [ ] Kafka consumer (Redpanda, already in docker-compose) reading execution
      events from all services — each event carries a correlation_id from
      libs/correlation-id.
- [ ] WORM-pattern, append-only audit store: hash-chain each record to the
      previous one. Local dev: write to Postgres with a trigger that prevents
      UPDATE/DELETE. Production path: S3 Object Lock — document this gap
      explicitly in your report, don't pretend Postgres WORM = S3 WORM.
- [ ] Per-tenant query API: GET /audit?tenant_id=X&correlation_id=Y —
      returns the full Intent → Outcome chain for one execution. Must not
      expose records from other tenants even if correlation_id is known.
- [ ] Tamper-detection job: re-hashes the chain on demand and reports any
      broken link.

## Critical tests (Gate acceptance line, docs/PLAN.md Phase 7)

1. Reconstruction test: emit a synthetic 3-step execution (intent, task,
   outcome events) with a shared correlation_id. Query /audit with that ID
   and confirm all three steps are returned in order.
2. Tamper test: manually modify one audit record in the DB, run the tamper-
   detection job, confirm it reports the broken link.
3. Cross-tenant isolation test: query /audit with tenant A's correlation_id
   using tenant B's credentials — confirm zero records returned.

All three in raw test output.

## Act-mode evidence required

- Raw output of all three tests.
- Raw audit record JSON showing hash_chain_link field.
- Raw query result for reconstruction test (all 3 steps visible).
- Explicit note on Postgres WORM vs S3 Object Lock gap.
