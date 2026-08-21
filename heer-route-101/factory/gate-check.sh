#!/usr/bin/env bash
# HEER ROUTE 101 — Gate check
# Cline runs this before submitting any Gate acceptance report.
# Usage: bash factory/gate-check.sh AGENT-02
# It does NOT replace Master review — it surfaces obvious gaps first.

set -euo pipefail
AGENT_ID="${1:-UNKNOWN}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   HEER Gate Check — $AGENT_ID            "
echo "╚══════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0
WARN=0

check_ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
check_fail() { echo "  ✗ FAIL: $1"; echo "    → $2"; FAIL=$((FAIL+1)); }
check_warn() { echo "  ⚠  WARN: $1"; echo "    → $2"; WARN=$((WARN+1)); }

# ── Universal checks (all agents) ────────────────────────────────────────────
echo "[ Universal checks ]"

# No status-vocabulary violations in any committed file
if git log --oneline -5 | grep -iE "\bDONE\b|\bCOMPLETE\b|\bFINISHED\b" > /dev/null 2>&1; then
  check_warn "Commit messages" "Some commits use 'done/complete/finished' — use IMPLEMENTED/TESTED/VERIFIED instead"
else
  check_ok "Commit message vocabulary"
fi

# .clinerules still present and unmodified
if [ -s ".clinerules" ]; then
  check_ok ".clinerules intact"
else
  check_fail ".clinerules" "Missing or empty — must not be removed during implementation"
fi

# console/ not modified (unless this is AGENT-12)
if [ "$AGENT_ID" != "AGENT-12" ]; then
  if git diff --name-only HEAD 2>/dev/null | grep -q "^console/"; then
    check_fail "Console untouched" "console/ was modified — only AGENT-12 is authorized to touch it"
  else
    check_ok "Console untouched"
  fi
fi

# policies/ not directly written (unless AGENT-03 or AGENT-11's proposal path)
if [ "$AGENT_ID" = "AGENT-11" ]; then
  if git diff --name-only HEAD 2>/dev/null | grep -q "^policies/" && \
     ! git diff --name-only HEAD 2>/dev/null | grep -q "^proposals/"; then
    check_warn "Learning loop write path" "policies/ was modified directly — AGENT-11 should only write to proposals/"
  fi
fi

# ── Agent-specific checks ─────────────────────────────────────────────────────
echo ""
echo "[ Agent-specific checks for $AGENT_ID ]"

case "$AGENT_ID" in

AGENT-02)
  # RLS check: every tenant-scoped table must have an RLS policy
  echo "  Checking RLS coverage..."
  if command -v psql &> /dev/null; then
    TABLES_WITHOUT_RLS=$(psql postgresql://heer:heer_dev_only@localhost:5432/heer -t -c \
      "SELECT tablename FROM pg_tables WHERE schemaname='public' AND rowsecurity=false;" \
      2>/dev/null | grep -v "^$" | wc -l | tr -d ' ')
    [ "$TABLES_WITHOUT_RLS" -eq 0 ] \
      && check_ok "All tenant tables have RLS" \
      || check_fail "RLS coverage" "$TABLES_WITHOUT_RLS table(s) without RLS — CI check would fail"
  else
    check_warn "RLS check" "psql not available locally — verify manually"
  fi

  # Tenant-isolation test script must exist and be executable
  [ -x "tests/tenant-isolation/test_tenant_isolation.sh" ] \
    && check_ok "Tenant isolation test executable" \
    || check_fail "Tenant isolation test" "tests/tenant-isolation/test_tenant_isolation.sh not found or not executable"

  # SPIFFE/SPIRE config must exist
  [ -f "infra/spire/server/server.conf" ] && [ -f "infra/spire/agent/agent.conf" ] \
    && check_ok "SPIRE config files present" \
    || check_fail "SPIRE config" "infra/spire/server/server.conf or agent.conf missing"

  # No static credentials (grep for common patterns)
  if grep -r "api_key\s*=\s*['\"][^'\"]\|password\s*=\s*['\"][^'\"]\|secret\s*=\s*['\"][^'\"]" \
     infra/ 2>/dev/null | grep -v "heer_dev_only\|placeholder\|example\|test"; then
    check_warn "Static credentials scan" "Possible hardcoded credentials found above — review before Gate"
  else
    check_ok "No obvious static credentials"
  fi
  ;;

AGENT-03)
  # Decision API: all three decision types must have tests
  if find services/policy-engine -name "*.test.*" | xargs grep -l "permit\|deny\|exception" 2>/dev/null | head -1 | grep -q .; then
    check_ok "Decision type tests (permit/deny/exception) exist"
  else
    check_fail "Decision type coverage" "No test file covers all three decision types"
  fi

  # At least two .rego files in policies/
  REGO_COUNT=$(find policies -name "*.rego" 2>/dev/null | wc -l | tr -d ' ')
  [ "$REGO_COUNT" -ge 2 ] \
    && check_ok "Rego rules present ($REGO_COUNT files)" \
    || check_fail "Rego rules" "Need at least 2 .rego files — found $REGO_COUNT"

  # decision_id must appear in the service code
  grep -r "decision_id" services/policy-engine/src/ 2>/dev/null | grep -q . \
    && check_ok "decision_id referenced in service code" \
    || check_fail "decision_id" "decision_id not found in services/policy-engine/src/ — every decision must be logged with one"
  ;;

AGENT-04)
  # State machine states must all be present
  STATES="Raised Triaged Assigned Resolved Closed"
  for state in $STATES; do
    grep -r "$state" services/exceptions-node/src/ 2>/dev/null | grep -q . \
      && check_ok "State '$state' present in code" \
      || check_fail "State machine" "State '$state' not found in services/exceptions-node/src/"
  done

  # SLA timer must exist
  grep -r "sla\|SLA\|deadline" services/exceptions-node/src/ 2>/dev/null | grep -q . \
    && check_ok "SLA logic referenced" \
    || check_fail "SLA timer" "No SLA/deadline logic found — required by ADR-101-04"
  ;;

AGENT-05)
  # Unregistered agent must return Deny
  grep -r "unregistered\|DENY\|deny" services/ai-registry/src/ 2>/dev/null | grep -q . \
    && check_ok "Deny-for-unregistered referenced in code" \
    || check_warn "Registry-gated execution" "Could not confirm unregistered agents get Deny — verify test covers this"

  # All mandatory registry fields must appear in schema
  FIELDS="owner purpose tenant_scope model_version risk_tier data_classes human_oversight last_review_date"
  for field in $FIELDS; do
    grep -r "$field" services/ai-registry/src/ infra/postgres/migrations/ 2>/dev/null | grep -q . \
      && check_ok "Field '$field' in schema/code" \
      || check_fail "Registry fields" "Mandatory field '$field' not found"
  done
  ;;

AGENT-06)
  # Task graph must be immutable once started
  grep -r "immut\|version\|new.*graph\|graph.*version" services/mission-engine/src/ 2>/dev/null | grep -q . \
    && check_ok "Graph immutability / versioning referenced" \
    || check_fail "Graph immutability" "No immutability or versioning logic found — mid-flight changes must create a new version"

  # Per-node policy check must exist
  grep -r "policy\|decision\|permit" services/mission-engine/src/ 2>/dev/null | grep -q . \
    && check_ok "Per-node policy check referenced" \
    || check_fail "Per-node policy" "No policy check found — each task node requires its own Permit decision"
  ;;

AGENT-11)
  # No direct write to policies/ from service code
  if grep -r "writeFile\|fs\.write\|open.*w\|>\|appendFile" services/learning-loop/src/ 2>/dev/null \
     | grep -i "polic" | grep -qv "proposals"; then
    check_fail "No-write rule" "Learning loop appears to write directly to policies/ — violates ADR-101-11"
  else
    check_ok "No direct write to policies/ detected"
  fi

  # Proposals must include source_correlation_ids
  grep -r "source_correlation_ids\|correlation_id" services/learning-loop/src/ 2>/dev/null | grep -q . \
    && check_ok "Provenance (source_correlation_ids) referenced" \
    || check_fail "Provenance" "source_correlation_ids not found — every proposal must cite its evidence"
  ;;

AGENT-12)
  # Voice must call same Policy Engine path as API
  grep -r "policy\|decision\|permit" services/voice-interface/src/ 2>/dev/null | grep -q . \
    && check_ok "Policy Engine called from voice interface" \
    || check_fail "Voice governance" "Voice interface doesn't appear to call Policy Engine — ADR-101-12 requires same path as API"

  # Console HTML must not have been structurally altered (check file size stability)
  CONSOLE_SIZE=$(wc -c < console/heer-console.html 2>/dev/null || echo 0)
  if [ "$CONSOLE_SIZE" -lt 10000 ]; then
    check_warn "Console file size" "console/heer-console.html is suspiciously small ($CONSOLE_SIZE bytes) — may have been truncated"
  else
    check_ok "Console file size looks intact ($CONSOLE_SIZE bytes)"
  fi
  ;;

*)
  echo "  ⚠  No agent-specific checks configured for $AGENT_ID"
  ;;
esac

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo " Gate check: $PASS passed, $FAIL failed, $WARN warnings"
echo "══════════════════════════════════════════════════════"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo " ✗ GATE BLOCKED — fix failures before submitting to Master."
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo " ⚠  Gate has warnings — include them in your Master report."
  echo "   Master makes the final call, not this script."
  exit 0
else
  echo " ✓ Gate checks clear — submit evidence report to Master for final review."
  echo "   This script does not replace Master review."
  exit 0
fi
