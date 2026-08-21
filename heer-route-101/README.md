# HEER — ROUTE 101

AI Agency Operating Partner. Governance-first architecture: identity, policy,
orchestration, and audit as first-class services — see docs/ARCHITECTURE.md for
the binding decisions and docs/PLAN.md for the build order.

## For Cline / any coding agent

Read `.clinerules` first — it's binding, not a suggestion. Then `docs/ARCHITECTURE.md`,
`docs/PLAN.md`, and `docs/ROADMAP.md`. Only work on packages marked AUTHORIZED in
PLAN.md's status table, and never treat PLAN.md's acceptance criteria as sufficient
for production — check ROADMAP.md's five gates before anything ships to real traffic.

## Local dev

```bash
docker-compose up -d
docker-compose ps   # postgres, opa, redis, redpanda should all be healthy
```

- Postgres: localhost:5432 (user: heer / pass: heer_dev_only — dev only, never reuse)
- OPA: localhost:8181
- Redis: localhost:6379
- Redpanda (Kafka-compatible): localhost:9092

## Repo layout

```
.clinerules              # binding rules for coding agents — read this first
docs/
  ARCHITECTURE.md        # condensed, implementation-facing architecture reference (the ADRs)
  PLAN.md                # phased build order with per-phase acceptance criteria
  ROADMAP.md              # production gates, ownership, environments, rollback policy, milestones
  SKILLS.md                # required voice-skill catalog (ADR-101-13)
  STACK.md               # recommended technology stack with rationale
console/
  heer-console.html      # voice-first operator dashboard prototype (mocked data)
services/
  policy-engine/         # R101-03
  ai-registry/            # R101-05
  exceptions-node/        # R101-04
  mission-engine/         # R101-06
  audit/                  # R101-08
  learning-loop/          # R101-11 — proposal-only autonomous learning
  voice-interface/        # R101-12 — STT/TTS gateway, no elevated authority
policies/                # OPA/Rego rules — never inline policy in service code
tests/
  tenant-isolation/       # cross-tenant access tests, required for every tenant-scoped table
infra/                    # IaC (Terraform, k8s manifests) — added from Phase 6 onward
```

## Status

Fresh baseline, Phase 0 (R101-00) not yet started. See docs/PLAN.md.
