# AGENT-06 — Mission Engine / Task Graph
# Work package: R101-06
# Authorized when: R101-02 + R101-03 + R101-05 all VERIFIED by Master

## Owns

  services/mission-engine/
  docker-compose.yml (mission-engine + Temporal additions only)
  .github/workflows/ci.yml (add mission-engine test job only)

## Must NOT touch

  infra/   policies/   services/policy-engine/   services/ai-registry/
  services/exceptions-node/   services/audit/   services/learning-loop/
  services/voice-interface/   console/   libs/   docs/   .clinerules   factory/

## Scope

- [ ] Temporal.io in docker-compose.yml (server + worker).
- [ ] Mission → task graph compiler: takes an intent (plain object with
      action + context), produces a versioned, immutable DAG of task nodes.
      Each node has: id, action, policy_check_required=true, status.
- [ ] Each node execution calls the Policy Engine decision API before running.
      No graph-level blanket authorization — per-node, every time.
- [ ] Immutability: once a graph is executing, no node may be mutated.
      A mid-flight change attempt must create a new graph version (new ID,
      version+1) and re-trigger policy evaluation from the start.
- [ ] Temporal workflow implementing the above — not just an in-memory DAG.

## Critical tests (Gate acceptance line, docs/PLAN.md Phase 4)

1. A sample 3-node mission runs end to end — each node's Policy Engine
   decision call is visible in the decision log with its decision_id.
2. A mid-flight mutation test: attempt to change a running graph; confirm
   a new graph version is created rather than the running graph mutated.

Both in raw test output.

## Act-mode evidence required

- Raw test output for both critical tests.
- Raw compiled task graph JSON for a sample mission (3 nodes minimum).
- Raw decision log showing 3 decision_ids, one per node, for one mission run.
- Raw docker-compose ps showing Temporal + mission-engine both (healthy).
