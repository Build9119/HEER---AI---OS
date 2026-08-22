#!/usr/bin/env bash
# HEER ROUTE 101 — Per-agent .clinerules generator
# Creates a tightly scoped .clinerules for a specific agent window.
# Usage: bash factory/make-agent-rules.sh AGENT-02
# Run this in the VS Code window for that agent BEFORE opening Cline.

set -euo pipefail
AGENT_ID="${1:-}"
if [ -z "$AGENT_ID" ]; then
  echo "Usage: bash factory/make-agent-rules.sh AGENT-02"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Agent ownership map
declare -A AGENT_OWNS=(
  [AGENT-02]="infra/keycloak infra/spire infra/postgres/migrations tests/tenant-isolation"
  [AGENT-03]="services/policy-engine policies"
  [AGENT-04]="services/exceptions-node"
  [AGENT-05]="services/ai-registry"
  [AGENT-06]="services/mission-engine"
  [AGENT-07]="services/audit/worker-security"
  [AGENT-08]="services/audit"
  [AGENT-11]="services/learning-loop"
  [AGENT-12]="services/voice-interface console"
)

declare -A AGENT_PACKAGES=(
  [AGENT-02]="R101-02"
  [AGENT-03]="R101-03"
  [AGENT-04]="R101-04"
  [AGENT-05]="R101-05"
  [AGENT-06]="R101-06"
  [AGENT-07]="R101-07"
  [AGENT-08]="R101-08"
  [AGENT-11]="R101-11"
  [AGENT-12]="R101-12"
)

if [ -z "${AGENT_OWNS[$AGENT_ID]+x}" ]; then
  echo "Unknown agent: $AGENT_ID"
  echo "Valid agents: ${!AGENT_OWNS[@]}"
  exit 1
fi

OWNS="${AGENT_OWNS[$AGENT_ID]}"
PACKAGE="${AGENT_PACKAGES[$AGENT_ID]}"

# Build the NOT OWNS list (everything else)
ALL_DIRS="infra/keycloak infra/spire infra/postgres/migrations tests/tenant-isolation services/policy-engine policies services/exceptions-node services/ai-registry services/mission-engine services/audit/worker-security services/audit services/learning-loop services/voice-interface console"
NOT_OWNS=""
for dir in $ALL_DIRS; do
  if ! echo "$OWNS" | grep -q "$dir"; then
    NOT_OWNS="$NOT_OWNS  $dir\n"
  fi
done

cat > .clinerules << RULES
# HEER ROUTE 101 — $AGENT_ID scoped rules
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# Work package: $PACKAGE
# This file is binding. Read every line before doing anything.

## Session start — mandatory, no exceptions

Run this first, paste complete output, stop if it fails:
  bash factory/session-guard.sh $AGENT_ID

Read these files in order before writing anything:
  1. factory/prompts/$AGENT_ID.md  ← your exact scope and acceptance criteria
  2. docs/ARCHITECTURE.md          ← the ADRs
  3. docs/PLAN.md                  ← acceptance criteria for $PACKAGE
  4. factory/DASHBOARD.md          ← what's authorized right now

Run before claiming done:
  bash factory/gate-check.sh $AGENT_ID

## You are $AGENT_ID — work package $PACKAGE only

### You OWN (write access):
$(echo "$OWNS" | tr ' ' '\n' | sed 's/^/  /')
  docker-compose.yml     (your service addition ONLY — no other changes)
  .github/workflows/ci.yml  (your test job ONLY — no other changes)

### You must NOT touch:
$(echo -e "$NOT_OWNS")  libs/
  docs/              (read only)
  .clinerules        (read only — this file)
  factory/           (read only)
  console/heer-console.html  (locked design — AGENT-12 only, wiring only)

## Session corruption protocol

If you hit 3 or more tool call failures in a row:
  STOP. Say exactly: "Session corrupted at [step] — run factory/recover.sh $AGENT_ID"
  Do not try to recover. Do not summarise. Do not commit. Wait for Master.

## Status vocabulary — use ONLY these words

  IMPLEMENTED = file/code exists
  TESTED      = automated test executed, output seen
  VERIFIED    = acceptance criterion from docs/PLAN.md independently confirmed

Never use: done, complete, finished, looks good, working, all good.
Never round IMPLEMENTED up to VERIFIED.

## Evidence rules

Every report requires RAW output:
  - Full test runner output with named test cases
  - Full docker-compose ps output
  - Full SQL query results
  - Full git log and git status
Summaries are not evidence. "12/12 tests pass" is not evidence.

## Hard boundaries — never cross these

  - No static, long-lived credentials (ADR-101-02)
  - No cross-tenant data without RLS (Section 7)
  - No task execution without Policy Engine Permit (ADR-101-06)
  - No agent without Registry entry (ADR-101-05)
  - No learning-loop direct write to policies/ (ADR-101-11)
  - Voice = same Policy Engine path as API, no bypass (ADR-101-12)

## Ambiguity escalation

  1. Check docs/ARCHITECTURE.md
  2. Check docs/PLAN.md
  3. Check docs/ROADMAP.md
  4. Check factory/FACTORY.md
  5. Stop and report to Master — never guess on identity, tenant isolation,
     policy evaluation, or the console design
RULES

echo ""
echo "✓ .clinerules written for $AGENT_ID"
echo "  Work package: $PACKAGE"
echo "  Owns: $OWNS"
echo ""
echo "Next: open Cline in this VS Code window and paste:"
echo "  bash factory/session-guard.sh $AGENT_ID"
