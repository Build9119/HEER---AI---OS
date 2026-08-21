# AGENT-04 — Exceptions Node
# Work package: R101-04
# Authorized when: R101-02 + R101-03 VERIFIED by Master
# (can run in parallel with AGENT-06)

## Owns

  services/exceptions-node/
  docker-compose.yml (exceptions-node service addition only)
  .github/workflows/ci.yml (add exceptions-node test job only)

## Must NOT touch

  infra/   policies/   services/policy-engine/   services/ai-registry/
  services/mission-engine/   services/audit/   services/learning-loop/
  services/voice-interface/   console/   libs/   docs/   .clinerules   factory/

## Scope

- [ ] Temporal workflow implementing the exception state machine:
      Raised → Triaged → Assigned → Under Review → Resolved
      (Approved | Rejected) → Closed.
      States are explicit — no implicit transitions, no skipped states.
- [ ] Every exception record carries: exception_id, originating decision_id
      (from Policy Engine), policy_version evaluated, requesting_identity,
      tenant_id, severity (low/medium/high/critical), raised_at, sla_deadline.
- [ ] SLA clock per severity: critical=1h, high=4h, medium=24h, low=72h.
      SLA breach triggers an escalation signal — stub the notification
      channel behind an interface (don't hardcode Slack/email).
- [ ] API: POST /exceptions (raise), GET /exceptions/:id, PATCH
      /exceptions/:id/transition (move state with required fields).

## Critical tests (Gate acceptance line, docs/PLAN.md Phase 5)

1. An SLA-breach test: raise a high-severity exception, fast-forward the
   clock past 4 hours, confirm the escalation signal fires.
2. An audit-trail test: raise an exception and confirm its record contains
   a valid decision_id that links back to a Policy Engine decision.

Both in raw test output.

## Act-mode evidence required

- Raw test output for both critical tests.
- Raw POST /exceptions request + response.
- Raw state transition sequence for one exception (all states, raw API calls).
- Raw DB query showing exception record with decision_id populated.
