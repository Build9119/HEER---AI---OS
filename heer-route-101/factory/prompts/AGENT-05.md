# AGENT-05 — AI Inventory Registry
# Work package: R101-05
# Authorized when: R101-02 VERIFIED + R101-03 VERIFIED by Master

## Owns

  services/ai-registry/
  docker-compose.yml (ai-registry service addition only)
  .github/workflows/ci.yml (add ai-registry test job only)

## Must NOT touch

  infra/   policies/   services/policy-engine/   services/mission-engine/
  services/exceptions-node/   services/audit/   services/learning-loop/
  services/voice-interface/   console/   libs/   docs/   .clinerules   factory/

## Scope

- [ ] Registration API: POST /agents — creates a registry entry with all
      mandatory fields from ADR-101-05: owner, purpose, tenant_scope,
      model_version, risk_tier (NIST AI RMF mapped: minimal/limited/high),
      data_classes_touched, human_oversight_level, last_review_date.
      Nullable nowhere. Tenant-scoped (RLS from R101-02 applies).
- [ ] Lookup API: GET /agents/:id and GET /agents?tenant_id=X.
- [ ] Policy Engine integration: the Policy Engine (AGENT-03's decision API)
      must reject any request from an unregistered agent identity. Wire this
      as a call from the decision API to the registry lookup — or a shared
      Postgres query if both services share the DB. Document which approach
      and why.
- [ ] Quarterly attestation stub: a scheduled job (cron or Temporal stub)
      that flags entries where last_review_date > 90 days. Does not need to
      send notifications — just mark the entry as stale in the DB.
- [ ] Unit + integration tests: an unregistered agent identity must receive
      a hard Deny from the Policy Engine — prove it with a test.

## Critical test (Gate acceptance line, docs/PLAN.md Phase 3)

"An unregistered agent identity gets a hard Deny from the Policy Engine,
verified by a test."

The test must: register an agent, prove it gets Permit; then use a different,
unregistered identity and prove it gets Deny. Both cases in raw test output.

## Act-mode evidence required

- Raw test output showing both cases (registered=Permit, unregistered=Deny).
- Raw POST /agents request + response showing all mandatory fields.
- Raw GET /agents/:id response.
- Raw DB query: SELECT id, owner, risk_tier, last_review_date,
  is_stale FROM agent_registry LIMIT 5;
