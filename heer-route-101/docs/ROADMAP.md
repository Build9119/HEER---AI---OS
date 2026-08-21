# HEER ROUTE 101 — production roadmap

This sits above docs/PLAN.md. PLAN.md answers "what gets built and in what order."
This document answers "what does it take for that thing to be allowed to touch
production traffic, who signs off, and what happens if it breaks." Where the two
conflict, this document's gates win — a phase can be IMPLEMENTED per PLAN.md and
still be refused a production gate here.

No phase advances on verbal agreement. Every gate below requires the named artifact
to exist and be linked from the PR/ticket that claims the gate is passed.

## Environment strategy

Three environments, promoted in order. No phase skips an environment, ever —
including hotfixes.

| Environment | Purpose | Data | Who can deploy |
|---|---|---|---|
| dev | Local/shared dev cluster, docker-compose or dev k8s namespace | Synthetic only | Any engineer, any time |
| staging | Production-topology mirror, same OPA policies, same RLS config | De-identified copy of prod schema, zero real tenant data | CI/CD only, via PR merge to `main` |
| production | Live tenant traffic | Real | CI/CD only, via tagged release + gate sign-off below |

A change is never hand-deployed to staging or production. If that happens, treat it
as a security incident, not a shortcut — it bypasses every gate below.

## Roles (fill in names before kickoff — do not start Phase 1 with this table empty)

| Role | Responsible for | Name |
|---|---|---|
| Master / Architecture Owner | Final sign-off on architecture changes, ADR approval | _____ |
| Security Owner | Sign-off on Gate 3 (security) every phase | _____ |
| Data/Privacy Owner | Sign-off on Gate 4 (tenant isolation, data classes) | _____ |
| Service Owner (per service) | Implementation, on-call, PLAN.md acceptance criteria | _____ per service |
| Release Manager | Executes promotion, owns rollback trigger | _____ |

If a role is unfilled, that role's gate cannot be signed off, and the phase cannot
reach production. This is intentional — it surfaces the ambiguity instead of letting
a phase quietly ship without a real owner.

## Phase-to-production gate sequence

Every phase in PLAN.md (R101-00 through R101-08) passes through the same five gates
before it's allowed into production. This is what removes ambiguity: "done" always
means "passed all five," never "code merged."

### Gate 1 — Implementation complete (dev)
- All checklist items in the phase's PLAN.md section are checked off.
- Code merged to `main` via PR with at least one reviewer who is not the author.
- Artifact: PR link.

### Gate 2 — Verified (staging)
- Phase's Acceptance line in PLAN.md is demonstrated in staging, not just dev.
- Automated test suite (unit + the phase's specific tests, e.g. tenant-isolation)
  passes in the staging CI run.
- Artifact: link to the passing staging CI run.

### Gate 3 — Security sign-off
- Security Owner reviews: identity/secrets handling, mTLS config if applicable,
  no static credentials introduced, dependency vulnerability scan clean.
- For any phase touching the Policy Engine or Exceptions Node: a reviewer other
  than the implementer manually re-reads the policy/workflow logic line by line.
- Artifact: signed-off checklist (see Production Readiness Checklist below), named
  Security Owner, dated.

### Gate 4 — Tenant isolation & data sign-off
- For any phase touching tenant-scoped data: tenant-isolation test suite passes
  in staging with production-equivalent RLS policies active.
- Data classes touched are declared (public/internal/confidential/regulated) and
  match what's registered for the relevant agent(s) in the AI Inventory Registry.
- Artifact: signed-off checklist, named Data/Privacy Owner, dated.

### Gate 5 — Master approval to promote
- Master / Architecture Owner confirms Gates 1–4 are all signed and the phase
  doesn't conflict with an ADR in docs/ARCHITECTURE.md.
- Artifact: Master sign-off recorded in the release ticket.

Only after Gate 5 does the Release Manager promote to production. No phase is
promoted on a Friday or ahead of a holiday/on-call gap — this is a rule, not a
guideline, because the Exceptions Node and audit trail are the safety net for
everything else, and a broken safety net over a weekend is the worst possible
failure mode for this system.

## Production readiness checklist (used at Gate 3/4, one copy per phase)

- [ ] No static, long-lived credentials introduced (grep for API keys, check
      Vault/SPIFFE usage instead).
- [ ] Every new tenant-scoped table has an RLS policy — CI check is green.
- [ ] Every new agent-callable action requires a Policy Engine Permit decision —
      no bypass path exists (manually verify, don't just trust the code review).
- [ ] Rollback plan written and tested in staging (see Rollback below).
- [ ] Dashboards/alerts exist for this phase's new service before it goes live —
      not added after the first incident.
- [ ] On-call runbook entry exists naming the Service Owner and escalation path.
- [ ] Audit events for this phase's actions are visible end-to-end in the audit
      query layer (once R101-08 exists) or explicitly noted as "audit deferred to
      R101-08" if this phase ships before audit is live — never silently missing.

## Rollback policy

Every production promotion must have a tested rollback before Gate 5, not one
improvised during an incident.

| Trigger | Action | Who decides |
|---|---|---|
| Automated test failure post-deploy | Automatic rollback via CI/CD | System (no human gate needed) |
| Tenant-isolation breach suspected | Immediate rollback + incident declared | Any engineer, no approval needed to roll back |
| Policy Engine returning incorrect Permit/Deny at elevated rate | Rollback + freeze policy changes until root-caused | Security Owner or Release Manager |
| SLA breach in Exceptions Node itself (the safety net breaks) | Rollback + all affected missions paused, not silently retried | Master / Architecture Owner |

Rolling back is never treated as a failure requiring justification. Staying on a
broken production deploy while debugging live is the actual failure mode to avoid.

## Dependency graph (explicit, not inferred)

```
R101-00 (repo/tooling)
   │
   ▼
R101-02 (identity & tenant) ──────────────┬──────────────┐
   │                                       │              │
   ▼                                       ▼              ▼
R101-03 (policy engine)            R101-07 (worker sec)  R101-08 (audit)
   │
   ▼
R101-05 (AI registry) ──requires policy engine + identity
   │
   ▼
R101-06 (mission engine) ──requires registry + policy + identity
   │
R101-04 (exceptions node) ──requires policy + identity (parallel to R101-06 is fine)
   │
   ▼
R101-11 (autonomous learning loop) ──requires audit (R101-08) + exceptions (R101-04)
   │  proposal-only; no write path into policy/registry/task-graph templates
   │
   ▼
R101-12 (voice interface & console) ──requires identity + policy + audit
   │  voice has no elevated authority — same Policy Engine path as any channel
   │
   ▼
R101-09 (end-to-end acceptance) ──requires ALL above at Gate 5 in staging
   │
   ▼
R101-10 (closure)
```

R101-07 and R101-08 can run in parallel with R101-03 once R101-02 is done — they
don't depend on the Policy Engine directly. R101-11 depends on both R101-08 and
R101-04 since it consumes their output; it cannot start earlier no matter how
tempting it is to bootstrap learning from a partial audit trail. R101-12 can start
as soon as identity, policy, and audit exist — it doesn't need the Mission Engine
or Exceptions Node finished, since the console can display "not yet available" for
those skills rather than blocking entirely. Everything else is strictly sequential.
If a task tries to start R101-06 before R101-05 is at Gate 2, that's the ambiguity
this graph exists to prevent — stop and flag it.

## Voice interface: additional production gate

Because voice is a new attack surface (ambient audio, spoofed-voice risk, and a UI
built for zero-friction action), R101-12 has one extra requirement before Gate 5:

- A red-team pass specifically attempting to (a) trigger a Gated skill by voice,
  (b) skip the spoken-confirmation step for a Control-class skill, and (c) get any
  raw audio to leave the client. All three must fail. Document the attempt and the
  failure in the release ticket — "we didn't think of a way to break it" is not
  the same as "we tried to break it and couldn't."

## Extra scrutiny for learning-derived changes

A policy-change PR or task-graph-template addition that originated from R101-11's
Learning Pipeline goes through the same five gates as any other change, plus:

- The PR description must include the provenance block (source correlation IDs,
  pattern description) — Gate 1 is not satisfied without it.
- Gate 3 (security sign-off) for a learning-derived change requires the Security
  Owner to independently verify the suggested change against the underlying audit
  data, not just review the diff — the point of provenance is that it's checkable.
- A learning-derived change is never eligible for expedited/hotfix promotion,
  regardless of how minor it looks. The system proposing a change to its own
  governing rules is exactly the case ROADMAP.md's gates exist for.

## Milestones (relative weeks — anchor to a real start date before kickoff)

| Milestone | Target | Exit condition |
|---|---|---|
| M0 — Dev environment live | Week 1 | R101-00 at Gate 2 (staging exists and is healthy) |
| M1 — Identity & policy foundation | Week 4 | R101-02 and R101-03 at Gate 5 (production) |
| M2 — Registry live, agents gated | Week 6 | R101-05 at Gate 5 |
| M3 — Missions executable end-to-end | Week 9 | R101-06 at Gate 5 |
| M4 — Exceptions + worker security + audit | Week 12 | R101-04, R101-07, R101-08 all at Gate 5 |
| M4.5 — Autonomous learning loop live (proposal-only) | Week 13 | R101-11 at Gate 5; first learning-derived PR produced and reviewed |
| M5 — Production-ready HEER | Week 14 | R101-09 acceptance passed |
| M6 — ROUTE 101 closed | Week 15 | R101-10 complete, SoT updated to AUTHORITATIVE |

These are planning targets, not commitments to leadership until the Roles table
above is filled and a Master has reviewed sequencing against real team capacity.
Do not present these dates externally until that review happens — that's exactly
the kind of ambiguity (a plan doc becoming a promise) this roadmap is meant to avoid.

## Escalation path when something is ambiguous

1. Check docs/ARCHITECTURE.md — is this an ADR question?
2. Check docs/PLAN.md — is this a scope/acceptance-criteria question?
3. Check this document — is this a gate/ownership/rollback question?
4. If still unresolved: stop work, write the ambiguity as a one-paragraph question
   in the phase's tracking ticket, tag the Master / Architecture Owner, do not guess.

This applies equally to human engineers and coding agents (Cline). "I made a
reasonable assumption" is not an acceptable substitute for step 4 on anything
touching identity, tenant isolation, or policy evaluation.
