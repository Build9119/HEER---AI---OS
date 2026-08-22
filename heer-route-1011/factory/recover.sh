#!/usr/bin/env bash
# HEER ROUTE 101 — Factory recovery
# Run this when a Cline session leaves the repo in a broken or unknown state.
# Usage: bash factory/recover.sh AGENT-02
# It snapshots what's there, resets to the last clean gate, and reports.

set -euo pipefail
AGENT_ID="${1:-UNKNOWN}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   HEER Factory Recovery — $AGENT_ID      "
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Snapshot broken state ──────────────────────────────────────────────────
SNAPSHOT_DIR="factory/.snapshots/$(date +%Y%m%d_%H%M%S)_${AGENT_ID}_broken"
mkdir -p "$SNAPSHOT_DIR"
echo "[ 1/5 ] Snapshotting broken state → $SNAPSHOT_DIR"
git status > "$SNAPSHOT_DIR/git-status.txt" 2>&1 || true
git log --oneline -20 > "$SNAPSHOT_DIR/git-log.txt" 2>&1 || true
git diff > "$SNAPSHOT_DIR/git-diff.txt" 2>&1 || true
docker compose ps > "$SNAPSHOT_DIR/docker-ps.txt" 2>&1 || true
echo "  ✓ Snapshot written"

# ── 2. Show what's uncommitted ────────────────────────────────────────────────
echo ""
echo "[ 2/5 ] Current uncommitted state:"
git status --short || true
echo ""

# ── 3. Find last clean gate commit ───────────────────────────────────────────
echo "[ 3/5 ] Finding last clean gate commit..."
LAST_GATE=$(git log --oneline | grep -E "\[R101-0[0-9]\]" | head -1 | awk '{print $1}' || true)
if [ -z "$LAST_GATE" ]; then
  LAST_GATE=$(git log --oneline | tail -1 | awk '{print $1}')
  echo "  ⚠  No gate commit found — last commit is: $LAST_GATE"
else
  echo "  ✓ Last gate commit: $LAST_GATE ($(git log --oneline -1 $LAST_GATE))"
fi

# ── 4. Ask before resetting ───────────────────────────────────────────────────
echo ""
echo "[ 4/5 ] Recovery options:"
echo ""
echo "  A) Stash uncommitted changes and restart $AGENT_ID from last gate"
echo "     → git stash + restart session"
echo "  B) Hard reset to last gate commit (DISCARDS uncommitted work)"
echo "     → git reset --hard $LAST_GATE"
echo "  C) Keep everything as-is, just fix docker-compose"
echo "     → docker-compose down && docker-compose up -d"
echo "  D) Exit and let Master decide manually"
echo ""
read -p "  Choose A/B/C/D: " CHOICE

case "${CHOICE^^}" in
  A)
    echo ""
    echo "  → Stashing changes..."
    git stash push -m "AGENT-${AGENT_ID} broken session $(date +%Y%m%d_%H%M%S)" || true
    echo "  ✓ Changes stashed. Run 'git stash list' to see them."
    echo "  → Bringing docker-compose back up..."
    docker compose down 2>/dev/null || true
    docker compose up -d 2>/dev/null || docker-compose up -d
    echo "  ✓ Stack restarted. Run factory/session-guard.sh $AGENT_ID to verify."
    ;;
  B)
    echo ""
    echo "  ⚠  This will DISCARD all uncommitted changes."
    read -p "  Type 'yes' to confirm hard reset to $LAST_GATE: " CONFIRM
    if [ "${CONFIRM,,}" = "yes" ]; then
      git reset --hard "$LAST_GATE"
      git clean -fd
      echo "  ✓ Reset to $LAST_GATE"
      docker compose down 2>/dev/null || true
      docker compose up -d 2>/dev/null || docker-compose up -d
      echo "  ✓ Stack restarted from clean baseline."
    else
      echo "  → Reset cancelled."
    fi
    ;;
  C)
    echo ""
    echo "  → Restarting docker-compose only..."
    docker compose down 2>/dev/null || true
    sleep 3
    docker compose up -d 2>/dev/null || docker-compose up -d
    sleep 10
    docker compose ps 2>/dev/null || docker-compose ps
    ;;
  D)
    echo ""
    echo "  → Exiting. Share factory/.snapshots/ contents with Master."
    exit 0
    ;;
  *)
    echo "  → Invalid choice. Exiting without changes."
    exit 1
    ;;
esac

# ── 5. Post-recovery guard ────────────────────────────────────────────────────
echo ""
echo "[ 5/5 ] Running session guard post-recovery..."
bash factory/session-guard.sh "$AGENT_ID" || true

echo ""
echo "══════════════════════════════════════════════════════"
echo " Recovery complete. Share this output with Master     "
echo " before starting a new $AGENT_ID session.            "
echo "══════════════════════════════════════════════════════"
