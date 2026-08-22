# AGENT-07 — Remote Worker Security Baseline
# Work package: R101-07
# Authorized when: R101-02 VERIFIED by Master
# (can run in parallel with AGENT-03 and AGENT-08)

## Owns

  services/audit/worker-security/   (create this subdirectory)
  infra/spire/                       (extend only — don't re-create)
  docker-compose.yml                 (execution-gateway service addition only)
  .github/workflows/ci.yml           (add worker-security test job only)

## Must NOT touch

  services/policy-engine/   services/ai-registry/   services/mission-engine/
  services/exceptions-node/   services/learning-loop/   services/voice-interface/
  console/   libs/   docs/   .clinerules   factory/

## Scope

- [ ] Execution gateway service: all worker calls pass through it. The
      gateway rejects any worker not presenting a valid SPIFFE-issued cert.
- [ ] Execution epoch: every active execution has an epoch ID. Workers
      must present the current epoch ID on every call. Gateway rejects
      stale-epoch calls (epoch mismatch = hard reject, logged).
- [ ] Per-tenant rate limiting at the gateway: one tenant's traffic cannot
      degrade another's. Configurable limit per tenant, fail-open=false
      (deny on limit breach, not pass-through).
- [ ] mTLS between gateway and workers — enforced, not optional.

## Critical tests

1. Stale-epoch test: worker calls gateway with an old epoch ID — confirm
   hard rejection with a logged reason.
2. Noisy-neighbor test: saturate one tenant's rate limit, confirm a second
   tenant's requests continue to succeed at normal latency.

Raw test output for both.
