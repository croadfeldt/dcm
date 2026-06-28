# ADR-022: Credential API Selection (capability-declared, requirement-selected)

**Status:** Proposed
**Date:** 2026-06-28
**Type:** Architecture Decision Record (a `DecisionRecord` with architecture scope — UDLM `entities/knowledge-family.md` §4.5)
**Related:** ADR-005 (Provider Abstraction), ADR-007 (Placement Engine), ADR-021 (Adopting External Standards by Reference); UDLM ADR-004 (Provider capability declaration); `governance/credentials.md`; CPX-001…012; AAL (NIST 800-63B)
**Supersedes (in part):** the `value_retrieval_endpoint` passthrough in `governance/credentials.md`

## Context

A Credential Provider's retrieval path was specified as a `value_retrieval_endpoint` the consumer calls directly. Direct provider→consumer retrieval is **correct and required** — CPX-001 forbids credential *values* from transiting DCM stores. But if that endpoint is the provider's **native** API (Vault, AWS Secrets Manager, a KMS), DCM leaks a **vendor-specific API** to consumers, breaking the vendor-neutrality the rest of the contract guarantees.

Auth/credentials are a crucial, high-assurance surface. They need the **full capability set exposed and selectable, queryable, and governable** — not a single fixed envelope and not a vendor passthrough.

And — crucially — **a declared capability is only a *claim*.** "Provider XYZ supports FIPS L3 / AAL3 / EU key custody" is not trustworthy because the provider says so. The trust model must follow **common security practice appropriate to the target market**: the claim has to be backed by **external attestation** of a strength the market demands (third-party certification, accreditation, or cryptographic hardware attestation), and selection must gate on the *attestation*, not the claim.

## Decision

**Treat the credential API like a workload placement target: providers *declare* the full credential capability matrix (including which standardized API specs they support); requests *state requirements*; DCM *selects* the appropriate spec by capability match — the same filter → gate → score → select → negotiate pipeline the Placement Engine uses for providers.**

1. **Declare (Data, UDLM).** A Credential Provider publishes a granular `credential_capability` block on its provider capability declaration (ADR-004): per credential **type** × **operation**, the **API specs** it supports (version-pinned, adopt-by-reference per ADR-021), plus algorithms, key parameters, `key_usage`, assurance (AAL/FIPS/HSM/attestation), lifetime bounds, rotation, revocation, retrieval transport + auth, and **residency/jurisdiction**. A provider MAY list its `vendor-native` API as one entry, marked `portability: provider-specific`.
2. **Require (Data, UDLM).** A request carries `credential_requirements`: the credential type and the *acceptable* API specs + constraints (min assurance, FIPS level, HSM, algorithms, `key_usage`, lifetime, rotation, revocation SLA, residency). Standardized-by-default: `vendor-native` is selected **only** when explicitly named.
3. **Select (Policy, DCM).** A **Credential API selection** step — structurally identical to placement (ADR-007): **filter** providers/specs that satisfy the requirement → **gate** on profile (sovereign/fsi may forbid `vendor-native`, require FIPS L3 / AAL3 / in-jurisdiction key custody) → **score/select** → **negotiate** the version. A provider that exposes only a native API **fails the filter** for any standardized requirement — exactly as a provider with no failure-domain support fails a spread constraint.

   **Priority — security/trust/fit-for-purpose first, portability retained but subordinate.** A *deliberate inversion* of the general UDLM stance: for most resources portability is near-sacrosanct (intent references abstract kinds, never vendor ids). For **credentials**, security + trust (attestation) + fit-for-purpose are the **hard filter/gate**; **portability is a scoring *preference*, not a gate**. Among producers that clear the security/trust bar, prefer the more standardized/portable one (retain the portability benefit) — but **never trade below the security/trust floor to gain portability**, and `vendor-native` (least portable) is a legitimate selection when it is the fit-for-purpose secure choice the market needs *and* the request permits it. Portability yields to security/trust for credentials; it doesn't vanish — it's the tie-breaker, not the requirement.
4. **Attest (Trust).** Every declared capability carries **attestation** of market-appropriate strength — a claim is not trust. Selection **gates on the attestation, not the claim**: a request/profile sets the minimum attestation tier + accepted frameworks/authorities; a provider claiming FIPS L3 with no/expired/self-asserted attestation **fails the gate** in a market that requires accredited attestation. (See *Trust & attestation* below; this is the credential facet of the broader DCM Trust Model — ADR-023.)
5. **Value path unchanged (CPX-001).** Selection happens in the control plane; the value still flows **direct provider→consumer** over the *selected* spec. DCM never holds the value.

## Why this shape (reuse, not new primitives)

It is three existing mechanisms composed onto credentials:
- **`adopted_standard_support`** (ADR-021) — declare supported standards, version-pinned, conformance-referenced.
- **The Placement filter/gate/score/select engine** (ADR-007) — match declared capability to stated requirement.
- **The portability opt-out** — `vendor-native` is opt-in, like `portability: provider-specific` topology pinning.

No new selection primitive is introduced. The pattern **generalizes**: any provider operation with competing standard specs (not only credentials) can use capability-declared / requirement-selected API negotiation. Credentials is the first and most safety-critical instance; this ADR scopes the decision to credentials and flags the generalization for a later, broader ADR rather than over-reaching now.

## Trust & attestation (a claim is not trust)

Each declared capability (and the provider as a whole) carries an `attestation[]` set. Trust is graded by the **strength of the attestation source**, not the assertion:

| Tier | Attestation source | Acceptable in |
|---|---|---|
| `self_asserted` | the provider declares it | dev / minimal only |
| `vendor_attested` | vendor-signed conformance declaration (the `adopted_standard_support` self-cert) | standard |
| `independently_verified` | a third-party verifier validated it (UDLM independent verifier; CONFORMANCE flow) | standard / fsi |
| `accredited` | a **recognized authority** certified it against a named framework, with certificate id + validity window | fsi / sovereign |
| `hardware_attested` | runtime cryptographic attestation (TPM/HSM quote, FIPS module attestation) — provable, not just documented | sovereign / highest |

Each attestation entry is granular: `{ tier, framework, authority, certificate_ref, valid_from, valid_until, evidence_uri, scope, signature }`.

**Market-appropriate, by reference (ADR-021), never invented.** The **profile** (minimal/standard/fsi/sovereign × region) sets the *minimum tier* and the *accepted frameworks/authorities* for the target market — examples:
- **standard:** `vendor_attested`+; FIPS via CMVP if claimed.
- **fsi:** `independently_verified`+; PCI-DSS, SOC 2; FIPS 140-3 CMVP.
- **sovereign (region-scoped):** `accredited` by the region's authority — EU: eIDAS (QTSP), SecNumCloud, BSI C5, EUCS; US-gov: FedRAMP High + FIPS 140-3 CMVP + Common Criteria; AU: IRAP — plus `hardware_attested` at the top tier.

DCM **upholds** (gates selection on attestation + validates certificate validity/revocation), **participates** (consumes the recognized frameworks' artifacts), and **exposes** (publishes provider *and its own* attestations as verifiable data). Attestation is carried on the existing first-class **`Accreditation`** artifact (versioned, time-bounded) — this ADR applies it to credential capabilities; it is not a new store.

## Queryable & Governable (first-class, not incidental)

- **Queryable:** the `credential_capability` matrix is registry data — admins/consumers can ask "which providers issue `x509` via `acme` at FIPS L3 with online rotation and EU key custody?" before requesting. Selection is just that query, executed by the engine.
- **Governable:** because every capability is declared field-data, `credential_profile` and the Governance Matrix gate on it directly — e.g. sovereign profile: `vendor-native` forbidden, FIPS ≥ L3, AAL3, residency ∈ {eu}, revocation SLA ≤ PT30S. Gating references the *declared* capabilities, so a non-conformant provider is filtered out *before* selection, not caught at use.

## Adopt-by-reference per credential type (ADR-021 gate)

Don't invent a universal secret-wire format (none dominates). Per type, reference the governing standard; define a thin DCM **selection/negotiation envelope** only as the wrapper (not a re-spec of payloads):

| Credential type | Standard API spec(s) referenced |
|---|---|
| x509 cert | ACME (RFC 8555), EST (RFC 7030), SCEP, CMP (RFC 4210) |
| OAuth/OIDC token | RFC 6749 + introspection RFC 7662 |
| KMS-managed key | KMIP (OASIS ≥2.0), PKCS#11 |
| SSH key | OpenSSH CA cert format |
| Kerberos keytab | RFC 4120 |
| generic secret / password | DCM retrieval envelope (no dominant standard) — thin, uniform |
| `vendor-native` | the provider's own API — opt-in, `portability: provider-specific` |

## Options considered

- **Single fixed DCM credential envelope for everything** — rejected: re-specs solved standards (T5 violation) and loses per-type fidelity (an x509/ACME flow ≠ an OAuth token flow).
- **Direct passthrough to the provider's native API** — rejected: leaks vendor API to consumers; not queryable/governable uniformly.
- **Route values through DCM to normalize** — rejected: violates CPX-001 (value would transit DCM).
- **Capability-declared + requirement-selected (placement pattern), value direct** — **chosen.**

## Data · Policy · Provider (required lens — SPEC-DESIGN §29)

- **Data (UDLM):** `credential_capability` matrix + `attestation[]` on the provider declaration; `credential_requirements` (+ `min_attestation_tier`, `accepted_frameworks`) on the request — all granular, queryable fields.
- **Policy (DCM):** the Credential API selection step (filter/gate/score/select/negotiate), gating on **attestation, not claims**, via `credential_profile`/Governance-Matrix; certificate validity + revocation checks at selection (part of the Trust Model, ADR-023).
- **Provider:** declares the matrix, **implements each declared spec** (naturalizes its backend behind each), and **furnishes attestation** of the strength its target markets require; serves the value directly over the selected spec (CPX-001).

## Consequences

- Provider capability declaration gains a `credential_capability` block (UDLM); request gains `credential_requirements`.
- `governance/credentials.md` retrieval section is rewritten around declare-and-select; `value_retrieval_endpoint` becomes "the endpoint for the *selected* spec," not a vendor passthrough.
- New conformance requirement: a Credential Provider must implement every API spec it declares; declaring only `vendor-native` is permitted but self-limiting (filtered out of standardized requests).
- Selection + gating are testable against declared data → credentials become **provably** governable per profile, not best-effort.
