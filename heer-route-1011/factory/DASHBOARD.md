# HEER ROUTE 101 — Master Coordination Dashboard

Update this file after every Gate review. This is the single source of truth
for what's running, what's blocked, and what's next. Agents read it; only
Master writes it.

## Current status

| Agent | Work package | Status | Gate accepted | Blocked by |
|---|---|---|---|---|
| AGENT-00 | R101-00 Repo baseline | VERIFIED | yes | — |
| AGENT-02 | R101-02 Identity/tenant | IN PROGRESS | no | — |
| AGENT-03 | R101-03 Policy Engine | NOT STARTED | no | R101-02 |
| AGENT-04 | R101-04 Exceptions Node | NOT STARTED | no | R101-02 + R101-03 |
| AGENT-05 | R101-05 AI Registry | NOT STARTED | no | R101-02 + R101-03 |
| AGENT-06 | R101-06 Mission Engine | NOT STARTED | no | R101-02 + R101-03 + R101-05 |
| AGENT-07 | R101-07 Worker security | NOT STARTED | no | R101-02 |
| AGENT-08 | R101-08 Audit | NOT STARTED | no | R101-02 |
| AGENT-11 | R101-11 Learning loop | NOT STARTED | no | R101-08 + R101-04 |
| AGENT-12 | R101-12 Voice/console | NOT STARTED | no | R101-02 + R101-03 + R101-08 |

## What can start right now

- AGENT-02 is in progress — finish and get Gate 1 accepted first.

## What unlocks after AGENT-02 is Gate-accepted

Lane A (can run in parallel — open three Cline windows):
  AGENT-03 (Policy Engine)
  AGENT-07 (Worker security)
  AGENT-08 (Audit)

## How to start an agent

1. Open a new VS Code window (File → New Window) pointed at the repo root.
2. Open Cline in that window.
3. Paste the contents of factory/prompts/AGENT-XX.md as the first message.
4. Wait for the Plan-mode summary before approving Act mode.
5. Review the Act-mode evidence report here (with Master) before accepting the Gate.
6. Update this dashboard after Gate acceptance.

## Active issues

- AGENT-02: .clinerules was missing from the repo during the first Plan-mode
  session. Restore it from the scaffold zip before AGENT-02's Act mode runs.
  Command: unzip -p ~/Downloads/heer-route-101-repo-scaffold.zip
           heer-route-101/.clinerules > .clinerules
  Then: git add .clinerules && git commit -m "[R101-02] restore .clinerules"

## Gate log

| Date | Agent | Gate | Decision | Notes |
|---|---|---|---|---|
| 2026-08-20 | AGENT-00 | Gate 1 | ACCEPTED | CI IMPLEMENTED ONLY (no remote). Infrastructure + correlation-id VERIFIED. |
| — | AGENT-02 | Gate 1 | PENDING | Awaiting honest Plan-mode + .clinerules restore |
