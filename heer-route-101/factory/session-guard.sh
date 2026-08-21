#!/usr/bin/env bash
# HEER ROUTE 101 — Session guard
# Cline runs this at the START of every session, before any file changes.
# If any check fails, Cline stops and reports to Master. No exceptions.
# Usage: bash factory/session-guard.sh AGENT-02

set -euo pipefail
AGENT_ID="${1:-UNKNOWN}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0

check() {
  local label="$1"
  local result="$2"   # "ok" or "fail"
  local detail="$3"
  if [ "$result" = "ok" ]; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ FAIL: $label"
    echo "    → $detail"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   HEER Session Guard — $AGENT_ID         "
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Git repo exists
git rev-parse --git-dir > /dev/null 2>&1 \
  && check "Git repository" "ok" "" \
  || check "Git repository" "fail" "Not a git repo. Run factory/bootstrap.sh first."

# 2. .clinerules present and non-empty
[ -s ".clinerules" ] \
  && check ".clinerules present" "ok" "" \
  || check ".clinerules present" "fail" "Missing or empty. Restore from scaffold zip."

# 3. Factory prompt for this agent exists
PROMPT_FILE="factory/prompts/${AGENT_ID}.md"
[ -f "$PROMPT_FILE" ] \
  && check "Agent prompt exists ($PROMPT_FILE)" "ok" "" \
  || check "Agent prompt exists ($PROMPT_FILE)" "fail" "Prompt file missing. Re-unzip scaffold."

# 4. Session state file exists
[ -f "factory/.session-state.json" ] \
  && check "Session state file" "ok" "" \
  || check "Session state file" "fail" "Run factory/bootstrap.sh first."

# 5. No uncommitted work from a previous corrupted session
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$DIRTY" -gt 0 ]; then
  echo "  ⚠  Uncommitted changes detected ($DIRTY files):"
  git status --short | head -20
  echo "     Review before proceeding — this may be leftover from a prior session."
  echo "     If it's expected (e.g. mid-task), that's fine. If unexpected, stop."
fi

# 6. Docker services healthy (warn, don't fail — some agents don't need containers)
if command -v docker &> /dev/null; then
  UNHEALTHY=$(docker compose ps 2>/dev/null | grep -v "healthy\|Up" | grep -v "NAME" | wc -l | tr -d ' ' || echo "0")
  [ "$UNHEALTHY" -eq 0 ] \
    && check "Docker services" "ok" "" \
    || check "Docker services" "fail" "$UNHEALTHY service(s) not healthy. Run docker-compose up -d."
fi

# 7. Agent ownership check — warn if agent tries to work outside its directory
declare -A AGENT_DIRS=(
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
if [ -n "${AGENT_DIRS[$AGENT_ID]+x}" ]; then
  echo "  ✓ Authorized directories for $AGENT_ID:"
  for dir in ${AGENT_DIRS[$AGENT_ID]}; do
    echo "    → $dir"
  done
else
  echo "  ⚠  No directory mapping found for $AGENT_ID — check factory/FACTORY.md"
fi

echo ""
echo "══════════════════════════════════════════"
echo " Guard result: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo " ✗ SESSION BLOCKED — fix the failures above before proceeding."
  echo "   Report to Master before touching any files."
  exit 1
else
  echo " ✓ SESSION CLEAR — read your prompt at factory/prompts/${AGENT_ID}.md"
  echo "   then give Master a Plan-mode summary before writing any files."
  exit 0
fi
