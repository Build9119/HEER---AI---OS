# AGENT-03 — Policy Engine
# Work package: R101-03
# Authorized when: R101-02 VERIFIED by Master

## You are

A scoped implementation agent owning the Policy Engine service and OPA rules.
You do not touch identity/tenant infrastructure (AGENT-02's territory) or any
other service directory. You report to Master only.

## Before writing anything

  git status
  git log --oneline -10
  cat .clinerules   ← read every line, it governs you
  cat docs/ARCHITECTURE.md | grep -A 40 "ADR-101-03"

## Owns

  services/policy-engine/
  policies/           (all .rego files)
  docker-compose.yml  (policy-engine service addition only)
  .github/workflows/ci.yml (add policy-engine test job only)

## Must NOT touch

  infra/              services/ai-registry/    services/mission-engine/
  services/exceptions-node/                    services/audit/
  services/learning-loop/   services/voice-interface/
  console/   libs/   docs/   .clinerules   factory/

## Scope

- [ ] OPA deployed as a service in docker-compose.yml (if not already present
      from R101-00 — check first, don't duplicate).
- [ ] Decision API (Node/TS service): input = {identity, action, resource,
      context}, output = {decision: permit|deny|exception, decision_id,
      policy_version, rationale}.
- [ ] Every decision logged with its decision_id — emit to stdout structured
      JSON for now; the audit service (AGENT-08) will consume it later.
- [ ] At least two real Rego rules in policies/: one financial-limit rule,
      one registry-check rule (deny if agent not in registry — even as a
      stub check until ai-registry exists).
- [ ] Policy change process: PR template addition requiring a named reviewer
      for any change to policies/ directory.
- [ ] Unit tests: permit, deny, and exception cases against the sample rules.
      All three cases must be covered.

## Plan-mode must include

1. Raw git status.
2. Whether OPA is already in docker-compose (from R101-00) — don't add it again.
3. Full decision API request/response shape.
4. Full Rego rule content for both rules (not descriptions — actual code).
5. How decision_id is generated and what format it takes.

## Act-mode evidence required

- Raw test output: all three decision cases (permit/deny/exception) with
  actual request inputs and response JSON shown.
- Raw docker-compose ps confirming policy-engine is (healthy).
- Raw content of both .rego files.
- A sample decision log line showing decision_id, policy_version, rationale.

## Gate acceptance line (docs/PLAN.md Phase 2)

"Decision API returns a correctly-shaped response for permit, deny, and
exception cases against the sample rule; every decision is logged with a
decision_id."
