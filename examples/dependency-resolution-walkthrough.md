# Example: resolving the dependency-modeling estate

A worked walkthrough of the resolution pass (`architecture/dependency-resolution.md`) over the
anonymized example estate (the UDLM repo's `examples/dependency-modeling/`). It shows how
dependencies authored four different ways collapse into one effective graph and a derived order.

## The authored estate (15 resources)

- **Power (component chain).** `host-a` contains two power supplies: `psu-a1 → feed-a` and
  `psu-a2 → feed-b` — two independent rails. `host-b` (at the bench) contains one: `psu-b1 →
  feed-wall`. Power is authored on the PSU, not the host.
- **Realm (bundle).** `realm` is a `Topology.DependencyBundle` whose dependencies are `idm`
  (DirectoryService) + `dns` (AddressService). `host-a`, `host-b`, `svc-app`, `svc-db` each attach to
  it with a single reference edge.
- **App (direct edge).** `svc-app depends_on svc-db`. `svc-app` runs on `host-a`, `svc-db` on `host-b`.
- **Location.** `host-a` in `loc-rack`, `host-b` in `loc-bench`.

Each resource authored only its *local* facts — a PSU names its feed, a host names its rack and its
realm bundle, a service names the DB it talks to. Nobody hand-wired "host-a depends on feed-a and
feed-b and idm and dns."

## Resolution (build-time, not stored)

1. **Seed** with the authored edges.
2. **Bundle expansion** — each member's edge to `realm` becomes a dependency on the bundle's targets.
   That's **8 derived edges**: `{host-a, host-b, svc-app, svc-db} → {idm, dns}`. Attach one edge,
   inherit two.
3. **Scope derivation** — `tenant_uuid` could inject the same realm dependency without even the
   membership edge; here the bundle already carries it, so nothing new. The realm's own upstreams are
   excluded (cycle-safe).
4. **Transitive chains** — no expansion needed. `host-a → psu-a1 → feed-a` and `host-a → psu-a2 →
   feed-b` are ordinary edges, so **host-a's effective power dependency is the union of both feeds**.
   A coarse "host-a on one UPS" edge would have silently dropped the second rail.

Effective graph = authored + derived, 0 cycles.

## Derived shutdown order (topological)

| step | resources | note |
|---|---|---|
| 0 | psu-a1, psu-a2, psu-b1, svc-app | leaf consumers stop first |
| 1 | feed-a, feed-b, feed-wall, host-a, svc-db | |
| 2 | host-b, loc-rack | |
| 3 | loc-bench, realm | |
| 4 | **dns, idm** | control-plane gate — hold until last |

Reverse for startup. Note the payoff: `host-a` stops before **both** its feeds (redundancy honored),
and the realm's identity/DNS stop last — all derived, none of it hand-authored per resource.

## Reproduce

```
python3 shutdown_order.py <path-to>/examples/dependency-modeling   # from the estate-explorer tools
```

See `architecture/dependency-resolution.md` for the mechanics and the UDLM repo's
`docs/dependency-modeling.md` for the data-model side.
