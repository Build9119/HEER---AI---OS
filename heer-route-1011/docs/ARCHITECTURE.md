# HEER ROUTE 101 — architecture reference (condensed for implementation)

Full governance document: HEER_ROUTE_101_MASTER_ARCHITECTURE.docx (source of truth for
rationale and industry-standard mapping). This file is the implementation-facing summary
Cline reads every session — keep it in sync if the master doc changes.

## System identity

HEER = governance + orchestration + memory. Subordinate components: JARVIS (executor),
Hermes (action keeper), Obsidian (memory). These are never independently addressable —
every action routes through HEER governance first.

## Approved architecture decisions (binding)

### ADR-101-02 — Identity & tenant model
- Every principal (human, agent, worker) has a globally unique OIDC identity.
- Agent/worker identities are short-lived (max 24h), SPIFFE/SPIRE-issued, never static keys.
- Tenancy chain is mandatory on every resource: Business → Tenant → Agent → Worker →
  Execution → Memory.
- Cross-tenant access denied by default at the data layer (Postgres RLS), not just the API.

### ADR-101-03 — Policy Engine
- OPA/Rego, standalone service, synchronous and blocking.
- Every policy: owner, industry-overlay tag, version, rationale field.
- No execution proceeds without a recorded Permit decision + decision ID.
- Policy changes go through Master Approval — never hot-patched.

### ADR-101-04 — Exceptions Node
- Exception = first-class object with its own ID and state machine, not a log line.
- States: Raised → Triaged → Assigned → Under Review → Resolved (Approved/Rejected) → Closed.
- Carries: originating decision ID, policy version evaluated, requesting identity.
- SLA clock per severity tier; breach = automatic escalation.

### ADR-101-05 — AI Inventory Registry
- Single source of truth for every agent. No registry entry = no Permit decision, ever.
- Required fields: owner, purpose, tenant scope, model/version, risk tier (NIST AI RMF
  mapped), data classes touched, human-oversight level, last review date.
- Quarterly owner-signed attestation; stale entries auto-flag to Exceptions Node.

### ADR-101-06 — Mission / task execution
- Every mission compiles to an explicit, versioned task graph (DAG) before execution.
- Each graph node carries its own policy check — no blanket mission-level authorization.
- Graphs are immutable once execution starts; mid-flight change = new version + re-evaluation.

### ADR-101-07 — Remote worker security
- mTLS with short-lived certs, no shared secrets.
- Every worker action bound to an execution epoch; stale-epoch calls rejected at gateway.
- Per-tenant backpressure and rate limits.

### ADR-101-08 — Audit & governance correlation
- One correlation ID spans Intent → Mission → Policy Evaluation → Task → Worker →
  Result → Outcome.
- WORM-pattern, hash-chained audit records (tamper-evident).
- Per-tenant queryable without exposing other tenants.

### ADR-101-11 — Autonomous learning loop (Obsidian-driven)
- HEER learns from its own execution history, not from live production traffic in
  real time. The loop is: Audit outcomes + Exceptions resolutions + human overrides
  → Obsidian (memory) → Learning Pipeline → **Proposed** policy/behavior changes →
  same Propose → Review → Master Approval lifecycle as any other ADR (Section 9).
- HEER may never self-modify a live policy, a live task-graph template, or its own
  registry entry. Learning output is always a proposal artifact, never a write.
- Three learning surfaces, each gated differently:
  1. **Policy tuning suggestions** (e.g. "this financial-limit rule triggers 40%
     false-positive exceptions") — routed to the Policy Engine's human reviewer
     group, never auto-merged into policies/.
  2. **Task-graph pattern library** — successful, VERIFIED mission patterns get
     cached in Obsidian as reusable templates. Reuse is allowed without re-approval;
     the pattern *becoming* a template requires sign-off, same as any ADR.
  3. **Agent performance feedback** — feeds the AI Inventory Registry's risk-tier
     and review-date fields (e.g. an agent with rising exception rate gets flagged
     for early re-attestation, not silently deprioritized or retrained in place).
- Every learning-derived proposal carries provenance: which audit records, which
  exception resolutions, and which correlation IDs it was derived from — an
  unattributed "the system suggests X" is not acceptable; it must cite its evidence
  the same way an ADR cites its rationale.
- No model fine-tuning or weight update happens on live tenant data without
  explicit per-tenant consent recorded in the AI Inventory Registry (this extends
  the existing data-governance rule in Section 8, not a new exception to it).
- A learning proposal that would loosen a security or tenant-isolation boundary is
  never auto-suggested for fast-track approval — it goes through Gate 3/4 in
  docs/ROADMAP.md like any change touching those boundaries, full stop.
- Rationale: the single biggest failure mode in "self-improving" agent systems is
  the learning loop becoming a silent second write-path around the governance the
  rest of the architecture was built to enforce. This ADR closes that path by
  construction — learning only ever produces an artifact that re-enters the front
  of the same approval pipeline everything else uses.

### ADR-101-12 — Voice-first conversational interface
- Voice is the primary interaction channel. The console is ambient and
  conversational — no forms, no typed commands required for standard operation.
- **Voice is a transport, not a trust boundary.** Every voice command resolves to
  the exact same {identity, action, resource, context} shape any other channel
  produces, and goes through the same Policy Engine Permit/Deny/Exception decision
  (ADR-101-03) before anything executes. A spoken command has no elevated or
  reduced authority versus an API call or a dashboard click.
- Speech-to-text and text-to-speech are commodity services behind an interface
  (not a fixed vendor) so the voice layer can be swapped without touching
  governance code.
- Wake-word / always-listening capture, if enabled, runs entirely client-side and
  discards audio that doesn't match the wake pattern — raw ambient audio is never
  transmitted to any backend service. This is a hard requirement, not an
  optimization, given how much regulated conversation happens in earshot of an
  always-on device in an enterprise setting.
- Every voice interaction is logged in the audit trail (ADR-101-08) with the same
  correlation ID discipline as any execution — a spoken instruction is exactly as
  reconstructable after the fact as anything else in the system.
- Sensitive/high-risk actions (anything that would route to the Exceptions Node
  under ADR-101-04) require a spoken confirmation step back from HEER before
  execution — "pause mission 4471" gets "confirm: pause mission 4471, yes or no,"
  never silent execution on a single utterance.

### ADR-101-13 — Skills framework
- A "skill" is a registered, governed capability HEER can invoke — structurally
  identical to an agent entry in the AI Inventory Registry (ADR-101-05), not a
  separate unmanaged plugin system. Every skill has an owner, a risk tier, and a
  set of policies that gate it.
- Skills are additive and sandboxed: a new skill cannot expand what any existing
  agent or the console itself is authorized to do. Installing a skill is itself a
  Master-Approval-gated action (Section 9), because a skill is functionally a new
  entry point into the system.
- Three skill classes, each with a different default posture:
  1. **Read/inform skills** (status, reporting, lookups) — default ON, low risk,
     still logged, still policy-checked, but no confirmation step required.
  2. **Control skills** (pause/resume a mission, reassign an exception) — default
     ON but require the spoken-confirmation step from ADR-101-12.
  3. **Financial/high-risk skills** (approve a payment, change a policy limit) —
     default GATED. Gated means the skill is visible and registered but returns an
     Exception rather than executing, until a human explicitly ungates it per
     tenant — this is what the console's "gated" skill state means.
- See docs/SKILLS.md for the initial required skill catalog.

## Execution lifecycle (must match exactly)

```
Intent → Mission → Policy Evaluation → Authorization → Task Graph →
Task Execution → Worker → Result → Audit → Outcome
```

## Change lifecycle (must match exactly)

```
Propose → Review → Master Approval → Authorize Work Package →
Implement → Verify → Accept → Update SoT
```

## Status vocabulary (never interchangeable)

| Status | Meaning |
|---|---|
| PROPOSED | Suggested but not approved |
| APPROVED | Master authority has approved it |
| IMPLEMENTED | Code exists |
| TESTED | Automated tests executed |
| VERIFIED | Required behavior independently checked |
| ACCEPTED | Work package formally accepted |
| AUTHORITATIVE | Accepted state incorporated into the SoT |

## Recommended stack (reference — see docs/STACK.md for rationale per component)

Identity: Keycloak/Ory + SPIFFE/SPIRE + Vault | Policy: OPA | Workflow (Exceptions +
Mission Engine): Temporal.io | Data: Postgres (RLS) + pgvector | Events/Audit: Kafka +
S3 Object Lock + ClickHouse | Runtime: Kubernetes + Istio/Linkerd (mTLS) | Model
gateway: LiteLLM/Portkey | Tracing: OpenTelemetry.

## Proposed changes (pending Master approval)

_(none yet — add entries here, never edit the ADRs above directly)_
