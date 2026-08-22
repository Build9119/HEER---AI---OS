# AGENT-12 — Voice Interface & Operator Console
# Work package: R101-12
# Authorized when: R101-02 + R101-03 + R101-08 VERIFIED by Master

## Owns

  services/voice-interface/
  console/heer-console.html   ← wire to live services ONLY — do not restyle.
                                 See console/README.md for what "wire" means.
  docker-compose.yml (voice-interface service addition only)
  .github/workflows/ci.yml (add voice-interface test job only)

## HARD RULE on the console

console/heer-console.html's visual design (Tactical Glass HUD, ring-to-layer
mapping, LOCK/RANGE readouts, pink bezel, tuned voice, activation tones) is
LOCKED. The visual system is the result of deliberate design decisions
documented in console/README.md and docs/CONSOLE_DESIGN.md.

You may ONLY change console/heer-console.html to:
  - Replace mocked data with real API calls to live services.
  - Wire the PTT button to the real voice-interface service endpoint.
  - Wire the governance feed to real Policy Engine decision events.
  - Wire mission progress bars to real mission-engine state.

Any other change to the console — color, layout, font, animation, copy —
is out of scope. Propose it separately to Master.

## Scope

- [ ] STT/TTS gateway service behind a swappable interface — no vendor
      hardcoded into business logic. Local dev: browser Web Speech API
      (already in console) is acceptable; the service layer should be
      abstracted so a real provider (Deepgram, Google STT) can be swapped
      in without changing governance code.
- [ ] Every voice/text command produces the same
      {identity, action, resource, context} shape and calls the Policy
      Engine decision API — identical path to any other channel.
      Prove this with a test (same input → same decision, voice vs API).
- [ ] Spoken confirmation step for Control-class skills (ADR-101-12):
      a Control-class action is not executed until HEER speaks a confirmation
      prompt and the operator responds affirmatively.
- [ ] Gated skills return Exception from Policy Engine, not execution.
      Prove with a test.
- [ ] Wire console to live services (replace mocked data).

## Critical tests (Gate acceptance line, docs/PLAN.md Phase 7.75 + ROADMAP.md red-team)

1. Parity test: same action via voice and via direct API call produces
   identical Policy Engine decisions (same decision shape, same result type).
2. Confirmation test: a Control-class skill invoked by voice is blocked
   until the confirmation step completes — prove the execution doesn't fire
   before confirmation.
3. Gated-skill test: a Gated skill invoked by voice returns an Exception,
   not an execution result.

Plus the ROADMAP.md red-team requirement:
4. Audio isolation check: prove no raw audio leaves the client — show a
   network trace (browser DevTools HAR or equivalent) demonstrating only
   transcribed text is transmitted, not audio bytes.

All four in raw evidence.
