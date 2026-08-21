# HEER skills catalog — required for launch

Every skill below is a registered capability (ADR-101-13), not a hardcoded console
feature. Each row is effectively a stub AI Inventory Registry entry — fill in Owner
before a skill goes live. "Class" determines default posture: Read (no confirmation),
Control (spoken confirmation required), Gated (off by default, returns an Exception
until a human ungates it per tenant).

## Core operator skills (build first — these make the console usable at all)

| Skill | Class | What it does | Owner |
|---|---|---|---|
| Status report | Read | Summarizes governance state, active missions, open exceptions | ___ |
| System health | Read | Reports service health, latency, error rates per component | ___ |
| Exception review | Read | Lists/describes pending exceptions with SLA countdown | ___ |
| Registry lookup | Read | Answers "who's registered," "what's this agent's risk tier" | ___ |
| Audit query | Read | Answers "what happened to correlation ID X" / "show me last hour" | ___ |
| Mission control | Control | Pause / resume / cancel a running mission | ___ |
| Exception triage | Control | Assign, escalate, or resolve an exception by voice | ___ |
| Policy explain | Read | Explains why a specific decision was Permit/Deny/Exception, citing decision_id | ___ |

## Financial / high-risk skills (ship gated, ungate per tenant deliberately)

| Skill | Class | What it does | Owner |
|---|---|---|---|
| Payment approval | Gated | Approves a payment/invoice above a configured threshold | ___ |
| Policy limit change | Gated | Adjusts a financial or scope limit inside the Policy Engine | ___ |
| Agent risk-tier override | Gated | Manually changes an agent's registry risk tier | ___ |
| Emergency stop | Gated (but always reachable) | Halts all missions on a tenant immediately — see note below | ___ |

Emergency stop is the one Gated skill that must still be voice-reachable even when
everything else is gated off — a governance system that can't be told to stop by
voice in an incident is a design failure. It still requires spoken confirmation and
is still fully audited; it is just never blocked behind a separate ungating step.

## Conversational quality-of-life skills (build once core skills are stable)

| Skill | Class | What it does | Owner |
|---|---|---|---|
| Follow-up context | Read | Resolves "pause that one instead" referring to the prior answer | ___ |
| Daily briefing | Read | Proactive voice summary at a scheduled time — opt-in per operator | ___ |
| Cross-tenant summary | Read (Master-only) | Aggregates status across tenants — requires Master-level identity | ___ |
| Explain-like-I'm-new | Read | Plain-language explanation of any HEER concept for onboarding operators | ___ |

## Explicitly out of scope for the voice channel (do not build these as skills)

- Anything that would change an ADR or docs/ARCHITECTURE.md itself — architecture
  changes go through Section 9's Propose → Review → Master Approval flow, not voice.
- Bulk/irreversible data operations (mass delete, mass export) — too easy to
  trigger by voice-recognition error; require the dashboard's explicit UI for these.
- Anything from R101-11's Learning Pipeline proposing itself as a voice skill that
  writes to policy — ADR-101-11's no-self-write rule applies regardless of channel.

## Adding a new skill

1. Register it here with Owner and Class.
2. Add a registry entry per ADR-101-05's required fields.
3. Write the policy rule(s) that gate it in policies/.
4. Ship it Gated by default if there's any doubt about risk — you can always
   loosen a gate; tightening one after an incident is a much worse conversation.
