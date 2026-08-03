# Policy obligations delegated from UDLM

**What this is.** The register of policy work UDLM has *delegated to DCM*. UDLM fixes an invariant every
conformant realization must honor; where UDLM applies the ADR-008 peer test and finds that a conformant
peer could legitimately decide the *mechanism* or the *exception* differently, it stops there and hands the
operational choice to the realization. Each row below is one such hand-off: the UDLM invariant DCM **must
satisfy**, and the policy DCM **must decide** to satisfy it.

This register is the DCM-side counterpart of those ADRs. An obligation is `open` until DCM ships the policy
that discharges it. Add a row whenever a UDLM ADR carries a "Delegated work — the DCM policy obligation"
section.

| ID | Obligation | UDLM source | Status |
|---|---|---|---|
| OBL-001 | Credential-material intake mechanism | UDLM ADR-049 | **open** |
| OBL-002 | Provider-pin eligibility bypass | UDLM ADR-050 | **open** |
| OBL-003 | Provenance sealing — completeness, retention, and port fidelity | UDLM ADR-059 | **open** (pending ADR-059 ratification) |

---

## OBL-001 — Credential-material intake mechanism

**UDLM invariant DCM must satisfy** (ADR-049 / `CPX-013`/`CPX-014`): a credential *literal* submitted where
a *reference* is required is detected and refused; the detection is **ordered before** the intent is
persisted; and the rejecting path persists neither the material nor an echo of it — not in the (immutable)
Intent store, not in the error payload, not in the audit `detail`. Ordering is part of the invariant: a
correct decision taken *after* the write is a failed decision, because the store cannot take it back out.

**Policy DCM must decide:**
- **The mechanism.** Scan-before-persist, intake-time coercion-to-a-reference, or another shape that meets
  the invariant. (ADR-049's catalogue is informative — the honest costs are laid out there so this decision
  need not rediscover them.)
- **The profile floor.** Which profiles accept detect-and-refuse, and which **raise the floor to coercion**
  (the credential provider stores the literal and returns a reference; the persisted intent is well-formed).
  Same profile-priced rigor as bare-vs-governed vocabulary.
- **The false-positive remedy** for the scan path — most plausibly a reviewable per-field opt-out declared
  on the type.
- **Under coercion:** record the transformation + provenance (the vocabulary-ladder discipline), and price
  the narrow `CPX-001` exception — hand-off only, never at rest, never logged.

**Definition of done:** a profile-governed policy that meets the invariant on the consumer-intent path, and
a passing run of UDLM must-reject `003-inline-credential-literal-refused` under DCM's realization.

---

## OBL-002 — Provider-pin eligibility bypass

**UDLM invariant DCM must satisfy** (ADR-050 / `PRV-009`/`PRV-011`): the `effective_capabilities` ceiling
**always applies at the dispatch boundary, on every path**. A pin is **preference among eligible providers**
— it decides *which* eligible provider, never *whether* an ineligible one is reached. A pin naming an
ineligible provider yields `placement.capability_mismatch` **before dispatch**. A capability mismatch is a
`policy_violation`, never a `provider.*` failure (the provider did not break; it was never eligible).

**Policy DCM must decide:**
- **Whether a deliberate bypass exists at all**, per profile — the genuine case of a provider that *can* do
  the work but never declared it. If permitted, its shape: the **override-record flow** (approver, reason,
  scope, time bound — the priced default) or a two-field split (clarity at the cost of a larger surface).
- **The deprecation window** for operators relying on today's absolute-pin behaviour, and the
  declaration-defect remedy (fix the stale declaration) named in the same change — so no operator's pin
  simply "stops working" without a path.
- **The placement-algorithm text**: amend the step that describes the pin as skipping the remaining steps,
  so the eligibility check is unconditional at the dispatch boundary.

**Definition of done:** placement enforces the ceiling on every path (pin included); any bypass is a
recorded, approved, time-bounded override whose permissibility is set per profile; a passing run of UDLM
must-reject `005-provider-capability-mismatch-refused`, typed `policy_violation`.

---

## OBL-003 — Provenance sealing: completeness, retention, and port fidelity

**Pending UDLM ADR-059 ratification (croadfeldt/udlm#342)** — registered now so the obligations land with
the decision, not after it.

**UDLM invariant DCM must satisfy** (ADR-059): every data write on every record, from Intent intake through
layer application and policy writes to Realized — Discovered included — is **sealed** as an OpenLineage
event embedding the working copy and its Layer-1 chain head; the working record carries state claims only
(states + leaf pin + integrity chain — never provenance); lineage is cited **only** from the sealed,
chained, anchored ledger; DCM is the **sole hasher** at both grains; a port never silently degrades
fidelity — every dropped or mapped element is sealed with its authorizing policy.

**Policy DCM must decide:**
- **Emission completeness + delivery** — the declared policy naming what MUST be sealed and the platform
  proof that it was (OL itself guarantees neither); the failure disposition when sealing is unavailable
  (block the write vs queue-and-flag, per profile). For discovery specifically, completeness is
  **cadence attestation**, not chain arithmetic: discovery-run chains deliberately do not link cycle to
  cycle (runs are independent evidence; chains prove what exists is unaltered, never that everything
  that should exist does), so a silently omitted run is caught by declaring the expected discovery
  cadence and raising a finding when a seal is missing against it — the ADR-048 staleness shape
  (`expected_observation` / `on_exceeded`), which also survives seal retention where a chain would not.
- **Opt-in continuity citations, per pathway** — a profile MAY require each discovery-run seal to
  cite the previous run's chain head (the `pathway_ref` citation mechanism, pointed backward),
  giving regulated estates (`fsi`/`sovereign`) structural gap detection without making cross-run
  chaining the substrate default or entangling RHY-008 retention for everyone else. The same
  option applies to **provider event streams** (the third pathway anchor, ADR-059 Decision 4) —
  with a stronger default case for requiring it there: a provider is an interested external
  party, not the platform's own probe, so `fsi`/`sovereign` SHOULD consider continuity citations
  (or provider-signed events) on provider-driven writes even where discovery runs stay uncited.
- **Discovered-seal retention** — profile/policy-decided windows for the snapshot stream (rides the
  RHY-008 retention machinery; the durable-inventory role stays exempt).
- **Provider-scope consumption permission** — whether consumers may bind Provider-scope definitions
  directly, per profile; the catalog projection must price the portability consequence either way.
- **Port-fidelity classes** — which elements are ignorable-on-port vs blocking (the drop/refuse/
  route-to-review split), and the translation-policy admission bar for the mapped grade of the
  compatibility ladder.
- **Ledger operation** — anchoring cadence for the global root (per boundary: git carrier, WORM object
  store), verification cadence, and the tenancy/authorization posture of the ledger store (the platform
  half of the OL gap assignment).
- **L1-verification failure as its own finding class** — a record failing chain verification is TAMPER,
  not drift: separate finding type, separate response matrix row; the walker treats it as REFUSING.
- **The drift policy** (ADR-059 Decision 8 delegates the whole classification surface): per-field
  relevance (which fields matter — observed-only fields and benign jitter are policy-excluded),
  severity classification onto the canonical drift enum, flap debounce, and **the accept
  mechanism** — the deliberately open fork: adopt-the-discovered-value-into-intent (a
  request-pathway change, chained and sealed; cleanest, heaviest) versus an accepted-deviation
  record that suppresses re-detection (lighter, but standing "known divergence" state that must
  be governed and expired). Both are priced in the ADR; this register is where the ruling lands.
- **Finding lifecycle operation** — open-once keying (resource + diverged-field-set),
  confirm-not-duplicate on re-detection, closure by citing resolution seal; current drift status
  is always derived on read, never answered from a finding.

**Definition of done:** a profile-governed sealing policy with platform-proven completeness; retention and
port-fidelity policies shipped; ledger runbook (anchor + verify cadences) in operation; a port exercised
end-to-end whose seals show the full journey including at least one policy-authorized fidelity drop; chain
verification wired into the walker preflight with the tamper finding class emitted on failure.

