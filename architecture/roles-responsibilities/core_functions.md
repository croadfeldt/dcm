# DCM Logical Components

## Purpose, Role, Responsibility

- **Purpose:** Why it exists  
- **Role:** What it does  
- **Responsibility:** What it owns  

---

## Control Plane

### Functions

#### Cost Analysis
- **Purpose:** Allow consumers to understand true cost of requesting/utilizing a service throughout its lifecycle.
- **Role:** Provide full costing of services during the lifecycle of a service through DCM.
- **Responsibility:** All accounting functions required to inform consumers of the true cost of services throughout the lifecycle of a service estimate or request.

#### Orchestration
- **Purpose:** Ensure the lifecycle of a request from instantiation to fulfillment.
- **Role:** Coordinate and manage required DCM functions to facilitate the realization of the request.
- **Responsibility:** Manage and coordinate other functions in DCM to fulfill a request.

#### Audit *(Combine with Observability?)*
- **Purpose:** Allow appropriate personas to review/validate transactions end-to-end through the DCM architecture.
- **Role:** Provide reports, analysis, and interactive interrogation of transaction details to support SRE, Auditors, Security teams, and Consumer personas.
- **Responsibility:** All functions related to reporting, analysis, and interrogation of transactions for security, RBAC, and operational details.

#### Service Catalog *(Should this be the initiator of a service request?)*
- **Purpose:** Provide catalog of services available for consumption by consumers.
- **Role:** Facilitate the presentation of available services based on RBAC rules.
- **Responsibility:** Manage the lifecycle of available services and present a catalog based on RBAC rules.

#### Rules Engine
- **Purpose:** Perform business, operational, and decision-making rules for various information domains (e.g., RBAC, service validation, data injection/manipulation).
- **Role:** Execute logic based on predefined rules/rulesets triggered by request payload data.
- **Responsibility:** All business logic required to facilitate a request payload becoming realized.

#### IDM / IAM
- **Purpose:** Authenticate and retrieve info on consumers and providers of DCM.

#### Observability
- **Purpose:** Log actions and report on functions and data used during DCM lifecycle functions and activities.

#### Widget Discovery
- **Purpose:** Discover, audit, and report on infrastructure and data to determine the state of identified items.

#### Message Bus
- **Purpose:** Send messages into and out of DCM in a common message queue format.

#### API Gateway
- **Purpose:** Central clearing house for the DCM control plane. Provides API ingress for consumers, internal processes, and egress for Service Provider integration. Manages internal processes to ensure information is passed between appropriate DCM control plane services.

#### Request Payload Processor
- **Purpose:** Create the target service payload based on consumer input, core data layers, and service layers combined into a unified data model. Consumed by service providers to effect the desired state.

#### Drift Remediation / Notification
- **Purpose:** Detect drift between discovered state, requested state, and provisioned state. Perform notification and/or remediation as designated by Rules Engine.

---

### Data Sources

#### Service Catalog Cache
- **Purpose:** Storage cache for services offered by service providers.

#### Core Rules
- **Purpose:** Rules scoped to all actions possibly taken by DCM, regardless of service provided. Also stores service-level rules not owned by the service provider.
    - *Example: Security Team enforcing rules for a service*
- **Caveat:** In a modular design, service-specific rules may be injected via the service provider to ensure coordination with security/audit teams.

#### IDM
- **Purpose:** Store for user authentication and information in support of RBAC services.

#### Core Layers
- **Purpose:** Layers for the data payload outside the scope of specific services.
    - *Example: Data Center layer, Rack layer*

#### Core Data *(Could be combined with Core Layers?)*
- **Purpose:** Information outside the scope of specific services.
    - *Example: Data Center Name, Service categories*

#### Business Data / Groups *(Could be combined with IDM?)*
- **Purpose:** Group information for business groups related to consumers/services.
    - *Example: Business Unit info, Organizational info, Product Owner*

#### Discovered Widgets *(May belong in service providers)*
- **Purpose:** Cache information discovered by Widget Discovery. Used to compare discovered, requested, and provisioned state.
    - *Example: Used for drift remediation and notification*

#### Requested Widgets
- **Purpose:** Store all request payloads provided to service providers. Used for audit and drift remediation.

#### Realized Widgets
- **Purpose:** Store all realized request payloads as provisioned by service providers.
- **Intent/Use:** Record what was realized/provisioned, including additional details from providers. Used for audit, reporting, and drift remediation.

#### Log Store
- **Purpose:** Store all actions/data used during the lifecycle of a DCM action/process.
- **Intent/Use:** Used by audit, reporting, and historical record processes.

#### Service Layer Cache
- **Purpose:** Cache of all layer sources of data used to create a request payload for a service.
- **Intent/Use:** Stores the data layers used to create the request payload.

---

## Consumer Ingress

### Functions

#### Web UI
- **Purpose:** Provide web UI services to end users/web consumers of DCM.
- **Intent/Use:** Build UI, interact with consumers, and provide DCM services via web interface.

#### Consumer API
- **Purpose:** Provide consumer-level API spec/services.
- **Intent/Use:** Direct consumption of services via unified API model.

### Data Sources

- N/A

---

## Egress

### Functions

#### Messaging
- **Purpose:** Provide messaging protocol from DCM to external systems.
- **Intent/Use:** Interaction with external services outside the Interoperability API.

#### Interoperability API
- **Purpose:** Provide common API spec and data model to interact with Service Providers.
- **Intent/Use:** Pass data to a DCM service provider for consumption and effecting changes or exchanging data.

### Data Sources

- N/A

---

## Service Provider

### Functions

#### Services API
- **Purpose:** Communicate with DCM in unified API spec and data format.
- **Intent/Use:** Allow DCM to pass data to the Service Provider to effect changes or exchange data.

#### Naturalization
- **Purpose:** Convert DCM unified data model to tool/service provider-specific format.
- **Intent/Use:** Enable unified data/API model execution via native tooling or automation.

#### Realization
- **Purpose:** Effect the desired change or exchange information.
- **Intent/Use:** Service Provider tooling/automation performs steps to effect change or gather information.

#### Denaturalization
- **Purpose:** Convert tool/provider-specific data into the DCM Unified data model.
- **Intent/Use:** Allow DCM to interact with realized data in its natural model for drift and audit processes.

### Data Sources

#### Service Catalog / APIs
- **Purpose:** List of services provided and appropriate APIs.
- **Intent/Use:** Inform DCM of available services and APIs.

#### Service Rules
- **Purpose:** Business rules specific to services provided.
- **Intent/Use:** Apply conditional, data manipulation, and enforcement policies (e.g., Security, Authorization, Validation).

#### Service Layer SCM
- **Purpose:** Location of service-specific data layers.
- **Intent/Use:** Inform DCM where to get required data layers for request payloads.

### Data

#### Service Request Payload
- **Purpose:** Data defining the requested service/data exchange.
- **Intent/Use:** Data in DCM format to be converted to provider-specific format for realization.

#### Realized Request Payload
- **Purpose:** Data created as a result of realization, converted back to DCM format.
- **Intent/Use:** Snapshot of realized state for audit and drift processes.