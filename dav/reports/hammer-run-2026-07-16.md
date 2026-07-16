# DAV hammer round — 2026-07-16

**What this is / what it settles.** I generated 280 edge-case use cases across 14 enterprise-capability
themes and ran them (plus the 31-UC regression baseline) through DAV's gap engine against the just-swept
UDLM/DCM architecture. The result is a ranked list of architecture gaps and one net-new UDLM type, staged
for review. **Headline: the September 1.0 *surface* held — the hammer round found almost no missing types.
It found missing *depth*** — spec detail the surface implies but doesn't pin down, and one genuinely absent
resource type (address pools). Nothing here is auto-admitted; the framework proposes, you dispose.

---

## The numbers

| Run | UCs | Analyzed | supported | partially_supported | not_supported |
|---|---|---|---|---|---|
| Baseline (set 29 + seeds, regression) | 31 | 29 | 6 (21%) | 23 (79%) | 0 |
| **Hammer (280 new, 14 themes)** | **280** | **272** | **50 (18%)** | **221 (81%)** | **1 (<1%)** |

(8 hammer + 2 baseline UCs failed on stage-2 JSON parse — the 32B model timing out mid-emit, spread evenly
across themes, no bias. Re-runnable.)

**The most important number is buried:** even *supported* UCs average **1.7 gaps each**, and partials
average **1.9**. The verdicts don't split "works" vs "broken" — they split "works, with named refinements"
vs "works once we pin down a detail the spec left implicit." Across 503 gaps, only **15 are critical (≥80)**
and **29 major (65–79)**. That's the shape of a mature surface being probed for depth, not a model full of
holes. I read that as validation of the 1.0 scope decision, not a threat to it.

### By theme (hammer)

| Theme | supported | partial | not_supported |
|---|---|---|---|
| audit-compliance | 8 | 12 | – |
| policy-override | 7 | 13 | – |
| multi-tenancy | 5 | 14 | – |
| capacity-placement / decommission / networking | 4 | 16 | – |
| brownfield-discovery / dr-rehydration / drift-recovery / storage-mobility | 3 | 16 | 0/0/1/0 |
| credentials / cost-quota | 2 | 16–18 | – |
| federation / sovereignty | 1 | 18–19 | – |

Sovereignty and federation scored the fewest clean "supported" — but see the gap analysis: most of their
partials are **data or spec-detail gaps, not architecture gaps** (details below).

---

## Ranked gaps (foundational first)

I ranked by how cross-cutting each gap is, not raw count — a gap that blocks many high-value UCs beats a
one-off.

### 1. Audit-trail cross-reference discipline *(biggest cluster — not a missing type)*
"Audit Trail Recording" (×5), "Audit Trail Integration" (×4), and for-rehydration / for-blocked-delegation
variants recur across brownfield, decommission, sovereignty, and rehydration. **Root cause: the audit
substrate already exists** — `registry/audit-record.schema.json`, `registry/audit-leaf.schema.json`,
`observability/universal-audit.md` — **but the capability specs don't cite it.** The engine keeps flagging
"where does this action get recorded?" because each spec leaves its audit emission implicit.
- **Fix (no new type):** a spec-wide cross-reference rule — every state-changing capability names the
  `audit-record` it emits — plus a checklist in the standards runbook. This is a discipline pass, cheap.
- **The one genuine extension:** the tamper-evidence UCs (audit 003/004, erasure-vs-immutable) asked for
  `proof-contract.md` / `tree-head-contract.md` that don't exist. That's a real contract gap with a real
  standard behind it — **RFC 9162 (Certificate Transparency / Merkle inclusion+consistency proofs)**. I'd
  add it as a thin contract over the existing `audit-leaf`, not a resource type. Proposed, needs your call.

### 2. Policy-contract depth
Missing-ref clusters point hard at `contracts/policy-contract.md` §7.2 (evaluation), §7.3 (constraint
emission), §7.7 (three-state outcome / governance honesty), §7.5 (per-pass audit), and
`governance-enforcement/policy-profiles.md` (precedence, override scoping, external-mode). The contract
*exists and is right*; the UCs want the concrete emission + precedence detail spelled out. Sharpest edge:
**cross-tenant authorization** — storage `cross-tenant-volume-leakage-denied` (critical) and
`cross-tenant-access-denial` (major) name a capability (XTA-001/002) the spec implies but doesn't define.
- **Fix:** concreteness pass on policy-contract §7.3/§7.7 + define the cross-tenant-authz capability. Spec
  depth, no new type.

### 3. Network.IPAddressPool — **net-new type, STAGED for your review** ✅
Networking (`ipaddress-from-pool-allocation-ownership`, `pool-exhaustion-detection`) and multi-tenancy
(`per-tenant allocation records for chargeback`) were partial because **no first-class address-pool type
existed** — only `Network.IPAddress` (a consumed address) and `Network.DHCPScope` (service-side subnet
config). There was no object to express *allocation ownership*: which addresses are in play, who holds each,
whether the pool is exhausted.
- **Done:** drafted `Network.IPAddressPool`, anchored on **RFC-2131 DHCP subnet pools** (already registered,
  already backs `Network.DHCPScope` — no new standard) and mirroring the existing **Storage.Pool →
  Storage.Dataset** allocatable-pool pattern (a pool is the source; the carved record `depends_on` it).
- **Status:** on local branch `feat/network-ipaddresspool` (croadfeldt/udlm), **all four gates green**
  (validate_registry 0 failures, ci_compat net-new, estate-tokens 0, single-source OK). **Not pushed** —
  branch protection is yours. Companion edge (`Network.IPAddress.allocated_from → Network.IPAddressPool`,
  mirroring `Storage.Dataset.pool`) is proposed but *not* applied, to keep this a single-type add.

### 4. Drift / recovery model refinements
Flapping detection (no fixed point), concurrency precedence between a sanctioned modification and a drift
remediation firing at the same time (2 critical), and recovery-policy thresholds. The **one `not_supported`
UC** is here: `correct-immutable-realized-directly` — when an operator tries to edit an immutable Realized
record, the spec rejects it but gives no guidance toward the legitimate path (adopt-into-intent /
remediate-to-intent). That's a genuine finding: the *refusal* is modeled, the *redirect* isn't.
- **Fix:** recovery-policy model additions (flapping thresholds, mod-vs-remediation precedence) + a
  rejected-mutation guidance clause. Spec depth in `entities/resource-service-entities.md §3` +
  `foundations/four-states.md §6`.

### 5. Federation forward-compatibility *(2 critical)*
`peer-ahead-of-ratified-model-version`: no defined rule for how a DCM handles unknown fields / unknown
resource types when a peer is on a newer model version. This is a schema-evolution gap.
- **Fix:** a **must-ignore-unknown / must-understand** rule (the well-worn protobuf/JSON-Schema evolution
  discipline) added to `foundations/layering-and-versioning.md`. No new type; a versioning-contract clause.

### 6. Sovereignty — mostly *data*, not architecture
Sovereignty scored low on clean-supported, but the analysis is reassuring: `sovereign-region-placement`
(critical "Missing Minnesota VM Accreditation") is a **data gap** — `accreditation.schema.json` and
`accreditation-state-mn.yaml` exist; the instance just doesn't cover the VM capability. The architecture
supports it; the demo estate is incomplete. The **real** spec gap is `peer-dcm-federation-residency-boundary`
(critical): federation admission must check peer-jurisdiction compatibility against a resource's residency
constraint — an intersection of gaps #5 and sovereignty.

### 7. Cost / quota — confirms the external-metering decision
Capex depreciation, FX normalization, FOCUS columns all came back partial/unsupported **as expected** — cost
is deliberately thin in UDLM. This isn't a type gap; it's confirmation that cost belongs in an external
metering Provider. **Routes straight to the Meteridian evaluation (task #28) / FOCUS.** No UDLM core change.

### 8. Credentials — lifecycle is DCM-runtime, plus one doc gap
`security.credential-ref.yaml` exists (referencing is modeled). The gaps — revocation escalation, federated
revocation coordination when a peer is unreachable — are **DCM runtime** concerns, and the
`DCM-Capabilities-Matrix` lacks a "Credential Model" section (doc gap). **Routes to tasks #24 (credential
referencing) / #25 (JIT).**

---

## What the architecture handles cleanly (50 supported)

Worth stating, since the partials dominate the headline: policy-override was the strongest theme (7
supported — separation-of-duties, tenant-cannot-loosen-system-deny, soft-enforcement all clean), audit had
8 (clock-skew cross-site ordering, retention-past-decommission), multi-tenancy 5, and the DPO-007
"decidable-must-not-route-to-review" case scored supported — the route-to-review-as-last-resort principle
we just settled holds up under probing.

---

## Proposed dispositions (your call on each)

| # | Gap | Proposal | Type of change | Status |
|---|---|---|---|---|
| 3 | Address-pool allocation ownership | `Network.IPAddressPool` | **net-new type** | **staged, gates green, unpushed** |
| 1 | Tamper-evidence proofs | RFC-9162 contract over `audit-leaf` | new contract doc | proposed |
| 1 | Audit not cited by capabilities | cross-ref discipline + checklist | spec discipline | proposed |
| 5 | Peer ahead of model version | must-ignore-unknown rule | versioning-contract clause | proposed |
| 2 | Cross-tenant authz | define XTA capability + §7.3/§7.7 concreteness | spec depth | proposed |
| 4 | Rejected immutable-mutation | redirect-to-legitimate-path clause | spec depth | proposed |
| 6 | Peer × residency | federation-admission jurisdiction check | spec depth | proposed |
| 7 | Cost model | route to Meteridian/FOCUS (task #28) | out of UDLM core | routed |
| 8 | Credential lifecycle | route to tasks #24/#25 (DCM runtime) | out of UDLM core | routed |

**The honest summary:** one type was actually missing (address pools — staged). Everything else is depth
the 1.0 surface implies but doesn't yet pin, or work that correctly lives outside UDLM core. That's a good
result for a September-1.0 readiness probe.

---

## Corpus delivered

280 UCs in `dcm/dav/use-cases/hammer-<theme>/` (20 each × 14 themes: sovereignty, multi-tenancy,
dr-rehydration, credentials, cost-quota, audit-compliance, federation, brownfield-discovery, decommission,
drift-recovery, capacity-placement, networking, storage-mobility, policy-override). Every UC is
provenance-tagged (`generated_by.source: llm-guided`, `metadata.note: batch=framework-hammer-2026-07-16`,
tag `hammer-2026-07-16`) so its verdicts stay sliceable from the hand-authored 21 — the ground-truth guard
against self-referential validation. All 280 validate against the engine's own ingest gate.

**One process fix worth flagging:** the generation kit (`dav/engine/GEN-KIT.md`) had drifted from the
engine's authoritative dimension/`generated_by` vocab (`consumer_profile.py`), so the first run quarantined
all 280. I found the real enums, remapped every file, and re-validated with the engine's own
`UseCase.validate()` before the run. GEN-KIT should be regenerated from `consumer_profile.py` (there's an
`export_dcm_vocab.py` that could source it) so the next round doesn't repeat this.

## Reproducibility
- Baseline verdicts: `/tmp/claude-1025/baseline-out/` · Hammer verdicts: `/tmp/claude-1025/hammer-out/`
- Compiler (verdict distribution + ranked gaps + missing-ref clusters): `/tmp/claude-1025/compile_report.py`
- Machine-readable dumps: `/tmp/claude-1025/{baseline,hammer}.json`
- Process this followed: `dcm/dav/stress-testing-process.md` (and mirror in `udlm/dav/`).
