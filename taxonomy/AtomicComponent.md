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
