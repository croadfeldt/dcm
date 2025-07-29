# Taxonomy

## Atomic Service *(Need a nickname)*
The smallest unit of a complete service. This may include numerous items of data and metadata, but it is the smallest unit of a service that can be considered complete and actionable.  
*First needed for applying Rules to services and service catalog items.*

---

## Service
Anything that will be consumed or requested by end users in the process of realizing their request.  
**Example:** VM as a service  
Core item this framework is attempting to facilitate.

---

## Atomic Component
A piece of DCM that performs a set of related functions in service of the overall DCM architecture. These "Components" each have a set of roles and responsibilities for effecting their work for DCM. This is also the scope to which the APIs will be based upon.

It is entirely possible that in an implementation of DCM, a single piece of software may perform multiple Atomic Component roles, as long as they provide the requisite roles, responsibilities, and APIs.

*Do we allow Atomic Component duplication / composability / overlap / overlay?*

**Defined by:**
- Roles
- Responsibilities
- APIs

**Example:** IDM service  
- **Role / Responsibilities:** Performs all functions related to authenticating users and providing user roles / group membership  
- **APIs:** Related to the IDM service

---

## Core Layers / Data
Layers and data that are required for the core function of DCM and services provided through DCM.  
Data that is applicable but not specific to just one atomic service.

**Examples:**
- Location Data
- Rack Data

---

## Business Data
Data that is tangential to realized atomic services, but not part of Core Data.

**Examples:**
- Owner Business unit
- Contact