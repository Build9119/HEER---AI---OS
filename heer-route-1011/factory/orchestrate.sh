#!/usr/bin/env bash
# HEER ROUTE 101 — Cline Multi-Agent Factory Orchestrator
# Usage:
#   bash factory/orchestrate.sh start AGENT-02          # start one agent
#   bash factory/orchestrate.sh start-lane-a            # start lane A (03, 07, 08)
#   bash factory/orchestrate.sh start-lane-b            # start lane B (05)
#   bash factory/orchestrate.sh start-lane-c            # start lane C (06, 04)
#   bash factory/orchestrate.sh start-lane-d            # start lane D (11, 12)
#   bash factory/orchestrate.sh status                  # show all agent statuses
#   bash factory/orchestrate.sh kill AGENT-02           # stop one agent
#   bash factory/orchestrate.sh kill-all                # stop all agents

set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIDS_DIR="$REPO/factory/.pids"
LOGS_DIR="$REPO/factory/.logs"
mkdir -p "$PIDS_DIR" "$LOGS_DIR"

# ── Colors ────────────────────────────────────────────────────────────────────
C='\033[0;36m'; G='\033[0;32m'; A='\033[0;33m'; R='\033[0;31m'; N='\033[0m'

# ── Dependency gates (what must be gate-accepted before an agent can start) ───
declare -A DEPS=(
  [AGENT-02]=""
  [AGENT-03]="AGENT-02"
  [AGENT-07]="AGENT-02"
  [AGENT-08]="AGENT-02"
  [AGENT-05]="AGENT-02 AGENT-03"
  [AGENT-06]="AGENT-02 AGENT-03 AGENT-05"
  [AGENT-04]="AGENT-02 AGENT-03"
  [AGENT-11]="AGENT-08 AGENT-04"
  [AGENT-12]="AGENT-02 AGENT-03 AGENT-08"
)

declare -A WORK_PACKAGE=(
  [AGENT-02]="R101-02" [AGENT-03]="R101-03" [AGENT-04]="R101-04"
  [AGENT-05]="R101-05" [AGENT-06]="R101-06" [AGENT-07]="R101-07"
  [AGENT-08]="R101-08" [AGENT-11]="R101-11" [AGENT-12]="R101-12"
)

# ── Check dependencies are gate-accepted ─────────────────────────────────────
check_deps() {
  local agent="$1"
  local deps="${DEPS[$agent]:-}"
  if [ -z "$deps" ]; then return 0; fi
  for dep in $deps; do
    local state_file="$PIDS_DIR/${dep}.gate"
    if [ ! -f "$state_file" ] || [ "$(cat $state_file)" != "ACCEPTED" ]; then
      echo -e "${R}✗ $agent blocked: $dep gate not accepted.${N}"
      echo "  Run: make gate-${dep##AGENT-} to check, then:"
      echo "  echo ACCEPTED > factory/.pids/${dep}.gate"
      return 1
    fi
  done
  return 0
}

# ── Build the Cline task prompt for an agent ─────────────────────────────────
build_prompt() {
  local agent="$1"
  local wp="${WORK_PACKAGE[$agent]}"
  cat <<PROMPT
You are $agent implementing $wp for HEER ROUTE 101.

SESSION START PROTOCOL — run this first, paste complete output:
  bash factory/session-guard.sh $agent

If guard fails: stop immediately. Report to Master. Do not proceed.

If guard passes, read in order (do not skip):
  1. .clinerules
  2. factory/FACTORY.md
  3. factory/prompts/$agent.md
  4. docs/ARCHITECTURE.md (your ADR section only)
  5. docs/PLAN.md (your phase section only)

Then run and paste ALL raw output:
  git status
  git log --oneline -10
  docker-compose ps

Give me a Plan-mode summary:
- Session guard result
- Current repo state (git status + log)
- Files that exist RIGHT NOW vs what you will create
- Exact implementation approach with full code/config shown
- How each acceptance test proves the criterion, not just that it exists

DO NOT write any files until I approve the plan.
DO NOT claim IMPLEMENTED/TESTED/VERIFIED until evidence exists.

Before submitting any Gate report, run:
  bash factory/gate-check.sh $agent
Paste the complete gate-check output in your report.

CORRUPTION PROTOCOL: If you hit 3+ tool failures in a row, stop.
Say exactly: "Session corrupted at [step] — requesting clean restart."
Wait for Master instruction. Do not try to recover.
PROMPT
}

# ── Launch a single agent in a new Terminal window ───────────────────────────
launch_agent() {
  local agent="$1"
  local wp="${WORK_PACKAGE[$agent]:-UNKNOWN}"

  echo -e "${C}Starting $agent ($wp)...${N}"

  # Check deps
  if ! check_deps "$agent"; then
    return 1
  fi

  # Check Cline CLI is available
  if ! command -v cline &>/dev/null; then
    echo -e "${A}⚠  Cline CLI not found. Falling back to prompt-file mode.${N}"
    echo "  1. Open a new VS Code window"
    echo "  2. Open Cline panel"
    echo "  3. Paste contents of: factory/prompts/$agent.md"
    echo ""
    build_prompt "$agent" > "$LOGS_DIR/${agent}.prompt"
    echo -e "${G}  Prompt saved to: factory/.logs/${agent}.prompt${N}"
    return 0
  fi

  # Write prompt to temp file
  local prompt_file="$LOGS_DIR/${agent}.prompt"
  build_prompt "$agent" > "$prompt_file"

  # Launch Cline in background, log to file
  local log_file="$LOGS_DIR/${agent}.log"
  cd "$REPO"

  # Try macOS terminal first, then Linux, then headless
  if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript <<APPLE
tell application "Terminal"
  do script "cd '$REPO' && echo '=== $agent ($wp) ===' && cline --task \"\$(cat '$prompt_file')\" 2>&1 | tee '$log_file'"
  set custom title of front window to "$agent"
end tell
APPLE
    echo -e "${G}✓ $agent launched in new Terminal window${N}"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v gnome-terminal &>/dev/null; then
      gnome-terminal --title="$agent" -- bash -c "cd '$REPO' && cline --task \"\$(cat '$prompt_file')\" 2>&1 | tee '$log_file'; bash"
      echo -e "${G}✓ $agent launched in gnome-terminal${N}"
    elif command -v xterm &>/dev/null; then
      xterm -title "$agent" -e "cd '$REPO' && cline --task \"\$(cat '$prompt_file')\" 2>&1 | tee '$log_file'" &
      echo $! > "$PIDS_DIR/${agent}.pid"
      echo -e "${G}✓ $agent launched in xterm${N}"
    else
      echo -e "${A}No terminal emulator found. Running headless...${N}"
      cline --task "$(cat $prompt_file)" > "$log_file" 2>&1 &
      echo $! > "$PIDS_DIR/${agent}.pid"
      echo -e "${G}✓ $agent running headless (logs: factory/.logs/${agent}.log)${N}"
    fi
  fi

  echo "$agent" >> "$PIDS_DIR/active-agents"
}

# ── Show status of all agents ─────────────────────────────────────────────────
show_status() {
  echo ""
  echo -e "${C}══ HEER Factory Status ══${N}"
  echo ""
  printf "%-12s %-14s %-12s %-10s\n" "AGENT" "WORK PKG" "GATE" "LOG SIZE"
  echo "──────────────────────────────────────────────"

  for agent in AGENT-02 AGENT-03 AGENT-07 AGENT-08 AGENT-05 AGENT-06 AGENT-04 AGENT-11 AGENT-12; do
    local wp="${WORK_PACKAGE[$agent]}"
    local gate="NOT STARTED"
    local logsize="-"

    if [ -f "$PIDS_DIR/${agent}.gate" ]; then
      gate=$(cat "$PIDS_DIR/${agent}.gate")
    elif [ -f "$LOGS_DIR/${agent}.log" ]; then
      gate="IN PROGRESS"
    fi

    if [ -f "$LOGS_DIR/${agent}.log" ]; then
      logsize=$(wc -l < "$LOGS_DIR/${agent}.log" | tr -d ' ')L
    fi

    local color=$N
    [[ "$gate" == "ACCEPTED" ]] && color=$G
    [[ "$gate" == "IN PROGRESS" ]] && color=$A
    [[ "$gate" == "BLOCKED" ]] && color=$R

    printf "${color}%-12s %-14s %-12s %-10s${N}\n" "$agent" "$wp" "$gate" "$logsize"
  done

  echo ""
  echo -e "${C}Docker services:${N}"
  docker-compose ps 2>/dev/null | tail -n +3 || echo "  Not running"
  echo ""
}

# ── Accept a gate (Master calls this after reviewing evidence) ────────────────
accept_gate() {
  local agent="$1"
  echo "ACCEPTED" > "$PIDS_DIR/${agent}.gate"
  echo -e "${G}✓ Gate accepted for $agent. Dependent agents can now start.${N}"
  echo ""
  # Show what just unlocked
  for a in AGENT-02 AGENT-03 AGENT-07 AGENT-08 AGENT-05 AGENT-06 AGENT-04 AGENT-11 AGENT-12; do
    local deps="${DEPS[$a]:-}"
    if echo "$deps" | grep -q "$agent"; then
      if check_deps "$a" 2>/dev/null; then
        echo -e "  ${G}→ $a is now unblocked (run: bash factory/orchestrate.sh start $a)${N}"
      fi
    fi
  done
}

# ── Kill an agent ─────────────────────────────────────────────────────────────
kill_agent() {
  local agent="$1"
  if [ -f "$PIDS_DIR/${agent}.pid" ]; then
    kill "$(cat $PIDS_DIR/${agent}.pid)" 2>/dev/null || true
    rm -f "$PIDS_DIR/${agent}.pid"
    echo -e "${A}✓ $agent stopped${N}"
  else
    echo "$agent: no PID file found (may be running in a terminal window)"
  fi
}

# ── Main dispatcher ───────────────────────────────────────────────────────────
CMD="${1:-help}"
shift || true

case "$CMD" in
  start)
    launch_agent "$1"
    ;;
  start-lane-a)
    echo -e "${C}Starting Lane A (R101-03, R101-07, R101-08 in parallel)...${N}"
    launch_agent "AGENT-03"
    launch_agent "AGENT-07"
    launch_agent "AGENT-08"
    ;;
  start-lane-b)
    echo -e "${C}Starting Lane B (R101-05)...${N}"
    launch_agent "AGENT-05"
    ;;
  start-lane-c)
    echo -e "${C}Starting Lane C (R101-06 + R101-04 in parallel)...${N}"
    launch_agent "AGENT-06"
    launch_agent "AGENT-04"
    ;;
  start-lane-d)
    echo -e "${C}Starting Lane D (R101-11 + R101-12 in parallel)...${N}"
    launch_agent "AGENT-11"
    launch_agent "AGENT-12"
    ;;
  accept)
    accept_gate "$1"
    ;;
  status)
    show_status
    ;;
  logs)
    tail -f "$LOGS_DIR/${1}.log" 2>/dev/null || echo "No log found for $1"
    ;;
  kill)
    kill_agent "$1"
    ;;
  kill-all)
    for agent in AGENT-02 AGENT-03 AGENT-04 AGENT-05 AGENT-06 AGENT-07 AGENT-08 AGENT-11 AGENT-12; do
      kill_agent "$agent"
    done
    ;;
  help|*)
    echo ""
    echo -e "${C}HEER Factory Orchestrator${N}"
    echo ""
    echo "  bash factory/orchestrate.sh start AGENT-02      # start one agent"
    echo "  bash factory/orchestrate.sh start-lane-a        # R101-03+07+08 parallel"
    echo "  bash factory/orchestrate.sh start-lane-b        # R101-05"
    echo "  bash factory/orchestrate.sh start-lane-c        # R101-06+04 parallel"
    echo "  bash factory/orchestrate.sh start-lane-d        # R101-11+12 parallel"
    echo "  bash factory/orchestrate.sh accept AGENT-02     # Master accepts a gate"
    echo "  bash factory/orchestrate.sh status              # show all agent status"
    echo "  bash factory/orchestrate.sh logs AGENT-02       # tail agent log"
    echo "  bash factory/orchestrate.sh kill AGENT-02       # stop one agent"
    echo "  bash factory/orchestrate.sh kill-all            # stop everything"
    echo ""
    ;;
esac
