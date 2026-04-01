# DCM — Data Center Management

Data Center Management (DCM) is an open-source governing framework for enterprise on-premises and sovereign cloud infrastructure. It provides a hyperscaler-like cloud experience — the operational model and self-service capabilities of a public cloud provider — on infrastructure that organizations own and control.

**License:** Apache 2.0

---

## What DCM Is

DCM is the governing control plane that sits above provisioning tools, automation platforms, and infrastructure systems — making them coherent, governed, and self-service. It is not a deployment tool or a configuration manager. It is the management plane that connects them.

**[Full project description →](project-overview.md)** — what DCM is, what it does, why, who benefits, and where it operates.

---

## Architecture in One Sentence

DCM is built on three foundational abstractions — **Data**, **Provider**, and **Policy** — connected by a policy-driven event loop. Every concept maps to one of these three. See [00-foundations.md](docs/data-model/00-foundations.md).

---

## Repository Structure

```
dcm/
├── README.md                          ← You are here
├── project-overview.md                ← What DCM is, why, who, where
├── DCM-Capabilities-Matrix.md         ← 299 capabilities across 38 domains
├── DISCUSSION-TOPICS.md               ← Active design discussions and decisions
├── LICENSE                            ← Apache 2.0
│
├── docs/
│   ├── data-model/                    ← 55 architecture documents (the core)
│   │   ├── 00-foundations.md          ← START HERE — the three abstractions
│   │   ├── 00-design-priorities.md    ← Decision hierarchy for all contributors
│   │   ├── 00-context-and-purpose.md  ← Problem statement, scope, data model objectives
│   │   ├── 01–49*.md                  ← Complete data model specification
│   │   ├── A-provider-contract.md     ← Unified Provider base contract + 12 typed extensions
│   │   └── B-policy-contract.md       ← Unified Policy base contract + 8 output schemas
│   │
│   ├── specifications/                ← 15 specification documents
│   │   ├── consumer-api-spec.md       ← Consumer-facing API specification
│   │   ├── dcm-admin-api-spec.md      ← Platform admin API specification
│   │   ├── dcm-flow-gui-spec.md       ← Flow GUI (policy authoring) specification
│   │   └── ...                        ← GUI specs, OPA integration, registration, etc.
│   │
│   └── taxonomy/
│       └── DCM-Taxonomy.md            ← Vocabulary, anti-vocabulary, domain prefixes
│
├── schemas/
│   ├── dcm-common.json                ← Shared types (UUID, datetime, semver, classification)
│   ├── entities/dcm-entities.json     ← Entity type definitions and lifecycle states
│   ├── events/dcm-events.json         ← 88 event payload schemas across 21 domains
│   ├── policies/dcm-policies.json     ← 8 policy type definitions with output schemas
│   ├── providers/dcm-providers.json   ← 12 provider type definitions
│   ├── resource-types/                ← Resource type specification template
│   └── openapi/
│       ├── dcm-consumer-api.yaml      ← 63 paths — consumer-facing
│       ├── dcm-admin-api.yaml         ← 57 paths — platform administration
│       ├── dcm-operator-api.yaml      ← 5 paths — provider operator interface
│       └── dcm-provider-callback-api.yaml ← 7 paths — provider callback
│
└── ai/
    └── DCM-AI-PROMPT.md               ← 104-section AI model context (load for AI-assisted work)
```

---

## Reading Order

### For architecture evaluation (start here)

| Order | Document | What you'll learn |
|-------|----------|-------------------|
| 1 | [project-overview.md](project-overview.md) | What DCM is, the problem it solves, who benefits, where it operates |
| 2 | [00-foundations.md](docs/data-model/00-foundations.md) | The three abstractions — Data, Provider, Policy — and how they connect |
| 3 | [00-design-priorities.md](docs/data-model/00-design-priorities.md) | Decision hierarchy that governs all design trade-offs |
| 4 | [A-provider-contract.md](docs/data-model/A-provider-contract.md) | Unified Provider base contract + 12 typed capability extensions |
| 5 | [B-policy-contract.md](docs/data-model/B-policy-contract.md) | Unified Policy base contract + 8 output schemas |
| 6 | [DCM-Capabilities-Matrix.md](DCM-Capabilities-Matrix.md) | What DCM can do — 299 capabilities across 38 domains |

### For deep technical review

| Range | Coverage |
|-------|---------|
| 00–05 | Context, foundations, entity types, four states, layering, ownership, resource types |
| 06–12 | Resource/service entities, dependencies, grouping, relationships, information providers, storage, audit |
| 13–19 | Ingestion, policy profiles, universal groups, universal audit, deployment, webhooks, auth providers |
| 20–27 | Registry governance, advanced information providers, federation, notifications, operational models, control plane, accreditation, governance matrix |
| 28–35 | Federated contribution, scoring model, meta provider, credential provider, authority tier, event catalog, API versioning, session revocation |
| 36–42 | Internal component auth, scheduled requests, dependency graph, self-health, standards catalog, operational reference, ITSM integration |
| 43–49 | Provider callback auth, Kessel evaluation, consistency review, workload analysis, accreditation monitor, location topology, implementation specifications |

### For API review

Start with [consumer-api-spec.md](docs/specifications/consumer-api-spec.md) and [dcm-admin-api-spec.md](docs/specifications/dcm-admin-api-spec.md), then validate against the OpenAPI schemas in `schemas/openapi/`.

---

## Key Numbers

| Metric | Value |
|--------|-------|
| Foundational abstractions | 3 (Data, Provider, Policy) |
| Provider types | 12 (unified base contract + typed capability extensions) |
| Policy types | 8 (unified base contract + typed output schemas) |
| Entity lifecycle states | 4 (Intent · Requested · Realized · Discovered) |
| Capabilities | 299 across 38 domains |
| Data model documents | 55 |
| Specifications | 15 |
| Consumer API paths | 63 |
| Admin API paths | 57 |
| Unresolved architectural questions | 0 |

---

## Status

**Architecture:** Complete — 0 unresolved questions — ready for implementation review.

**Implementation:** Not in this repository. See [dcm-project/dcm-examples](https://github.com/dcm-project/dcm-examples) for reference implementations.

**Website:** See [dcm-project/dcm-website](https://github.com/dcm-project/dcm-website) for the Hugo documentation site.

---

## How DCM Works

DCM's runtime is a **policy-driven event loop**: every data state change triggers Policy Engine evaluation, policies produce typed outputs (approve/halt/enrich/route/recover), outputs invoke Providers or produce new Data, and new Data triggers new events. There is no hard-coded pipeline — the pipeline is the sum of active Policies.

A request flows through: **intent declared** → **layer assembly** → **policy evaluation** → **Requested State written** → **dispatch to Provider** (Naturalization → execution → Denaturalization) → **Realized State written** → **ongoing drift monitoring**.

Providers wrap existing automation (Ansible, Terraform, vendor APIs). They implement one base contract and translate between DCM's unified data model and their native format. Organizations do not replace their automation — they govern it.

**[Full technical walkthrough →](project-overview.md#how-dcm-works)**

---

## AI-Assisted Work

Load [ai/DCM-AI-PROMPT.md](ai/DCM-AI-PROMPT.md) into any AI model's context at the start of a session. It contains 104 sections covering the complete architecture, all decisions, and working instructions.

---

## Related Projects

| Project | Relationship |
|---------|-------------|
| [Crossplane](https://crossplane.io) | Kubernetes-native infrastructure management — complementary scope |
| [Kessel](https://github.com/project-kessel) | Inventory and relationship management — evaluated for integration in [doc 44](docs/data-model/44-kessel-integration-evaluation.md) |
| [KRO](https://kro.run) | Kubernetes Resource Orchestrator — complementary scope |

---

## Contributing

DCM is open-source. Contributions, feedback, and expertise are welcome.

Before contributing, please read:
- [00-design-priorities.md](docs/data-model/00-design-priorities.md) — the decision hierarchy
- [DCM-Taxonomy.md](docs/taxonomy/DCM-Taxonomy.md) — vocabulary and anti-vocabulary
- [DISCUSSION-TOPICS.md](DISCUSSION-TOPICS.md) — active design discussions
