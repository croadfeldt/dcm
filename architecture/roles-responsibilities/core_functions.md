# DCM Logical Components

## Control Plane

### Functions

#### Cost Analysis
- **Purpose:** Capability to analyze cost of service to consumer.

#### Orchestration
- **Purpose:** Coordinate the specific actions needed to facilitate the realization of the Request Payload.

#### Audit *(Combine with Observability?)*
- **Purpose:** Ability to log actions and report on functions and data used during DCM lifecycle functions and activities.

#### Service Catalog
- **Purpose:** Provides list of Services available for consumption by consumers.

#### Rules Engine
- **Purpose:** Ability to interpret rules and take appropriate actions defined by them based on input data.

#### IDM / IAM
- **Purpose:** Ability to authenticate and retrieve info on consumers and providers of DCM.

#### Observability
- **Purpose:** Ability to log actions and report on functions and data used during DCM lifecycle functions and activities.

#### Widget Discovery?
- **Purpose:** Ability to discover, audit and report on infrastructure and data for the purpose of discovering state of identified items.

#### Message Bus
- **Purpose:** Ability to send messages into and out of DCM in a common message queue format.

#### API Gateway
- **Purpose:** Central clearing house for the DCM control plane. Responsible for providing API ingress for consumers, internal processes and egress for Service Provider integration. Also manages some of the internal processes of the control plane to ensure information is passed between appropriate DCM control plane services.

#### Request Payload Processor
- **Purpose:** Responsible for creating the target service payload based on input from the consumer, core data layers, core data and service layers combined into a single payload using a unified data model. This payload will then be consumed by the service providers to effect the desired state.

#### Drift Remediation / Notification
- **Purpose:** Responsible for detecting drift between discovered state, requested state and provisioned state. Once detected, notification and/or remediation should be performed by this function and designated by Rules Engine.

### Data Sources

#### Service Catalog Cache
- **Purpose:** Act as storage cache for services offered by the service providers.

#### Core Rules
- **Purpose:** Rules that are scoped to all actions possibly taken by DCM, regardless of service provided. Also a store for service level rules that are NOT owned by the service provider.
    - *eg; Security Team enforcing rules for a service*
- **Caveat:** Since this is a modular design, it is entirely possible that all service specific rules will be injected via the service provider as to ensure coordination between service providers and relevant security/audit teams.

#### IDM
- **Purpose:** Act as store for User authentication and information in support of RBAC service(s).

#### Core Layers
- **Purpose:** Layers for the data payload that are outside the scope of the specific service(s)
    - *eg; Data Center layer*
    - *eg; Rack layer*

##### Core Data *(Could be combined with Core Layers?)*
- **Purpose:** Provides specific information that is outside the scope of the specific service(s)
    - *eg; Data Center Name*
    - *eg; Service categories*

##### Business Data / Groups *(Could be combined with IDM?)*
- **Purpose:** Provide group information specifically to supply information on business groups for consumers/services.
    - *eg; Business Unit info*
    - *eg; Business related organizational information*
    - *eg; Product Owner*

##### Discovered Widgets *(This may belong in the realm of service providers)*
- **Purpose:** Cache information that was discovered by Widget Discovery functions. Used to compare discovered state with requested and provisioned state
    - *eg; Used for drift remediation and notification services*

##### Requested Widgets
- **Purpose:** Store of all request payloads as provided to the service providers. This is meant as a record of what was requested and for use by any audit and drift remediation processes.

##### Realized Widgets
- **Purpose:** Store of all realized request payloads as provisioned by the service providers.
- **Intent / Use:** This is meant to be a record of what was realized/provisioned by the service providers, including any additional detail they add during the process. Used for audit, reporting and drift remediation processes.

##### Log Store
- **Purpose:** Store of all actions/data used during the lifecycle of a DCM action/process.
- **Intent / Use:** Used by audit, reporting and historical record processes.

##### Service Layer Cache
- **Purpose:** Cache of all layer sources of data used to create a request payload for a service.
- **Intent / Use:** Stores the data layers that will be used to create the request payload, by the request payload processor.

---

## Consumer Ingress

### Functions

#### Web UI
- **Purpose:** Provides the web UI services to the end user/web consumer of DCM.
- **Intent / Use:** Builds UI, interacts with consumer and provides DCM services by means of a web interface.

#### Consumer API
- **Purpose:** Provides the consumer level API spec/services.
- **Intent / Use:** Direct consumption of Services via unified API model provided by DCM.

### Data Sources

- N/A

---

## Egress

### Functions

#### Messaging
- **Purpose:** Provides a messaging protocol from DCM to external systems.
- **Intent / Use:** Allows for interaction with external services outside the use of the Interoperability API.

#### Interoperability API
- **Purpose:** Provides a common API spec and data model to interact with Service Providers.
- **Intent / Use:** Be able to pass data to a DCM service provider in order for them to consume and effect the desired change or exchange data.

### Data Sources

- N/A

---

## Service Provider

### Functions

#### Services API
- **Purpose:** Means to communicate with DCM in unified API spec and data format.
- **Intent / Use:** Provides means to allow DCM to pass data to the Service Provider in order to have the Service Provider effect some change or exchange data.

#### Naturalization
- **Purpose:** Provide a conversion process from the DCM unified data model to a tool/service provider specific data format that is consumable by the provider tooling.
- **Intent / Use:** Allows DCM to have a unified data and API model that can still execute via native tooling or service provider automation.

#### Realization
- **Purpose:** Process to effect the desired change or exchange information.
- **Intent / Use:** Service Provider tooling/automation performs the steps needed to effect the desired change or gather required information.

#### Denaturalization
- **Purpose:** Opposite of Naturalization, convert tool or provider specific data into the DCM Unified data model.
- **Intent / Use:** Allows DCM to interact with the data created during the realization process via its natural data model. Allows for drift and audit processes in DCM without need for data translation.

### Data Sources

#### Service Catalog / APIs
- **Purpose:** Details the list of services the service provider provides and the appropriate APIs to call.
- **Intent / Use:** Informs DCM as to what services the provider has and what APIs to use to utilize those services.

#### Service Rules
- **Purpose:** Business Rules specific to the services provided by the Service Provider.
- **Intent / Use:** Applies specific conditional and data manipulation and enforcement policies for the services provided. Useful for Security, Authorization, Validation, etc.

#### Service Layer SCM
- **Purpose:** Location of service specific data layers for the services provided by the provider.
- **Intent / Use:** Informs DCM on where to get the required data layers for the request payload needed for each service provided.

### Data

#### Service Request Payload
- **Purpose:** Data that defines the requested service/data exchange.
- **Intent / Use:** Data in DCM data model format to be converted into tool/provider specific data and then used to perform required actions to realize requested service/data exchange.

#### Realized Request Payload
- **Purpose:** Data that was created as a result of the realization process after it has been converted back into the DCM data model format.
- **Intent / Use:** Snapshot of the state/data that defines the realized state of the Service Request Payload in the DCM data model format. Used during audit and drift processes in DCM.