# ADR-025: Realizing the scoped-Class paradigm

**Status:** Accepted (croadfeldt upstream) — downstream adoption pending eng alignment
**Date:** 2026-07-21

## Context

UDLM **ADR-038** lands the *scoped resource-type Class* paradigm: resource types are layered **Base / Type / Provider Classes** composed of scoped `SharedDataElement`s, with a URL-native addressing coordinate, a dual-anchor reference model, `covers`/`skip` layers, and three relationship axes (is-a / has-a / references-context). ADR-038's UDLM-vs-DCM split (the ADR-008 peer test) assigns the **model, grammar, classification, and data** to UDLM and the **engine — every *decision*** to DCM.

This ADR records **where that engine half lives in DCM**. The important finding: it is *mostly already here*. The paradigm is a cleaner data model over the realization engines DCM already has; only a few capabilities are net-new.

## Decision

**1. The paradigm's DCM responsibilities map onto existing engines.**

| Paradigm engine responsibility (UDLM ADR-038) | DCM home |
|---|---|
| Resolve the Class path (pick Type / Provider / instance from an eligible **set**) | Placement (ADR-007, ADR-019) — extended to Class-path resolution |
| Policy-fill type/provider-specific blanks (consumer-set ≻ policy-fill ≻ provider-default) | Policy engine (ADR-006) + override/exception governance (ADR-013) |
| Assemble layers (gather-by-`covers`, precedence, override, `narrow_only`), authorize `skip` | Data assembly / layering (ADR-012) + override governance (ADR-013) |
| Resolve references; compute blast radius (`impact_report`); enforce repoints | Reference resolution & change-impact (ADR-024) |
| Naturalize generic ↔ native (Provider Class realization) | Provider naturalization boundary (ADR-023) |
| Migration / rehydration on re-port | Migration & operational gating (ADR-020) |
| Ingest / promote vocabularies (`proposed → canonical`) | Brownfield greening / discovered ingestion (ADR-017) — extended per UDLM ADR-039 |
| Audit records; sovereignty gate at resolve | Audit & tamper-evidence (ADR-010); sovereignty & residency (ADR-011) |

**2. DCM is the domain for the Provider-Class and data-layer *definitions*.**

UDLM defines Base + Type classes and the *grammar* for the layers below; the **definitions that fill that grammar are not UDLM's** (UDLM ADR-038, *Authorship & domain*). DCM is where they live and are governed:

- **Provider Classes are provider-authored.** A `Compute.VM.OCPVirt` definition is a provider-created artifact. DCM **registers** the provider-contributed Class, **validates** it against the UDLM Type-class grammar (Liskov — add/refine, never contradict; the contribution gate), and exposes it for Class-path resolution and capability matching. Registration + validation extend the naturalization boundary (ADR-023) and the trust model (ADR-022 — who may contribute).
- **Data-layer definitions are organization-level.** The layer *contract* (`covers`/`skip`/precedence/`narrow_only`) is UDLM; *which* layers exist and what they hold — an org compliance overlay, a Data-Center info bundle — are org implementation details DCM stores, **binds** to groups/tenants/requests, and assembles (ADR-012/013).
- **DCM MAY ship examples or defaults** — a starter Provider Class, a default compliance layer — as conveniences, never as canon; an org overrides them. This is DCM content, not UDLM content.

**3. Net-new DCM work (small):**
- **Provider-Class registration + contribution-gate validation** — accept a provider-authored Provider Class, validate it Liskov-conforms to its Type Class, register it for resolution/matching (extends ADR-023 + ADR-022).
- **Class-path resolution** — Placement resolves a Base/Type Class request down to a concrete Provider Class + instance across the eligible *set*, by requirements + advertised capability + policy (extends ADR-007/019).
- **Requirements ↔ capability matching** — for requirements-based selection (storage, UDLM ADR-036) and portable-vocabulary membership (UDLM ADR-035).
- **Promotion / canonicalization** — `proposed → canonical` for `SharedDataElement`s and upward contributions; the ≥2-adopter promotion (extends ADR-017 + the trust model ADR-022 for who may promote).
- **The governed federation resolver** — resolving rooted addresses across peers/tenants/jurisdictions with the sovereignty gate at the wire (UDLM **ADR-040** stub; extends ADR-011 + ADR-024). Demand-driven, `peer` root first.

**4. The wire stays flat.** DCM exchanges the **resolved effective schema** (Base ⊕ Type ⊕ Provider, flattened) with peers, never the layered form — consistent with the compatibility rule (ADR-021, UDLM ADR-008).

## Consequences
- No new engine is required — the paradigm is realized by extending existing DCM engines, plus the federation resolver (its own follow-on, demand-driven).
- Addressing/query/filter are one mechanism (the coordinate predicate); DCM must not introduce a parallel selector/query construct (UDLM ADR-038 design criteria).
- Amends nothing structural in DCM; it *organizes* existing realization responsibilities under the paradigm and names the incremental work.

## Data · Policy · Provider
- **Data** — DCM consumes the UDLM Base/Type model, coordinate grammar, and layer contract; it authors none of *those*. But the **Provider-Class and data-layer definitions are DCM-domain** — provider- and org-authored, registered and governed here (Decision 2).
- **Policy** — placement, policy-fill, assembly, promotion, matching, skip/repoint gating, sovereignty.
- **Provider** — naturalization at the Provider-Class edge; capability advertisement.
