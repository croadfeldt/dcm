# DCM
DCM (Data Center Management) is envisioned as a framework designed to provide a "hyperscaler-like cloud experience" for on-premises infrastructure. It aims to centralize and automate the management, observation, and lifecycle of IT/IS services within an enterprise data center.

Here's an architectural overview of DCM, based on the provided documents:

**Core Principles & Goals:**

* **Centralized Management**: Consolidate disparate automation efforts under a single control plane or "single pane of glass" to manage various data center components.  
* **Automation & Self-Service**: Leverage existing automation tools (like Ansible Automation Platform) to offer a self-service model for provisioning, configuration, and day-to-day management. The goal is to enable application teams to define and deploy infrastructure as code.  
* **Declarative Infrastructure**: Define the desired state of infrastructure, with the system working to achieve and maintain that state, aiding in reconciliation between discovered and intended inventory.  
* **Composability**: Emphasize a composable architecture that allows for reusable services and operational efficiencies.  
* **Technology Agnostic Framework**: Designed to be flexible and consume common data formats, translating them to appropriate technologies, though an opinionated model is available.  
* **Full Lifecycle Management**: Enable complete lifecycle management of IT/IS services and ephemeral/declarative infrastructure.  
* **Mimics Kubernetes Design**: Draws inspiration from Kubernetes' orchestration and declarative control plane.

# Table of Contents

## Root
- [README.md](README.md) — Project TOC
- [overview.md](overview.md) - Project overview - will be merged into READMe.
- [taxonomy.md](taxonomy.md) — DCM taxonomy and definitions

## architecture

### api
- [APIOverview.md](architecture/api/APIOverview.md) — Overview of DCM APIs
- [ServiceOverview.md](architecture/api/ServiceOverview.md) — Service definition and API structure

### components
#### data_model
- [overview.md](architecture/components/data_model/overview.md) — Data flow model overview
- [DCM-Data_Flow_Model.pdf](architecture/components/data_model/DCM-Data_Flow_Model.pdf) — Data flow model diagram (PDF)

### deployment
*(No text files listed)*

### roles-responsibilities
- [core_functions.md](architecture/roles-responsibilities/core_functions.md) — DCM logical components and functions
- [DCM-Expected_Functions.pdf](architecture/roles-responsibilities/DCM-Expected_Functions.pdf) — Expected functions (PDF)
- [DCM-Expected_Relationships.pdf](architecture/roles-responsibilities/DCM-Expected_Relationships.pdf) — Expected relationships (PDF)

### sequence-daiagrams
- [AI Prompt - List services for Use.md](architecture/sequence-daiagrams/AI%20Prompt%20-%20List%20services%20for%20Use.md) — List services sequence prompt
- [AI Prompt - Request service for U.md](architecture/sequence-daiagrams/AI%20Prompt%20-%20Request%20service%20for%20U.md) — Request service sequence prompt
- [AI Prompt - Service Realization.md](architecture/sequence-daiagrams/AI%20Prompt%20-%20Service%20Realization.md) — Service realization sequence prompt
- [AI Prompt - User Web UI Login.md](architecture/sequence-daiagrams/AI%20Prompt%20-%20User%20Web%20UI%20Login.md) — User login sequence prompt
- [full-login-service-realization.md](architecture/sequence-daiagrams/full-login-service-realization.md) — Combined login, service listing, request, and realization sequence diagram (Mermaid)
- [list-services.md](architecture/sequence-daiagrams/list-services.md) — List services sequence diagram (Mermaid)
- [request-service.md](architecture/sequence-daiagrams/request-service.md) — Request service sequence diagram (Mermaid)
- [service-realization.md](architecture/sequence-daiagrams/service-realization.md) — Service realization sequence diagram (Mermaid)
- [user-login.md](architecture/sequence-daiagrams/user-login.md) — User login sequence diagram (Mermaid)

## example_use_cases
- [DCM-VM_provision-Terraform.pdf](exmaple_use_cases/DCM-VM_provision-Terraform.pdf) — Example use case: VM provisioning with Terraform (PDF)

## Other projects in the same space
There are many other projects in the same space, like:

* [Crossplane](https://crossplane.io)
* [Kessel](https://github.com/project-kessel)
* [KRO](https://kro.run)
