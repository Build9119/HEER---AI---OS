# learning-loop (R101-11)

Reads audit events (R101-08) and exception resolutions (R101-04), writes only
provenanced proposal artifacts (policy-change PRs, task-graph template candidates,
registry review flags). Never writes directly to policies/, task-graph templates,
or an agent's risk-tier/model-version fields. See docs/ARCHITECTURE.md ADR-101-11.

Not started — Phase 7.5 in docs/PLAN.md. Depends on R101-08 and R101-04.
