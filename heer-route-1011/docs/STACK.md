# Recommended technology stack

Picked for open standards and audit-evidence generation over vendor convenience —
see the Master Architecture doc Section 2 (governance mapping) for why that trade-off
matters for regulated deployments.

| Component | Pick | Why |
|---|---|---|
| Human/app identity | Keycloak or Ory (Kratos + Hydra) | OIDC-native, self-hostable |
| Workload identity | SPIFFE/SPIRE | Short-lived, attested identity — required by ADR-101-02 |
| Secrets | HashiCorp Vault | Dynamic, short-TTL credentials |
| Policy evaluation | Open Policy Agent (OPA) / Rego | Standard for exactly this decision pattern |
| Exceptions + Mission workflow | Temporal.io | Durable state machines, SLA timers, human-in-loop signals — one engine for both |
| Agent reasoning layer | LangGraph or thin custom wrapper | Proposes the graph; Temporal executes it; OPA gates every node |
| Model gateway | LiteLLM or Portkey | Model-agnostic, per-tenant rate limits and logging |
| Primary datastore | PostgreSQL (RLS) | Tenant isolation enforced at the data layer |
| Vector/semantic memory | pgvector or Qdrant | Start with pgvector; split out only if scale demands it |
| Event backbone | Apache Kafka (Redpanda for local dev) | Correlation-ID propagation across all services |
| Immutable audit store | S3 Object Lock (WORM) | Tamper-evident, hash-chained records |
| Audit query layer | ClickHouse | Fast per-tenant queries; Postgres is an acceptable downgrade pre-scale |
| Runtime | Kubernetes | Per-tenant resource isolation |
| Service mesh (mTLS) | Istio or Linkerd | Enforces mTLS + per-request authz at the network layer |
| Tracing | OpenTelemetry | Standard correlation-ID propagation |
| IaC | Terraform | |
| GitOps | ArgoCD | |
| CI | GitHub Actions / GitLab CI | |
| Observability | Grafana + Prometheus + Loki | |
