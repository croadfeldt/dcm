# Dependency resolution

**What this settles:** how DCM turns the authored UDLM estate — plus dependencies that arrive by
other means — into **one effective dependency graph** that consumers (ordered shutdown/startup,
topology visualizers, impact/blast-radius analysis) run on. The UDLM data model *stores* dependencies
several ways at the implementor's chosen granularity (see the UDLM doc: dependency modeling); DCM
*resolves* them uniformly so consumers never need to know how any dependency was authored.

Two orthogonal axes: the **authoring pattern** (the shape of a dependency) and the **insertion
mechanism** (how it reaches DCM's view). DCM merges every combination into the effective graph.

## Insertion mechanisms — how a dependency enters the graph

1. **Authored** — declared in the UDLM estate: a resource's `dependencies[]`, a bundle-membership
   edge, a `tenant_uuid`. Versioned, reviewable; the source of truth for stable structure.
2. **Discovered** — a discovery job probes reality (topology/LLDP, hypervisor inventory, cluster API,
   BMC, storage) and inserts observed edges (VM→host, NIC→switch-port, volume→pool). Keeps the graph
   synced with reality and **flags drift** where authored ≠ discovered.
3. **Derived** — computed at resolution time, never stored: bundle membership → the bundle's targets;
   scope (`tenant_uuid`) → the realm's identity/DNS services; transitive component chains
   (host→PSU→feed). This is where "attach one, inherit the rest" happens.
4. **Provider-reported** — a provider, realizing or managing a resource, emits the dependencies it
   alone observes at realization (workload→node, VM→host, reservation→DNS zone), as realized state.
5. **Policy-injected** — an admission/policy rule adds dependencies by condition ("any hypervisor
   depends on its rack's cooling domain"; "any realm member requires the realm IdM"), keeping broad
   invariants out of per-resource authoring.

These compose on one resource: power **authored** (PSU→feed), placement **discovered**, identity
**derived**, cooling **policy-injected**.

## The resolution pass (build-time, not stored)

DCM produces the effective graph as an ordered merge; it is recomputed on demand so it always
reflects the live model:

1. **Seed** with the authored estate edges.
2. **Union discovered** edges; where a discovered edge contradicts an authored one, keep both and
   emit a **drift** finding (authored is intent; discovered is reality).
3. **Union provider-reported** realized edges.
4. **Expand bundles** — for each resource with a membership edge to a `Topology.DependencyBundle`,
   add a dependency on each of the bundle's targets. Recurse for composed bundles.
5. **Derive scopes** — for each resource, inject its realm's `Security.DirectoryService` /
   `Network.AddressService` from `tenant_uuid` (excluding the control-plane resources themselves, to
   avoid cycles), and any `Facility.Location`-scoped ambient dependency.
6. **Apply policy injections** in a defined order.
7. Transitive chains need no special step — they are ordinary edges (`host→PSU→feed`) and fall out of
   graph traversal.
8. **Detect cycles**; a cycle is a resolution error surfaced to the operator (an orderable estate is
   a DAG). Report cyclic members rather than guessing an order.

The result is a DAG of typed edges. Consumers run over it directly:
- **ordered shutdown/startup** — topological sort (stop dependents before dependencies; reverse to
  start), with control-plane resources held last;
- **visualizers** — render the resolved graph, distinguishing authored vs derived vs discovered;
- **impact analysis** — "what breaks if X goes down" is reachability over the same graph.

## Choosing an authoring pattern (best practice)

| Pattern | Granularity | Effort/resource | Fidelity | Use for |
|---|---|---|---|---|
| Direct edge | any | high | exact | specific bindings, one-offs |
| Component chain (PSU→feed) | finest | medium | redundancy-aware | power, network fabric |
| Bundle (attach) | coarse | low | shared/ambient | identity/DNS, site, cooling |
| Scope-derived (field) | coarse | none | ambient | realm from tenant |

Guidance: **start coarse** (bundle/scope) for a fast, correct-enough graph; **refine to
component-level** where redundancy or precision earns the effort. Patterns mix on one resource. Model
power at the PSU→feed level rather than a host-level UPS edge whenever redundancy matters — a coarse
edge silently drops the second rail.

## Boundary

Storage of dependencies (the patterns, the types) is UDLM's; resolution and the insertion mechanisms
are DCM's. This keeps the data model free of computed state and lets an estate be authored coarsely,
finely, or in a mix without changing the model. See `architecture/00-layering-data-model-vs-dcm.md`.
