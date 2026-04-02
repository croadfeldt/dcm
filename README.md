# DCM — Data Center Management

DCM is a framework for sovereign private cloud management. It provides a declarative control plane for managing the lifecycle of arbitrary infrastructure resources across an enterprise — from bare metal and VMs to containers, applications, and managed services.

**Three foundational abstractions:** Data · Provider · Policy
**License:** Apache 2.0

---

## Repository Structure

```
dcm/
├── architecture/
│   ├── data-model/                         ← 57 architecture documents
│   │   ├── 00-foundations.md               ← Start here — three abstractions
│   │   ├── 01-entity-types.md
│   │   ├── 02-four-states.md
│   │   ├── ...
│   │   ├── 50-subscription-lifecycle.md
│   │   ├── 51-infrastructure-optimization.md
│   │   ├── A-provider-contract.md
│   │   └── B-policy-contract.md
│   ├── ai/DCM-AI-PROMPT.md                ← AI knowledge base (104 sections)
│   ├── DCM-Capabilities-Matrix.md         ← 309 capabilities across 39 domains
│   └── DISCUSSION-TOPICS.md               ← Open and resolved discussion topics
├── docs/
│   ├── specifications/                     ← 15 prose specification documents
│   └── engineering/
│       └── ENGINEERING-ALIGNMENT.md        ← Per-repo mapping for engineering teams
├── taxonomy/
│   └── DCM-Taxonomy.md                    ← Vocabulary, anti-vocabulary, 39 domain prefixes
├── schemas/
│   ├── openapi/                           ← 4 AEP-compliant API specs
│   │   ├── dcm-consumer-api.yaml          ← 72 consumer paths
│   │   ├── dcm-admin-api.yaml             ← 57 admin paths
│   │   ├── dcm-operator-api.yaml
│   │   └── dcm-provider-callback-api.yaml
│   ├── jsonschema/                        ← 6 JSON schemas
│   │   ├── dcm-common.json
│   │   ├── dcm-entities.json
│   │   ├── dcm-events.json                ← 101 event payloads across 22 domains
│   │   ├── dcm-policies.json
│   │   ├── dcm-providers.json             ← 6 provider types
│   │   └── resource-type-spec-template.json
│   └── sql/
│       └── 001-initial.sql                ← 14 tables, RLS, hash chain, LISTEN/NOTIFY
├── project-overview.md
├── LICENSE
└── README.md
```

## Key Facts

| Metric | Value |
|--------|-------|
| Architecture documents | 57 data model + 15 specifications |
| Capabilities | 309 across 39 domains |
| Provider types | 6 (service, information, meta, auth, peer_dcm, process) |
| Policy evaluation modes | 2 (Internal via OPA, External via provider) |
| Control plane services | 9 |
| Required infrastructure | 3 (PostgreSQL-compatible DB, OIDC-compatible IdP, Vault-compatible secrets) |
| Consumer API | 72 paths |
| Admin API | 57 paths |
| Event catalog | 101 payloads across 22 domains |

## Getting Started

1. **Understand the design** — read [`architecture/data-model/00-foundations.md`](architecture/data-model/00-foundations.md)
2. **Learn the vocabulary** — read [`taxonomy/DCM-Taxonomy.md`](taxonomy/DCM-Taxonomy.md)
3. **See what DCM can do** — browse [`architecture/DCM-Capabilities-Matrix.md`](architecture/DCM-Capabilities-Matrix.md)
4. **Build a service** — start with the OpenAPI specs in [`schemas/openapi/`](schemas/openapi/) and the engineering guide in [`docs/engineering/ENGINEERING-ALIGNMENT.md`](docs/engineering/ENGINEERING-ALIGNMENT.md)
5. **Deploy an example** — see [dcm-examples](https://github.com/dcm-project/dcm-examples)

## Related Repositories

| Repository | Purpose |
|-----------|---------|
| [dcm-examples](https://github.com/dcm-project/dcm-examples) | Reference implementations — Summit demo with Go services, Ansible, OpenShift manifests |
| [dcm-project.github.io](https://github.com/dcm-project/dcm-project.github.io) | Project website — documentation segmented by domain |
| [catalog-manager](https://github.com/dcm-project/catalog-manager) | Service catalog implementation |
| [service-provider-manager](https://github.com/dcm-project/service-provider-manager) | Provider registration |
| [policy-manager](https://github.com/dcm-project/policy-manager) | Policy CRUD and evaluation |
| [placement-manager](https://github.com/dcm-project/placement-manager) | Provider selection |
| [api-gateway](https://github.com/dcm-project/api-gateway) | API ingress (Traefik) |
| [enhancements](https://github.com/dcm-project/enhancements) | Design proposals |
| [shared-workflows](https://github.com/dcm-project/shared-workflows) | CI/CD workflows |
