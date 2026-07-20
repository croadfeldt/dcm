# ADR-024: Rule-ID naming convention and central registry

**Status:** Proposed
**Date:** 2026-07-20
**Type:** Architecture Decision Record (a `DecisionRecord` with architecture scope)
**Related:** ADR-021 (Adopting External Standards by Reference); **UDLM ADR-028** (the rule-ID naming convention + registry this adopts by reference). **Prior art:** UDLM's `registry/rule-id-registry.yaml` + `tests/check_single_source.py` (registry-backed, CI-wired).

## Context

Every normative rule in the DCM architecture carries a stable ID (`DRC-001`, `AUTH-018`, `POL-006`, …) so a doc — or a peer — can cite one rule and land on one definition. But the prefixes were minted ad hoc, with no registry of which prefix means what or where it lives, and no CI enforcing it. This is the same drift UDLM had before **UDLM ADR-028**, which fixed it with a naming convention + a schema-validated registry + a registry-backed `check_single_source` wired into CI.

An inventory of the DCM architecture (2026-07-20) found:

- **63 prefixes, 489 rule IDs.**
- **12 prefix spreads** (a family defined across more than one file): `ACM AUTH BOOT DRC HLT ICOM ING ITSM OPS SMX VER WLA`.
- **68 apparent full-ID collisions** — but these are **dominated by one pattern**: `architecture/DCM-Capabilities-Matrix.md` **re-lists** rule IDs that are *defined* in their domain home files (e.g. `ACM-002..007` also appear in `governance-enforcement/accreditation-monitor.md`; `AUTH-017..022` in `control-plane/session-revocation.md`; `DRC-001..005` in `control-plane/components.md`). The Capabilities Matrix is an **index**, not a second definition — so most "collisions" are the index doing its job, not real duplication.

## Decision

**DCM adopts UDLM's rule-ID naming convention and central-registry model (UDLM ADR-028) by reference, adapted to DCM's file layout — it does not coin its own.**

1. **Convention** (UDLM ADR-028, `registry/rule-id-naming.md`): IDs are `PREFIX-NNN`; one prefix = one family = one home file; a *definition* is an ID-first table row and lives only in the home; IDs are immutable once published (retire + supersede, never repoint); collisions are resolved by renumbering to a disjoint prefix, not coexistence. DCM ADRs continue to reference **UDLM** rule IDs by their qualified `UDLM XxX-NNN` name and never re-mint them.

2. **The Capabilities Matrix is an index, not a definition surface.** `DCM-Capabilities-Matrix.md` (and any equivalent roll-up) **references** IDs owned by domain docs; its rows are marked as references (or the check excludes it as a non-normative index, exactly as UDLM excludes its index surfaces). This resolves the bulk of the apparent collisions without moving any rule.

3. **Registry** (`registry/rule-id-registry.yaml`, validated by a schema): one record per prefix — `prefix`, `name`, `home`, `domain`, `status` — with `baseline_spread` for genuine debt to burn down and `additional_homes` for any *sanctioned* coordinated co-definition. The enforced invariant is **one definition per ID**, not literally one file per prefix.

4. **Enforcement** (`check_single_source`, CI-wired): fails on an unregistered prefix, a definition outside its home, or an ungrandfathered id-collision. Landed **report-only first** (baseline the existing spreads), then ratcheted to a hard gate as the residual real collisions are resolved — the same staged rollout UDLM used (ADR-028 → registry → renumbers).

**Data · Policy · Provider:** *Data* — the rule-ID registry is a DCM authoring artifact (mirrors UDLM's). *Policy / Provider* — n/a (spec hygiene, not a runtime decision).

## Consequences

- New rule families register their prefix before use; drift can't reappear silently once the gate is hard.
- The Capabilities-Matrix-as-index recognition collapses ~most of the 68 apparent collisions to a handful of genuine ones, which are then resolved by renumber (needs a prefix ruling, as UDLM's RSE/DSC did).
- Reuses UDLM's convention, schema shape, and check rather than inventing DCM-specific machinery (ADR-021, adopt-by-reference).
- Keeps UDLM and DCM rule-ID spaces coherent: DCM never re-mints a UDLM ID; UDLM references resolve cross-repo.

## What this ADR does NOT yet decide (follow-ups, need a ruling)

- The exact **prefix renumbers** for the residual genuine collisions (after the Matrix is treated as an index).
- Whether the 12 spreads are **debt** (`baseline_spread`, renumber later) or **sanctioned** (`additional_homes`, like UDLM's GRP/REL) — per-family call.
- The seeded `registry/rule-id-registry.yaml` (all 63 prefixes with homes) and the CI wiring land in the follow-up PR, once the above are ruled.

## Alternatives considered

- **Invent a DCM-specific convention** — rejected: UDLM ADR-028 already solves this; adopt by reference (ADR-021) and keep the two ID spaces coherent.
- **Treat the Capabilities Matrix rows as definitions** — rejected: it is an index; marking its rows as duplicate definitions would force needless renumbering of correctly-single-homed rules.
- **Hard-gate immediately** — rejected: 12 spreads + residual collisions would fail CI on day one; baseline-then-ratchet (UDLM's proven path) lands it green and burns debt down.
