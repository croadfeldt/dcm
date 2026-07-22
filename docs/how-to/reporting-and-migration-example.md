# Re-porting a workload across providers — a worked example (and its limits)

**What this is.** The concrete migration process behind the model's "re-porting" (UDLM ADR-038). It exists
because the honest answer to *"can you cast a VMware VM to an OpenShift VM?"* is **"the model enables it; it does
not perform it — and how much ports is a function of the requirements, not a promise."**

## Set expectations first (the caveats)

- **Enablement, not execution.** DCM + the model give you the *data framework* to plan and drive a re-port — the
  requirements, the dependency set, the eligible targets, and what won't fit. **Moving or repopulating the data
  is always a third party** (e.g. **MTV** for VMware→OCPVirt disk migration). DCM alone cannot move a disk.
- **A re-port is a rebuild, not a lift-and-shift.** You re-realize the workload from its *requirements* on the
  target's native services — the same as redeploying to a new cloud. The substrate never carries the source's
  native form across (naturalization boundary, ADR-023).
- **Portability is not 100 %.** Source-specific features with no target equivalent don't port; a partial/assisted
  re-port is the normal outcome, and a modest success rate is a win. The model's job is to make the *achievable*
  part automatic and **surface the remainder**, not to hide it.

## The mechanism — a rebuild reuses the original requirements

The key: **a "rebuild from requirements" is not from scratch.** The input is the workload's *own request* — the
requirement set it was realized from. Re-porting **re-realizes that set against the target provider**, and
`SharedDataElement` **scoping** is exactly what decides how much carries over automatically:

| Element scope | Carries to the target… | Why |
|---|---|---|
| **Base Class** (`Compute`) | **always** — every provider honors it | portable by definition (cpu, memory, storage requirements, network requirements) |
| **Type Class** (`Compute.VM`) | across the **type's** providers | portable across VM providers; the target re-satisfies it natively |
| **Provider Class** (`Compute.VM.OCPVirt`) | **only if the target has an equivalent** | provider-specific; maps to a target element or becomes the **surfaced remainder** |

So a re-port is: **take the original requirement set → re-scope it against the target's advertised capabilities
→ the portable subset re-realizes automatically; the non-portable remainder is what a human (or downstream
automation) rebuilds.** Scoping an element *higher* (Base/Type) is how you extend portability wherever a target
can honor it — that is the whole reason `SharedDataElement` carries a scope.

## Example A — portable migration (Base/Type only)

A VM requested at the **Type Class** with portable requirements only:

```yaml
class: Compute.VM
requirements:            # all Base/Type SharedDataElements — portable
  cpu: { min_cores: 8 }
  memory: { min_gib: 32 }
  storage: [ { tier: ssd, min_gib: 500 } ]        # requirements descriptor (ADR-036)
  os_image: { family: rhel, version: "9" }         # by standard identity (ADR-035), not a vendor image id
  network: [ { isolation: private, egress: restricted } ]   # portable network requirement
```

**Re-port to a different VM provider:** every requirement is Base/Type-scoped, so the set carries **wholesale** —
Placement (ADR-007/019) picks the new provider, and the workload re-realizes with no requirement loss.

**Still not free:** the *requirements* port; the *disk contents* do not. A third-party mover (MTV, `virt-v2v`, or
a backup/restore) moves or repopulates the data. High success rate, because there is no provider-specific surface.

## Example B — provider-explicit (VMware on NSX → `Compute.VM.OCPVirt` on OVN)

The reviewer's case. The source VM carries **provider-specific** elements alongside the portable ones:

```yaml
class: Compute.VM.VMware
requirements:
  cpu: { min_cores: 8 }                             # Base — ports
  memory: { min_gib: 32 }                           # Base — ports
  storage: [ { tier: ssd, min_gib: 500 } ]          # Type — ports
  os_image: { family: rhel, version: "9" }          # Type — ports
  network: [ { isolation: private, egress: restricted } ]   # Type — ports as a *requirement*
  nsx_security_group: prod-web-tier                 # Provider (VMware/NSX) — needs a target equivalent
  distributed_switch: dvs-prod-01                   # Provider (VMware) — no OCPVirt equivalent
```

**Rebuild from requirements onto OCPVirt/OVN:**
1. **The portable subset re-realizes automatically** — cpu / memory / storage / os_image / the *network
   requirement* (`isolation: private, egress: restricted`) all have OCPVirt/OVN native realizations. Note the
   network requirement ports because it was expressed at the **Type Class** as *what must hold* — the OVN
   provider naturalizes it to a `NetworkPolicy`, exactly as NSX naturalized it to a security group. That is the
   payoff of stating the requirement portably instead of storing the NSX construct.
2. **The provider-specific remainder is surfaced** — `nsx_security_group` maps to the OVN equivalent *iff* the
   intent behind it was captured as a Type-class requirement (above); the raw NSX group name does **not** cross.
   `distributed_switch` has no OCPVirt equivalent and is dropped, **flagged as non-portable** in the re-port
   report — a human decides whether it mattered.
3. **A third party moves the disk** — MTV performs the VMware→OCPVirt disk migration; DCM re-realizes the spec
   around it. Partial/assisted success — expected and made explicit.

The difference between A and B is **not** the mechanism; it's how much of the requirement set was expressed
portably (Base/Type) vs locked to the provider. The model doesn't make NSX portable — it makes the *portion you
expressed as requirements* portable, and tells you honestly what's left.

## What always needs a human or a third party
- **Data movement / repopulation** — a mover (MTV, `virt-v2v`, backup/restore). Never DCM.
- **The non-portable remainder** — provider-specific features with no target equivalent; surfaced, not silently
  dropped.
- **Advanced rebuilds** — where even the requirements need reshaping; the original request is still the starting
  point, not a blank page.

## References
- UDLM **ADR-038** — the scoped-Class model + *Re-porting* + *Operational expectations* (this doc is the "how" it
  defers to).
- DCM **ADR-020** (migration & operational gating), **ADR-023** (provider naturalization boundary),
  **ADR-007/019** (placement), **ADR-025** (scoped-Class realization).
- **MTV** (Migration Toolkit for Virtualization) — the third-party disk mover in the VMware→OCPVirt examples.
