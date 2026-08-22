#!/usr/bin/env bash
# HEER ROUTE 101 — Factory bootstrap
# Run this ONCE from the repo root before starting any Cline agent session.
# Usage: bash factory/bootstrap.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   HEER ROUTE 101 — Factory Bootstrap     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Verify git repo ────────────────────────────────────────────────────────
echo "[ 1/7 ] Verifying git repository..."
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "  → No git repo found. Initialising..."
  git init
  git checkout -b main
  echo "  ✓ git init done"
else
  echo "  ✓ Git repo OK (branch: $(git branch --show-current))"
fi

# ── 2. Verify .clinerules ─────────────────────────────────────────────────────
echo ""
echo "[ 2/7 ] Checking .clinerules..."
if [ ! -f ".clinerules" ]; then
  echo "  ✗ .clinerules MISSING — factory cannot run without it."
  echo ""
  echo "  Restore it from the scaffold zip:"
  echo "    unzip -p ~/Downloads/heer-route-101-repo-scaffold.zip \\"
  echo "      heer-route-101/.clinerules > .clinerules"
  echo "    git add .clinerules && git commit -m '[factory] restore .clinerules'"
  echo ""
  exit 1
else
  LINE_COUNT=$(wc -l < .clinerules)
  echo "  ✓ .clinerules present ($LINE_COUNT lines)"
fi

# ── 3. Verify factory prompts ─────────────────────────────────────────────────
echo ""
echo "[ 3/7 ] Checking agent prompts..."
AGENTS=(02 03 04 05 06 07 08 11 12)
MISSING_PROMPTS=0
for id in "${AGENTS[@]}"; do
  f="factory/prompts/AGENT-${id}.md"
  if [ -f "$f" ]; then
    echo "  ✓ $f"
  else
    echo "  ✗ MISSING: $f"
    MISSING_PROMPTS=$((MISSING_PROMPTS + 1))
  fi
done
if [ "$MISSING_PROMPTS" -gt 0 ]; then
  echo ""
  echo "  ✗ $MISSING_PROMPTS prompt(s) missing. Re-unzip the scaffold."
  exit 1
fi

# ── 4. Verify docker-compose services ────────────────────────────────────────
echo ""
echo "[ 4/7 ] Checking docker-compose services..."
if ! command -v docker &> /dev/null; then
  echo "  ⚠  Docker not found — skipping container check."
  echo "     Install Docker Desktop and run 'docker-compose up -d' manually."
else
  if docker compose ps --services 2>/dev/null | grep -q .; then
    echo "  Containers currently running:"
    docker compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || \
    docker-compose ps 2>/dev/null | tail -n +3 | awk '{print "  → " $1 "\t" $5}'
  else
    echo "  → Containers not running. Starting them..."
    docker compose up -d 2>/dev/null || docker-compose up -d
    echo "  → Waiting 10s for healthchecks..."
    sleep 10
    docker compose ps 2>/dev/null || docker-compose ps
  fi
fi

# ── 5. Write per-agent workspace markers ─────────────────────────────────────
echo ""
echo "[ 5/7 ] Writing agent workspace markers..."
declare -A AGENT_OWNS=(
  [02]="infra/keycloak infra/spire infra/postgres/migrations tests/tenant-isolation"
  [03]="services/policy-engine policies"
  [04]="services/exceptions-node"
  [05]="services/ai-registry"
  [06]="services/mission-engine"
  [07]="services/audit/worker-security infra/spire"
  [08]="services/audit"
  [11]="services/learning-loop"
  [12]="services/voice-interface console"
)
for id in "${!AGENT_OWNS[@]}"; do
  for dir in ${AGENT_OWNS[$id]}; do
    mkdir -p "$dir"
    MARKER="$dir/.agent-owner"
    echo "AGENT-${id}" > "$MARKER"
  done
done
echo "  ✓ Workspace markers written (.agent-owner files)"

# ── 6. Write session state file ───────────────────────────────────────────────
echo ""
echo "[ 6/7 ] Writing factory session state..."
cat > factory/.session-state.json << EOF
{
  "bootstrapped_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "repo_root": "$REPO_ROOT",
  "git_branch": "$(git branch --show-current)",
  "git_head": "$(git rev-parse --short HEAD 2>/dev/null || echo 'no-commits')",
  "agents": {
    "AGENT-02": { "status": "NOT_STARTED", "work_package": "R101-02", "gate_accepted": false },
    "AGENT-03": { "status": "NOT_STARTED", "work_package": "R101-03", "gate_accepted": false },
    "AGENT-04": { "status": "NOT_STARTED", "work_package": "R101-04", "gate_accepted": false },
    "AGENT-05": { "status": "NOT_STARTED", "work_package": "R101-05", "gate_accepted": false },
    "AGENT-06": { "status": "NOT_STARTED", "work_package": "R101-06", "gate_accepted": false },
    "AGENT-07": { "status": "NOT_STARTED", "work_package": "R101-07", "gate_accepted": false },
    "AGENT-08": { "status": "NOT_STARTED", "work_package": "R101-08", "gate_accepted": false },
    "AGENT-11": { "status": "NOT_STARTED", "work_package": "R101-11", "gate_accepted": false },
    "AGENT-12": { "status": "NOT_STARTED", "work_package": "R101-12", "gate_accepted": false }
  }
}
EOF
echo "  ✓ factory/.session-state.json written"

# ── 7. Print Cline startup prompt for AGENT-02 ───────────────────────────────
echo ""
echo "[ 7/7 ] Bootstrap complete."
echo ""
echo "══════════════════════════════════════════════════════════"
echo " NEXT STEP: Open Cline and paste the following prompt     "
echo "══════════════════════════════════════════════════════════"
echo ""
cat factory/prompts/AGENT-02.md
echo ""
echo "══════════════════════════════════════════════════════════"
echo " Copy everything between the lines above into Cline       "
echo "══════════════════════════════════════════════════════════"
