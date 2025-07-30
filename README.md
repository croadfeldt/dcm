# DCM
DCM (Data Center Management) is envisioned as a framework designed to provide a "hyperscaler-like cloud experience" for on-premises infrastructure. It aims to centralize and automate the management, observation, and lifecycle of IT/IS services within an enterprise data center. This is a work in progress with the initial stage of HLD documentation completed. Detailed specifications and discussions are on-going. Expertise and opinions are encouraged and welcome.

Here's an architectural overview of DCM, based on the provided documents:

**Core Principles & Goals:**

* **Centralized Management**: Consolidate disparate automation efforts under a single control plane or "single pane of glass" to manage various data center components.  
* **Automation & Self-Service**: Leverage existing automation tools (like Ansible Automation Platform) to offer a self-service model for provisioning, configuration, and day-to-day management. The goal is to enable application teams to define and deploy infrastructure as code.  
* **Declarative Infrastructure**: Define the desired state of infrastructure, with the system working to achieve and maintain that state, aiding in reconciliation between discovered and intended inventory.  
* **Composability**: Emphasize a composable architecture that allows for reusable services and operational efficiencies.  
* **Technology Agnostic Framework**: Designed to be flexible and consume common data formats, translating them to appropriate technologies, though an opinionated model is available.  
* **Full Lifecycle Management**: Enable complete lifecycle management of IT/IS services and ephemeral/declarative infrastructure.  
* **Mimics Kubernetes Design**: Draws inspiration from Kubernetes' orchestration and declarative control plane.

# Status of next release (alpha)

- [ ] todo 1 (owned by ....)
- [ ] todo 2 (owned by ....)
- [ ] todo 3 (owned by ....)
- [ ] todo 4 (owned by ....)

# Recommended Reading
- [overview.md](overview.md) - Project overview - will be merged into READMe.
- [taxonomy.md](taxonomy.md) — DCM taxonomy and definitions

# MVP
*(No text files listed)*

## Other projects in the same space
There are many other projects in the same space, like:

* [Crossplane](https://crossplane.io)
* [Kessel](https://github.com/project-kessel)
* [KRO](https://kro.run)

