# AGENTS.md — DCM

> Cross-agent context file ([agents.md](https://agents.md) standard). `CLAUDE.md` is a symlink to this
> file so Claude Code reads the same source of truth. Keep this current as the architecture evolves.

## What this repo is

**DCM — the Data Center Manager.** A vendor-neutral architecture specification for an intent-driven
control plane that provisions, governs, and rehydrates data-center resources. **DCM is one realization
of UDLM** (the Unified Data-center Lifecycle Model, `github.com/croadfeldt/udlm`) — understand the UDLM
substrate first; DCM is the control-plane architecture built on it.

**This is a docs/architecture-only repo — there is no application code** (no Go/Python/TS, no build).
The deliverable is the specification: Markdown architecture docs, machine-readable contracts (OpenAPI /
JSON Schema / SQL), ADRs, and a taxonomy. **Apache-2.0.**

## Layout

```
architecture/      Core architecture. ADRs (adr/, 001–016 + README index), the AI prompt
                   (ai/DCM-AI-PROMPT.md), DCM-Capabilities-Matrix.md, and subsystem folders
                   (control-plane/, convergence-engine/, ingestion/, credentials-and-auth/,
                   governance-enforcement/, runtime-features/, topology/, persistence/, integrations/).
                   Entry docs: overview.md, layering.md, operator-perspective.md, design-principles.md.
docs/              Prose specifications/ (consumer-api-spec, dcm-admin-api-spec), engineering/
                   (ENGINEERING-ALIGNMENT.md), future-features/, holistic-vision.md.
schemas/           Machine-readable contracts: openapi/ (consumer/admin/provider-callback/operator),
                   jsonschema/ (events, providers, entities, policies, resource-type template),
                   sql/001-initial.sql (18 tables).
reference/         implementation-standards.md, implementation-specifications.md, operational-reference.md.
taxonomy/          DCM-Taxonomy.md (the controlled vocabulary).
examples/          orchestration-scenarios.md. (Full examples live in the external dcm-project/dcm-examples repo.)
dav/               The DCM validation corpus/schemas DAV runs against (see croadfeldt/dav).
README.md, project-overview.md, LICENSE
```

## Read first (entry points)

1. UDLM substrate — `github.com/croadfeldt/udlm` (DCM is one realization of it).
2. `architecture/overview.md` → `architecture/layering.md` (the UDLM/DCM boundary).
3. `architecture/convergence-engine/overview.md` — the intent→realized loop, the heart of DCM.
4. `architecture/operator-perspective.md`, `taxonomy/DCM-Taxonomy.md`.
5. `architecture/DCM-Capabilities-Matrix.md` — what DCM can do.
6. `architecture/adr/README.md` + ADRs 001–016 — the decision history (the "why").

## Operating rules

- **Commits:** `--no-gpg-sign`, author `Chris Roadfeldt <chris@roadfeldt.com>`, trailer
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`. Commit subjects use a lowercase
  `scope: short description` prefix (`sov:`, `use-cases:`, `docs:`, `observability:`, …) where scope =
  the doc area touched.
- **PRs are subject-scoped** — one logical doc area per PR (≤2–3k lines; split larger subjects on logical
  boundaries). **Lead with the "why"** and capture decisions as **ADRs** in `architecture/adr/` (next
  number, one decision each) — that is this repo's document-the-why mechanism.
- **Remotes:** GitHub `croadfeldt/dcm` (origin) + `dcm-project/dcm` (upstream — the canonical project
  home; promote scoped PRs upstream). Default branch `main`; use `gh`.
- **Counts come from source artifacts, never summary blocks.** Three summary blocks in this repo
  (README "Key Facts", the AI prompt's self-report, and the old onboarding doc) disagree with each other
  and with the actual files. When you need a number, read the artifact:
  - capabilities → `architecture/DCM-Capabilities-Matrix.md` total (311 across 39 domains)
  - SQL tables → `schemas/sql/001-initial.sql` (18)
  - events → the §65 Event Catalog / UDLM event-catalog (82 across 26 domains)
  - API paths → `schemas/openapi/dcm-consumer-api.yaml` (75) / `dcm-admin-api.yaml` (admin spec)
  - provider types → 5 (unified provider model: service / information / auth / peer_dcm / process)
  - policy types → 8, with 2 evaluation modes (Internal via OPA / External via provider)

## The DCM AI prompt — conversational architecture exploration

`architecture/ai/DCM-AI-PROMPT.md` (~5,950 lines, plain Markdown) is a comprehensive knowledge base of
every architectural decision, capability, contract, and cross-reference. Load it into Claude (or any
128K+ context LLM) to explore the architecture conversationally — faster than reading the docs piecemeal.

- **Claude Projects** (best for ongoing use): add the file to a Project's knowledge base; every
  conversation then has full context.
- **claude.ai / other LLMs:** attach the file to a conversation; it stays active for the session.

Ask specific questions ("How does the override model work?", "What endpoints does a new service provider
implement?", "How does the three-tier app example resolve dependencies end to end?"). The prompt grew
cumulatively, so trust its **section content**, not any fixed section-number index.
