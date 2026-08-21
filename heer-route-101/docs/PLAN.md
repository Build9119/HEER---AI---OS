# HEER ROUTE 101 — implementation plan

Read this before starting any task. Work top to bottom — later phases depend on earlier
ones being VERIFIED, not just IMPLEMENTED.

## Work packages — status

| ID | Work package | Status | Depends on |
|---|---|---|---|
| R101-00 | Repo & tooling baseline | AUTHORIZED | — |
| R101-02 | Identity & tenant model | AUTHORIZED | R101-00 |
| R101-03 | Policy Engine | AUTHORIZED | R101-00 |
| R101-05 | AI Inventory Registry | AUTHORIZED | R101-02 |
| R101-06 | Mission Engine / task graph | AUTHORIZED | R101-02, R101-03, R101-05 |
| R101-04 | Exceptions Node | AUTHORIZED | R101-02, R101-03 |
| R101-07 | Remote worker security | AUTHORIZED | R101-02 |
| R101-08 | Audit / governance correlation | AUTHORIZED | R101-02 |
| R101-11 | Autonomous learning loop | AUTHORIZED (proposal-generation only — see Phase 9) | R101-08 |
| R101-12 | Voice interface & operator console | AUTHORIZED | R101-02, R101-03, R101-08 |
| R101-09 | End-to-end acceptance | BLOCKED | all above VERIFIED |
| R101-10 | ROUTE 101 closure | BLOCKED | R101-09 |

Do not start a BLOCKED package. If a task references one, stop and say so.

## Phase 0 — R101-00: Repo & tooling baseline

Goal: a working local dev loop, nothing governance-specific yet.

- [ ] `docker-compose.yml`: Postgres, OPA (server mode), Redis, Kafka (single-node/redpanda
      is fine for local dev).
- [ ] Root `README.md` with `docker-compose up` instructions.
- [ ] CI skeleton (GitHub Actions): lint + test on every PR, no deploy yet.
- [ ] Shared `libs/` package for correlation-ID propagation (used by every service from
      Phase 1 onward — build this now so nobody reinvents it).

Acceptance: `docker-compose up` brings up all four services healthy; CI runs on a
no-op PR and passes.

## Phase 1 — R101-02: Identity & tenant model

Goal: every principal has a verifiable identity; tenant boundary is enforced at the data layer.

- [ ] Keycloak (or Ory) container + realm config for human/app OIDC identities.
- [ ] SPIFFE/SPIRE server + agent for workload identity issuance (agents/workers).
- [ ] Postgres schema: `tenants`, `businesses`, `agents`, `workers` with the full
      Business → Tenant → Agent → Worker chain as foreign keys — nullable nowhere.
- [ ] Row-level security policies on every tenant-scoped table.
- [ ] `tests/tenant-isolation/`: a test that creates two tenants, seeds data for both,
      and asserts tenant A's connection cannot read/write tenant B's rows even via a
      raw query.

Acceptance: tenant-isolation test suite passes; no table with tenant-scoped data lacks
an RLS policy (write a CI check that fails the build if one is missing).

## Phase 2 — R101-03: Policy Engine

Goal: a Permit/Deny/Exception decision service, nothing calls it yet — that's Phase 3+.

- [ ] OPA deployed as a sidecar-capable service; `policies/` directory with at least
      one real rule (e.g. a financial-limit rule) and one test-only rule.
- [ ] Decision API: input = {identity, action, resource, context}, output =
      {decision: permit|deny|exception, decision_id, policy_version, rationale}.
- [ ] Every decision is logged with its decision_id (feeds Phase 5 audit correlation
      even before that service formally exists — just emit the event now).
- [ ] Policy change process: a PR to `policies/` requires a specific reviewer group
      (document this in the PR template, don't just say it in prose).

Acceptance: decision API returns a correctly-shaped response for permit, deny, and
exception cases against the sample rule; every decision is logged with a decision_id.

## Phase 3 — R101-05: AI Inventory Registry

- [ ] Postgres schema: `agent_registry` with all mandatory fields from
      docs/ARCHITECTURE.md ADR-101-05.
- [ ] Registration API + lookup API.
- [ ] Policy Engine integration: decision API now rejects any request where the
      requesting agent identity has no registry entry, or the entry is stale
      (past its review date).
- [ ] Quarterly-attestation reminder job (can be a stub/cron placeholder for now).

Acceptance: an unregistered agent identity gets a hard Deny from the Policy Engine,
verified by a test.

## Phase 4 — R101-06: Mission Engine / task graph

- [ ] Temporal.io deployed locally.
- [ ] Mission → task graph compiler: takes an intent, produces a versioned, immutable
      DAG of task nodes.
- [ ] Each node execution calls the Policy Engine decision API before running —
      no graph-level blanket authorization.
- [ ] Mid-flight change handling: attempting to mutate a running graph creates a new
      version and re-triggers policy evaluation, proven by a test.

Acceptance: a sample 3-node mission runs end to end, each node's Policy Engine call
is visible in the decision log, and a mid-flight mutation test produces a new graph
version rather than silently patching the running one.

## Phase 5 — R101-04: Exceptions Node

- [ ] Temporal workflow implementing the state machine: Raised → Triaged → Assigned →
      Under Review → Resolved (Approved/Rejected) → Closed.
- [ ] SLA timer per severity tier; breach triggers an escalation signal (stub the
      actual notification channel — Slack/email — behind an interface).
- [ ] Every exception record carries decision_id, policy_version, requesting identity.

Acceptance: an SLA-breach test fires the escalation path; an exception's audit trail
links back to the originating Policy Engine decision_id.

## Phase 6 — R101-07: Remote worker security

- [ ] Workers authenticate to the execution gateway via mTLS using SPIFFE-issued certs.
- [ ] Execution epoch concept: gateway rejects any worker call carrying a stale epoch.
- [ ] Per-tenant rate limiting at the gateway.

Acceptance: a stale-epoch test call is rejected; a noisy-neighbor load test shows one
tenant's traffic doesn't degrade another tenant's latency.

## Phase 7 — R101-08: Audit & governance correlation

- [ ] Kafka topic for execution events; every service from Phase 1 onward publishes
      to it with a shared correlation ID (use the libs/ package from Phase 0).
- [ ] Consumer writing to an append-only, hash-chained store (S3 Object Lock or
      equivalent for local dev).
- [ ] Per-tenant query API over ClickHouse (or Postgres if scale doesn't justify
      ClickHouse yet — note this as a deliberate downgrade, not a silent one).

Acceptance: a full execution (Intent → Outcome) is reconstructable from the audit
store using a single correlation ID; a tamper test (modifying one record) is
detectable via the hash chain.

## Phase 7.5 — R101-11: Autonomous learning loop

Goal: HEER learns from its own history and produces reviewable proposals. It never
writes a live change to policy, task-graph templates, or its own registry entry.
See docs/ARCHITECTURE.md ADR-101-11 for the binding design.

- [ ] Learning Pipeline service consuming from the audit event stream (R101-08) and
      Exceptions Node resolutions (R101-04) — read-only access to both, no write path
      back into either.
- [ ] Obsidian memory store: pattern library for VERIFIED, successful mission
      templates, keyed with provenance (correlation IDs it was learned from).
- [ ] Policy-tuning-suggestion generator: analyzes exception patterns (e.g. false-
      positive rate per rule) and produces a proposal artifact — a draft diff against
      a policies/ file, opened as a PR, never auto-merged.
- [ ] Agent-performance-feedback job: writes to the AI Inventory Registry's
      "flagged for early review" field only — never changes an agent's risk tier or
      deploys a new model version itself.
- [ ] Every proposal artifact includes a provenance block: source correlation IDs,
      date range, and the specific pattern that triggered the suggestion. A
      proposal without provenance is rejected by CI before it reaches a human
      reviewer.
- [ ] No fine-tuning or weight update job runs against live tenant data without a
      per-tenant consent flag checked first (query the AI Inventory Registry entry;
      fail closed if the flag is absent).

Acceptance: a synthetic test where the pipeline is fed a known exception pattern
produces a correctly-provenanced policy-change PR — and a separate test proves the
pipeline has no code path capable of writing directly to policies/, task-graph
templates, or the registry's risk-tier/model-version fields.

## Phase 7.75 — R101-12: Voice interface & operator console

Goal: the console people actually use, voice-first, with zero authority of its own.
See docs/ARCHITECTURE.md ADR-101-12 and docs/SKILLS.md for the binding design and
required skill catalog.

- [ ] STT/TTS integration behind a swappable interface (no vendor hardcoded into
      business logic).
- [ ] Wake-word capture runs client-side only; verify with a network trace that no
      raw audio leaves the client except the already-transcribed command text.
- [ ] Every voice command constructs the same {identity, action, resource, context}
      shape as any other channel and calls the same Policy Engine decision API —
      no separate "voice path" through the code.
- [ ] Spoken-confirmation step implemented for all Control-class skills (see
      docs/SKILLS.md) before execution.
- [ ] Console UI (the HTML/React operator dashboard) wired to live services instead
      of the mocked data in the initial prototype.
- [ ] Skill registry: each skill in docs/SKILLS.md's initial catalog gets a real
      AI Inventory Registry entry before it's reachable by voice.

Acceptance: a test proves a voice command and an equivalent API call for the same
action produce identical Policy Engine decisions (same input shape, same result);
a Control-class skill invoked by voice is blocked until the confirmation step
completes; a Gated skill invoked by voice returns an Exception, not an execution.

## Phase 8 — R101-09 / R101-10

Do not start until every phase above is VERIFIED (not just implemented) per
docs/ARCHITECTURE.md's status vocabulary. This is an end-to-end acceptance and
closure pass — request explicit instructions before beginning.

## What "done" means for any task in this plan

Per .clinerules: implemented ≠ tested ≠ verified. A task is only reportable as done
when its Acceptance line above is demonstrably true, not when the code compiles.
