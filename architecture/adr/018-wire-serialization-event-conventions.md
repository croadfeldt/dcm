# ADR-018: Wire Serialization & Event Conventions

**Status:** Accepted
**Date:** June 2026
**Docs:** ADR-003 (Four Lifecycle States), ADR-009 (API Gateway & Control Plane); UDLM `registry/naming-conventions.md` §4; CNCF CloudEvents
**Tracking:** companion to the UDLM data-model casing decision (naming-conventions §4)

## Context

UDLM defines the **data model** and fixes its on-the-wire casing — **`camelCase` keys** (UDLM `naming-conventions.md` §4): UDLM is an API- and event-bus-driven model consumed by code, not hand-edited config. DCM is the **runtime** that serializes and transports that model — over REST/gRPC at the API gateway (ADR-009) and over the event bus — between services written in **Go and Python**. This ADR covers the DCM-side conventions so the camelCase contract flows end to end without per-hop key-translation layers. (The casing of the data model itself is UDLM's call; this ADR is how the runtime honors it.)

## Decision

1. **Wire payloads are `camelCase`** — request/response bodies and event payloads match the UDLM data model. No snake_case↔camelCase translation layer between the API, the event bus, and services.

2. **Go services:** PascalCase exported struct fields with explicit tags — `json:"camelCase" yaml:"camelCase"`. Go keeps its idiom; the wire stays camelCase.
   ```go
   type ResourceDefinition struct {
       ResourceID  string `json:"resourceId" yaml:"resourceId"`
       MemoryLimit string `json:"memoryLimit" yaml:"memoryLimit"`
   }
   ```

3. **Python services:** native `snake_case` attributes via **Pydantic** with `alias_generator=to_camel` + `populate_by_name=True`; serialize `by_alias=True`. Python keeps PEP 8; the wire stays camelCase.

4. **Events use the CloudEvents envelope** (CNCF). Event **payload** property keys are `camelCase`. Event **type identifiers / topics** are lowercase **dot notation** — `resource.discovered`, `entity.realized`, `resource.definition.created` — so brokers (Kafka/NATS/etc.) can **wildcard-route** (`resource.definition.*`). Topics are never camelCased.

5. **No ad-hoc translation.** Frontends, third-party webhooks, and microservices consume the same camelCase shape; serialization config is centralized (Go tags / Pydantic aliasing), not reinvented per service.

## Options considered

- **snake_case on the wire** — rejected: forces manual `json:"snake_case"` tags on every Go field anyway, and adds friction for any web/UI/webhook consumer.
- **PascalCase keys** — rejected: legacy CloudFormation idiom only; unnatural for the Go/Python/JS consumers here.
- **camelCase topics** — rejected for event *names*: breaks broker wildcard routing; dot-notation is the broker-friendly idiom.

## Consequences

- Frontends and third-party webhook consumers ingest payloads directly — no key-translation layer.
- Fewer custom serialization configs across microservices; one convention from API request → event bus → service.
- Events are CloudEvents-compliant; dot-notation topics enable wildcard subscriptions.
- Go and Python each keep their native idioms; the boundary mapping is mechanical (struct tags / Pydantic).
- This ADR is the DCM realization of UDLM `naming-conventions.md` §4 — the data-model casing is owned by UDLM; the transport/serialization conventions are owned here.
