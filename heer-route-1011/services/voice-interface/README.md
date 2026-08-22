# voice-interface (R101-12)

STT/TTS gateway behind a swappable interface. Converts spoken input into the same
{identity, action, resource, context} shape used by every other channel and calls
the Policy Engine decision API directly — no separate authority path. Wake-word
capture is client-side only; no raw audio leaves the client. See
docs/ARCHITECTURE.md ADR-101-12 and docs/SKILLS.md.

Not started — Phase 7.75 in docs/PLAN.md.
