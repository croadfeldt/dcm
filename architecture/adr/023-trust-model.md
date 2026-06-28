# ADR-023: DCM Trust Model — uphold · participate · expose

**Status:** Proposed
**Date:** 2026-06-28
**Type:** Architecture Decision Record (a `DecisionRecord` with architecture scope)
**Related:** ADR-010 (Audit & Tamper Evidence), ADR-011 (Sovereignty & Data Residency), ADR-021 (Adopting External Standards by Reference), **ADR-022 (Credential API Selection)**; Internal/External CA + Trust Anchor (ICOM-009); Provider Callback Auth (PCA-001…010); Component Identity; Token Introspection (RFC 7662); Accreditation; Session Revocation
**Tracking:** "We must uphold, participate in, and expose a full trust model (TLS certs, OAuth, etc.)."

**Flows:** the operational sequences for this are in [`architecture/trust-flows.md`](../trust-flows.md).

## Context

Trust in DCM cannot be self-declared ("trust me, I'm the control plane") any more than a provider's capability can. DCM operates across organizational and sovereign boundaries, so it must be a **first-class participant in the established, standard trust fabric** — PKI/TLS, OAuth2/OIDC, attestation/accreditation — not a bespoke trust island. Three obligations, each non-negotiable across profiles (strictness varies, existence does not):

- **Uphold** — DCM *enforces* trust on every interaction: validates certificate chains to registered trust anchors, checks revocation, verifies tokens + introspection, gates on attestation (ADR-022). It never accepts an unverified peer, token, or claim.
- **Participate** — DCM *is a member* of standard trust systems: it presents its own mTLS identity, integrates external IdPs (OIDC/Keycloak/RHSSO), consumes external CAs (ACME/EST/SCEP/CMP), honors recognized accreditation authorities, and exchanges trust posture with peer DCMs to federate.
- **Expose** — DCM *publishes its own verifiable trust posture* so peers and consumers can verify **it**: its trust anchors, component identities (certs/JWKS), token-introspection/JWKS endpoints, conformance declaration, and attestations — all as verifiable data at well-known endpoints.

## DCM's role: trust **broker** (introducer/matchmaker), not credential authority

The most important boundary in this model: **DCM/UDLM broker trust; they do not custody, pass, or negotiate credentials.** DCM is a *control-plane introducer* that connects a credential **producer** (a Credential Provider — a real CA, Vault, IdP, KMS) to a credential **consumer**, then steps out of the path.

**DCM does** — discover + **match** producer↔consumer (the ADR-022 capability/requirement selection); **gate** on the producer's attestation for the target market; **broker the bootstrap** — give each party the other's endpoint, trust anchors, and a short-lived, scoped **introduction handle** so they can stand up a **direct, mutually-authenticated** channel; **audit** the introduction.

**DCM does NOT** — hold or pass credential **values** (CPX-001); sit in the credential **issuance/negotiation** path. The consumer speaks the *selected* standard API (ACME/EST/OAuth/KMIP) **directly** to the producer. DCM negotiates the *connection*; the parties negotiate the *credential* between themselves.

**"Trusted in this role" = introduction integrity, not secret custody.** Parties needn't trust DCM with secrets — only to make a *correct, authenticated, attested match*. That is a minimal, defensible trust surface: a compromised broker cannot leak credentials (it never holds them); at worst it could mis-introduce, which the parties' own mutual auth + the audit trail detect. DCM earns this trust by **exposing its own attested identity/posture** (below) so both parties verify the broker before accepting an introduction.

**DCM's second hat — a first-class participant for its OWN needs.** Brokering is for *other* parties' credentials. DCM itself also *consumes* credentials (component mTLS identity, user auth, internal trust) and *produces* its own component identity (Internal CA). It obtains these through the **same declare→select→attest machinery** — no privileged bypass; it eats its own dog food. Two credential categories with different custody rules:

| Category | Owner | Custody |
|---|---|---|
| **Managed** (brokered consumer↔producer) | the parties | **CPX-001 — value never in DCM**; DCM brokers + steps out |
| **DCM-operational** (its own TLS key, token-signing/JWKS key, component certs, user-auth session keys) | DCM | DCM **must** hold these to function — protected per profile (software → HSM), attested, rotated |

So CPX-001 governs *managed* credentials; DCM's *own* operational secrets are a normal, protected, attested category (it cannot terminate TLS or sign sessions otherwise). For **DCM's own component identity** the Internal CA is the homelab/minimal default; higher profiles plug in an external/accredited CA — pluggable, and it does not make DCM an authority for the brokered parties.

## Decision

**Adopt a single, declared, end-to-end trust model built entirely on standard mechanisms (adopt-by-reference, ADR-021), spanning five trust planes — each upheld, participated-in, and exposed, and each market-graded by attestation. DCM's posture across all five is *broker*: it connects and vouches, it does not custody secrets or sit in the credential negotiation path.**

| Plane | Mechanism (referenced standards) | Uphold | Participate | Expose |
|---|---|---|---|---|
| **Identity & transport** | X.509/PKIX (RFC 5280), mTLS, Trust Anchors; Component Identity; Provider Callback Auth (PCA) | validate chain→anchor + revocation on every hop (ICOM-009) | present own cert; accept external CAs | publish trust anchors + component certs |
| **Authorization** | OAuth2 (RFC 6749), OIDC, introspection (RFC 7662), JWKS; Session Revocation Registry | verify every token + revocation check | integrate any OIDC IdP (Keycloak/RHSSO/…) | own introspection/JWKS where DCM issues |
| **Credential issuance/retrieval** | ACME, EST, SCEP, CMP, KMIP, OAuth — **selected** per ADR-022 | gate on capability **+ attestation** | naturalize any compliant credential backend | publish credential capability + attestation matrix |
| **Capability attestation** | CMVP (FIPS 140-3), Common Criteria, FedRAMP, eIDAS, PCI-DSS, SOC 2, SecNumCloud, C5, IRAP; TPM/HSM remote attestation | gate selection on tier+framework, check validity | consume recognized authorities' certs | publish own + providers' attestations (Accreditation artifact) |
| **Federation** | Peer trust posture exchange; CONFORMANCE peer-verification flow | verify peer conformance+attestation before federating | exchange trust anchors with peers | expose conformance + trust posture for peers to verify |

Cross-cutting invariants: **CPX-001** (credential values never transit DCM); **everything is declared data** (anchors, identities, attestations, accepted frameworks) so it is queryable + governable; **market-appropriate strength** is set by `profile × region` (ADR-022's attestation tiers), referencing recognized frameworks, never inventing them; every trust decision is **audited** (ADR-010) with the attestation/cert that justified it recorded as provenance.

## Trust is graded, not binary

A peer/provider/token isn't "trusted" or "untrusted" — it carries a **trust posture** (which planes are satisfied, at what attestation tier, against which frameworks, valid until when). The profile defines the **minimum posture** for the market; the engine filters/gates on it (the ADR-022 pattern, applied across all five planes). Self-asserted is fine for dev; sovereign markets demand accredited + hardware-attested.

## Options considered
- **Implicit/internal trust (DCM asserts its own trustworthiness)** — rejected: not acceptable across orgs/sovereign boundaries; unverifiable.
- **Invent a DCM trust framework** — rejected (T5/ADR-021): the world has PKI, OAuth/OIDC, CMVP, CC, eIDAS, FedRAMP — adopt and compose them.
- **Uphold-only (enforce, but don't expose DCM's own posture)** — rejected: peers must be able to verify DCM itself for federation/sovereignty; trust is mutual.
- **Declared, standard-based, three-obligation model (uphold/participate/expose), market-graded by attestation** — **chosen.**

## Data · Policy · Provider (required lens)
- **Data (UDLM):** trust-posture declarations — trust anchors, component/provider identities, `attestation[]`, accepted-frameworks-by-profile, credential capability matrix (ADR-022); all as verifiable, version-pinned fields.
- **Policy (DCM):** enforcement + gating across the five planes (chain/revocation/token/attestation/federation), profile-graded by market; audited.
- **Provider:** presents identity (mTLS/PCA), declares + furnishes attestation of market-required strength, implements the credential specs it advertises.

## Consequences
- A coherent umbrella over already-present primitives (CA/anchors, PCA, Component Identity, OAuth/introspection, revocation, Accreditation, federation) — this ADR *names and unifies* them as one declared model, with ADR-022 as the credential facet.
- New/elevated UDLM data: a provider/realization **trust-posture** declaration (identity + anchors + attestation + exposed endpoints) alongside the credential capability matrix.
- New conformance requirement: a realization must **expose** its trust posture (well-known endpoints) and **uphold** validation on every plane — not optional.
- Trust becomes **provably** market-appropriate (gated on attested, validatable data), not best-effort or self-asserted.
