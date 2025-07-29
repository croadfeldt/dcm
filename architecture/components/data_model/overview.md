# DCM - Data Model

## Data Model - Objectives

  * Develop a framework for disseminating IaaC / Config data from base standards to consumption pipelines
  * Data model should enable consumption for provisioning and configuring of infrastructure and if applicable, software for production use
      * Eg; VM provisioning
  * Data model should enable for drift management, remediation and monitoring
  * Can be applied / consumed via layers / templates / direct usage
  * Allows for usage constraints
  * Avoid unanticipated data interactions.
      * Eg; during consumption, does the model allow for any results that are not easily and readily predictable or observable in advance
  * Flexible to contain any entity definition
  * Can be transformed to meet the needs of consumption tools
      * Terraform
      * Ansible
      * 3rd party tools
  * Must be stored in git repository
  * Use / mimic k8s yaml format

## Data Model - Rules

  * Host entities are the binding entities that realized entities attach to form a single unit
  * Everything should start with a base entity
  * Changes are implemented via a layer entity
  * Widgets come implemented via a realized entity which is a unit scoped layer entity made real
  * Layer entities override all previous entities in precedence chain
  * Layer entities must contain the chain of parent entities and maintain precedence order
  * Layer entities contain changes to parent entities or add / remove data
  * No limit on number of parent entities
  * All base and layer entities are immutable
  * All entities must be versioned
  * Changes to an entity result in a new version of the entity
  * Changes to a realized entity are done via a layer entity, resulting in a new realized entity
  * Versions consist of major, minor and revision
      * Major - Compatibility breaking changes
      * Minor - Feature additions, retain compatibility within major version
      * Revision - config data change, retain compatibility within major version
  * Version number components are base 10 numbers without limit
      * Eg; 1.100.34
  * Any piece of data in an entity can have metadata subtag of the base tag / data
      * Eg; Override preference
      * Eg; Basis for config value
      * Eg; Baseline for config value
  * All entities in a chain should maintain the parent format
      * Eg; yaml
  * All realized entities should be directly consumable by target operations
  * Each entity should be in source control, realized entities should be in CMDB and associated with the host entity
  * Each entity should contain a link to it’s parent entity
  * Each entity repo should remain online , or automatically redirect to new repo without impacting existing processes.
  * Origination Date / Time stamp must be included in each entity

## Data Model - Example Git Repo layout

  * Parent Repo(s)
      * Standards
      * Base templates
      * Meta data
      * Context
      * Governance
      * Origination date
  * Git Repo and / or directory structure should consolidate and isolate on the following
  * Standard Layers
      * Base - level 1
      * Specific Use Layers - level 1
  * Downstream logical units
      * Ships - level 2
      * Subs - level 2
      * Specific Use Layers - level 2
  * Enclaves in a logical unit
      * Enclave A - level 3
      * Enclave B - level 3
      * Specific Use Layers - level 4
  * Customizations
      * VM A realized config - level 4
      * Specific Use Layers - level 4

## Data Model - Example

  * Centralized config and provisioned state
  * Layered / templated customization
  * Everything as Code using standard Git processes
  * Observable data supply chain
  * Localization at point of need
  * Data versioning enables audit / compatibility
  * Ancillary Meta-Data
  * JSON / YAML native
  * API native consumption
  * Flexible repo layout based on need
  * Standardized naming schema provides clear reporting

Diagram: Ship, Enclave, Infra, Shore, Request, Git, Cache

## DCM - Data Model - Example data structure

Diagram: Inventory and Configuration

## Scale example for 40k linux vms

40,000 = (CIS Benchmark, Baseline, DMZ, Payments) x (Common Linux Config, RHEL, CoreOS, OEL) x (RHEL version specifics, 6, 7, 8, 9) x Request

40,000 = 3 x 4 x 3 x Request
