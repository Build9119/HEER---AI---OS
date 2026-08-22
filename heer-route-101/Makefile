# HEER ROUTE 101 — Factory Makefile
# Run from repo root: make <target>
# This is the Master control panel — not for agents to use directly.

.PHONY: help bootstrap guard-02 guard-03 guard-04 guard-05 guard-06 \
        guard-07 guard-08 guard-11 guard-12 \
        gate-02 gate-03 gate-04 gate-05 gate-06 \
        gate-07 gate-08 gate-11 gate-12 \
        up down ps reset-r101-02 status prompt-02 prompt-03 \
        prompt-04 prompt-05 prompt-06 prompt-07 prompt-08 \
        prompt-11 prompt-12

# ── Colours ────────────────────────────────────────────────────────────────────
CYAN  := \033[0;36m
GREEN := \033[0;32m
AMBER := \033[0;33m
RESET := \033[0m

help: ## Show this help
	@echo ""
	@echo "$(CYAN)HEER ROUTE 101 — Factory Control$(RESET)"
	@echo ""
	@echo "$(GREEN)Setup$(RESET)"
	@grep -E '^(bootstrap|up|down|ps|status):' Makefile | \
		awk -F: '{printf "  make %-20s %s\n", $$1, $$3}'
	@echo ""
	@echo "$(GREEN)Session guards (run before each agent session)$(RESET)"
	@echo "  make guard-XX     e.g. make guard-02"
	@echo ""
	@echo "$(GREEN)Gate checks (run before each Gate report)$(RESET)"
	@echo "  make gate-XX      e.g. make gate-02"
	@echo ""
	@echo "$(GREEN)Prompts (print the agent's Cline prompt)$(RESET)"
	@echo "  make prompt-XX    e.g. make prompt-02"
	@echo ""
	@echo "$(GREEN)Recovery$(RESET)"
	@grep -E '^reset-' Makefile | \
		awk -F: '{printf "  make %-20s\n", $$1}'
	@echo ""

# ── Setup ──────────────────────────────────────────────────────────────────────
bootstrap: ## Run the factory bootstrap (once, from a clean state)
	@bash factory/bootstrap.sh

up: ## Start all Docker services
	@echo "$(CYAN)Starting HEER services...$(RESET)"
	@docker-compose up -d
	@sleep 8
	@docker-compose ps

down: ## Stop all Docker services
	@echo "$(AMBER)Stopping HEER services...$(RESET)"
	@docker-compose down

ps: ## Show Docker service status
	@docker-compose ps

status: ## Show factory dashboard (git log + docker ps + agent status)
	@echo ""
	@echo "$(CYAN)── Git status ──────────────────────────────$(RESET)"
	@git log --oneline -8
	@echo ""
	@echo "$(CYAN)── Docker services ─────────────────────────$(RESET)"
	@docker-compose ps 2>/dev/null || echo "Docker not running"
	@echo ""
	@echo "$(CYAN)── Factory dashboard ───────────────────────$(RESET)"
	@cat factory/DASHBOARD.md | grep -A 30 "## Current status"
	@echo ""

# ── Session guards ─────────────────────────────────────────────────────────────
guard-02: ## Run session guard for AGENT-02
	@bash factory/session-guard.sh AGENT-02

guard-03: ## Run session guard for AGENT-03
	@bash factory/session-guard.sh AGENT-03

guard-04: ## Run session guard for AGENT-04
	@bash factory/session-guard.sh AGENT-04

guard-05: ## Run session guard for AGENT-05
	@bash factory/session-guard.sh AGENT-05

guard-06: ## Run session guard for AGENT-06
	@bash factory/session-guard.sh AGENT-06

guard-07: ## Run session guard for AGENT-07
	@bash factory/session-guard.sh AGENT-07

guard-08: ## Run session guard for AGENT-08
	@bash factory/session-guard.sh AGENT-08

guard-11: ## Run session guard for AGENT-11
	@bash factory/session-guard.sh AGENT-11

guard-12: ## Run session guard for AGENT-12
	@bash factory/session-guard.sh AGENT-12

# ── Gate checks ────────────────────────────────────────────────────────────────
gate-02: ## Run gate check for AGENT-02 (R101-02)
	@bash factory/gate-check.sh AGENT-02

gate-03: ## Run gate check for AGENT-03
	@bash factory/gate-check.sh AGENT-03

gate-04: ## Run gate check for AGENT-04
	@bash factory/gate-check.sh AGENT-04

gate-05: ## Run gate check for AGENT-05
	@bash factory/gate-check.sh AGENT-05

gate-06: ## Run gate check for AGENT-06
	@bash factory/gate-check.sh AGENT-06

gate-07: ## Run gate check for AGENT-07
	@bash factory/gate-check.sh AGENT-07

gate-08: ## Run gate check for AGENT-08
	@bash factory/gate-check.sh AGENT-08

gate-11: ## Run gate check for AGENT-11
	@bash factory/gate-check.sh AGENT-11

gate-12: ## Run gate check for AGENT-12
	@bash factory/gate-check.sh AGENT-12

# ── Prompts ────────────────────────────────────────────────────────────────────
prompt-02: ## Print AGENT-02's Cline prompt (copy-paste into Cline)
	@echo ""
	@echo "$(CYAN)══ AGENT-02 Cline prompt — copy everything below ══$(RESET)"
	@echo ""
	@cat factory/prompts/AGENT-02.md
	@echo ""
	@echo "$(CYAN)══ End of prompt ══$(RESET)"

prompt-03:
	@echo "" && cat factory/prompts/AGENT-03.md && echo ""

prompt-04:
	@echo "" && cat factory/prompts/AGENT-04.md && echo ""

prompt-05:
	@echo "" && cat factory/prompts/AGENT-05.md && echo ""

prompt-06:
	@echo "" && cat factory/prompts/AGENT-06.md && echo ""

prompt-07:
	@echo "" && cat factory/prompts/AGENT-07.md && echo ""

prompt-08:
	@echo "" && cat factory/prompts/AGENT-08.md && echo ""

prompt-11:
	@echo "" && cat factory/prompts/AGENT-11.md && echo ""

prompt-12:
	@echo "" && cat factory/prompts/AGENT-12.md && echo ""

# ── Recovery ───────────────────────────────────────────────────────────────────
reset-r101-02: ## Reset R101-02 work to last known good state (use after session corruption)
	@echo "$(AMBER)⚠  This will discard uncommitted R101-02 changes.$(RESET)"
	@echo "$(AMBER)   Press Ctrl+C to cancel, Enter to continue.$(RESET)"
	@read confirm
	@git checkout -- docker-compose.yml 2>/dev/null || true
	@git clean -fd infra/ tests/tenant-isolation/ 2>/dev/null || true
	@echo "$(GREEN)✓ Reset complete. Run make status to verify.$(RESET)"

logs: ## Tail all docker-compose logs
	@docker-compose logs -f --tail=50

# ── Multi-agent factory ────────────────────────────────────────────────────────
factory-status: ## Show all agent statuses + docker health
	@bash factory/orchestrate.sh status

start-02: ## Start AGENT-02 (R101-02 Identity & Tenant)
	@bash factory/orchestrate.sh start AGENT-02

start-lane-a: ## Start Lane A in parallel (R101-03 + R101-07 + R101-08)
	@bash factory/orchestrate.sh start-lane-a

start-lane-b: ## Start Lane B (R101-05 AI Registry)
	@bash factory/orchestrate.sh start-lane-b

start-lane-c: ## Start Lane C in parallel (R101-06 + R101-04)
	@bash factory/orchestrate.sh start-lane-c

start-lane-d: ## Start Lane D in parallel (R101-11 + R101-12)
	@bash factory/orchestrate.sh start-lane-d

accept-02: ## Master accepts AGENT-02 gate — unlocks Lane A
	@bash factory/orchestrate.sh accept AGENT-02

accept-lane-a: ## Master accepts Lane A gates — unlocks Lane B
	@bash factory/orchestrate.sh accept AGENT-03
	@bash factory/orchestrate.sh accept AGENT-07
	@bash factory/orchestrate.sh accept AGENT-08

accept-lane-b: ## Master accepts Lane B — unlocks Lane C+D
	@bash factory/orchestrate.sh accept AGENT-05

accept-lane-c: ## Master accepts Lane C gates — unlocks Lane D
	@bash factory/orchestrate.sh accept AGENT-06
	@bash factory/orchestrate.sh accept AGENT-04

kill-all-agents: ## Emergency stop — kill all running agents
	@bash factory/orchestrate.sh kill-all
