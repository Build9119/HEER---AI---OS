# AGENT-11 — Autonomous Learning Loop
# Work package: R101-11
# Authorized when: R101-08 + R101-04 VERIFIED by Master

## Owns

  services/learning-loop/
  docker-compose.yml (learning-loop service addition only)
  .github/workflows/ci.yml (add learning-loop test job only)

## Must NOT touch

  policies/           ← read only — learning-loop PROPOSES changes here,
                        never writes them directly. A PR is the write path.
  services/ai-registry/ (risk_tier and model_version fields) ← read only
  services/mission-engine/ (task-graph templates) ← read only
  console/   infra/   libs/   docs/   .clinerules   factory/

## Core constraint (ADR-101-11 — non-negotiable)

The learning-loop service has NO write path into policies/, task-graph
templates, or an agent's risk_tier/model_version fields. It produces
proposal artifacts only. A proposal is a structured JSON file written to
proposals/ directory with provenance (source correlation_ids, date range,
pattern description). A human (Master) turns a proposal into a PR.

If you find yourself writing code that directly updates a policy file, a
task-graph template, or a registry risk_tier field: STOP. That is an ADR
violation. Report it to Master instead of implementing it.

## Scope

- [ ] Kafka consumer reading from the audit event stream (R101-08) and
      exception resolution events (R101-04 output topic).
- [ ] Pattern detector: identifies exception patterns (e.g. a specific
      policy rule generating >30% false-positive exceptions over 7 days).
- [ ] Proposal generator: writes a JSON proposal file to proposals/ with:
      - proposal_id, generated_at
      - source_correlation_ids (array — minimum 3, no provenance = rejected)
      - pattern_description (plain English)
      - suggested_change (structured diff against the target artifact)
      - target (policy rule name, or task-graph template ID)
      - confidence (0.0–1.0)
- [ ] CI check: any proposal file missing source_correlation_ids fails the
      build — enforce this in the CI pipeline.
- [ ] Agent performance feedback: reads Registry entries and writes to
      a separate flagged_for_review table — NOT to agent_registry.risk_tier
      directly. The flag is "this agent's exception rate is elevated,
      suggest early re-attestation."

## Critical tests

1. Provenance test: feed synthetic audit events, run the pipeline, confirm
   a proposal file is generated WITH source_correlation_ids populated.
2. No-write test: prove the service has no code path that writes directly
   to policies/, task-graph templates, or agent_registry.risk_tier.
   (A grep-based CI check counts as evidence — show its output.)
3. Missing-provenance rejection test: generate a proposal without
   source_correlation_ids, confirm CI fails.
