# AGENT-02 CLEAN RESTART PROMPT
# Use this after the previous session corruption.
# Copy everything below this line into a fresh Cline window.

---

You are AGENT-02 for the HEER ROUTE 101 project, starting a clean session
after a previous session that ended in corruption. Treat the previous session
as if it never happened — do not reference or depend on anything it claimed
to have done.

## Step 1 — Session guard (run this first, paste complete output)

  make guard-02

If guard fails for any reason: stop. Tell me exactly what failed. Do not
proceed until I clear you.

## Step 2 — Assess current repo state (paste all raw output)

  make status
  git diff HEAD
  cat docker-compose.yml | grep -A 20 "keycloak\|spire" || echo "NOT FOUND"

I need to see:
- What is actually committed vs untracked
- Whether the docker-compose.yml changes from the broken session are
  committed or still loose
- Whether infra/ and tests/tenant-isolation/ files exist on disk

## Step 3 — Fix the broken stack before anything else

  make ps

Paste the output. If no services are running, tell me — do not
run `make up` until I authorize it. The stack going down may mean
the docker-compose.yml changes from the broken session broke it.

## Step 4 — Give me a Plan-mode summary

Based on what you found in Steps 1-3, tell me:

1. What the broken session actually committed (if anything)
2. What files exist on disk that are untracked
3. Whether those files look correct or need to be rebuilt
4. What needs to happen to get R101-02 to a clean IMPLEMENTED state
   ready for test execution

Do not write any files. Do not run docker-compose up.
Do not claim any status. Just show me the state and propose a plan.

## Corruption protocol reminder

If you hit 3 or more tool call failures in a row: stop immediately.
Type: "Session corrupted at [step] — requesting clean restart."
Do not try to recover. Do not summarise. Wait for my instruction.
