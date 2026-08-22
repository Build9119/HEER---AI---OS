# HEER ROUTE 101 — Multi-Agent Production Factory

## Design principle

One Cline instance per service. Each agent owns exactly one service directory,
cannot write outside it, runs under the same .clinerules contract, and reports
status using the same IMPLEMENTED / TESTED / VERIFIED vocabulary. The Master
(you) coordinates across agents — no agent coordinates with another agent directly.

This is not "Cline doing eight things in parallel." It is eight scoped agents
operating in sequence (or limited parallel where dependencies allow), each one
small enough to stay honest about what it has and hasn't verified.

## Agent roster

| Agent ID | Service | Owns | Authorized when |
|---|---|---|---|
| AGENT-00 | repo-baseline | .clinerules, docker-compose, libs/, .github/ | R101-00 VERIFIED |
| AGENT-02 | identity-tenant | infra/keycloak/, infra/spire/, infra/postgres/migrations/, tests/tenant-isolation/ | R101-00 VERIFIED |
| AGENT-03 | policy-engine | services/policy-engine/, policies/ | R101-02 VERIFIED |
| AGENT-05 | ai-registry | services/ai-registry/ | R101-02 + R101-03 VERIFIED |
| AGENT-06 | mission-engine | services/mission-engine/ | R101-02 + R101-03 + R101-05 VERIFIED |
| AGENT-04 | exceptions-node | services/exceptions-node/ | R101-02 + R101-03 VERIFIED |
| AGENT-07 | worker-security | services/audit/ (worker attestation pieces) | R101-02 VERIFIED |
| AGENT-08 | audit | services/audit/ | R101-02 VERIFIED |
| AGENT-11 | learning-loop | services/learning-loop/ | R101-08 + R101-04 VERIFIED |
| AGENT-12 | voice-console | services/voice-interface/, console/ | R101-02 + R101-03 + R101-08 VERIFIED |

## Parallel execution lanes (what can run at the same time)

Lane A (unblocked after R101-02 VERIFIED):
  AGENT-03 (policy-engine) + AGENT-07 (worker-security) + AGENT-08 (audit)

Lane B (unblocked after Lane A VERIFIED):
  AGENT-05 (ai-registry) — needs policy-engine + identity

Lane C (unblocked after Lane B VERIFIED):
  AGENT-06 (mission-engine) + AGENT-04 (exceptions-node) — can run in parallel

Lane D (unblocked after Lane C VERIFIED):
  AGENT-11 (learning-loop) + AGENT-12 (voice-console)

## Hard rules for all agents

1. An agent that hasn't been given a factory prompt (factory/prompts/) for its
   work package is not authorized to start — even if its dependency is met.
2. No agent writes outside its Owns column above. Ever. Not even "just to fix
   a shared constant." Propose it to the Master instead.
3. Every agent re-reads .clinerules at the start of every session — not just
   the first one.
4. Status reports use exact vocabulary: IMPLEMENTED / TESTED / VERIFIED.
   "Done" is not a status. "Looks good" is not a status.
5. An agent that discovers a dependency isn't actually VERIFIED (e.g. the
   previous agent's test passed locally but had a flaw) stops immediately,
   reports to Master, does not work around it.
6. Gate reviews happen here (with Master), not between agents. Agents do not
   review each other's work or unblock each other.

## Session discipline

Each agent session starts with this exact sequence, no exceptions:
1. git status + git log --oneline -10
2. Re-read .clinerules
3. Read the agent's factory prompt (factory/prompts/AGENT-XX.md)
4. Plan-mode summary to Master before any file changes
5. Master approval before Act mode
6. Raw evidence report after Act mode
7. Master Gate review before declaring VERIFIED
