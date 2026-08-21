# console

The operator-facing dashboard (voice-first, per ADR-101-12). `heer-console.html`
is the visual/interaction prototype, now built on a Stitch-generated visual
system ("Tactical Glass" — see the design notes below) with the working parts
wired underneath: real conversational AI, governance-synced ring lighting,
tuned voice output, and synthesized activation tones. Runs on mocked
governance/mission data; Phase 7.75 in docs/PLAN.md wires it to live services.

Visual system: Three.js 3D voice core with tick-mark radar rings (governance /
orchestration / execution), a WebGL shader background (starfield, scanlines,
vignette, grid), corner-reticle "HUD panel" framing, and module-numbered
panels (MODULE_02 // COMM_LINK, etc). Fonts: Space Grotesk (headers), Hanken
Grotesk (body), JetBrains Mono (all data/telemetry/timestamps). Sharp 0px
radius throughout, segmented block progress bars instead of pills — see
docs/CONSOLE_DESIGN.md for the full token/style reference this was built from.

Functional wiring (not just visual): the three rings light up in the actual
sequence governance → orchestration → execution as a real command is
evaluated — not decorative idle animation. Typed or spoken input goes to
Claude in character as HEER (ADR-101-12: voice/text have no elevated
authority, same path either way). Push-to-talk uses the browser's
SpeechRecognition API; voice output is tuned for a deeper, calmer register via
SpeechSynthesis voice selection; activation/thinking/response tones are
synthesized with WebAudio, no external audio files.

## v6 note

Added a decorative "reticle-accent" pink (#ff5fd8) as a purely atmospheric outer
bezel + LOCK-status highlight, echoing the two-tone look from the Stitch
screenshot export. Deliberately kept separate from the semantic governance
rings — blue/violet/teal still mean governance/orchestration/execution
throughout this repo's diagrams and docs; the pink never overloads that.
