Taxonomy

Atomic Service (Need a nickname)
    Smallest unit of a complete service, this may include numerous items of data and meta data, but it is the smallest unit of a service that can be considered complete and actionable. 
    First needed for applying Rules to services and service catalog items.

Service
    Anything that will be consumed or requested by end users in the process of realizing their request
    eg; VM as a service
    Core item this framework is attempting to facilitate

Atomic Component
    Piece of DCM that performs a set of related functions in service of the overall DCM architecture. These "Components" each of have set of roles and responsibilities for effecting their work for DCM. This is also the scope to which the APIs will be based upon.
    It is entirely possible that in an implementation of DCM a single piece of software may perform multiple Atomic Component roles, just as long as they provide the requisite roles, responsibilities and APIs.
    Do we allow Atomic Component duplication / composability / overlap / overlay?
    Defined by
        Roles
        Responsibilities
        APIs
    eg; IDM service
        Role / Responsibilities: Performs all functions related to authenticating users and providing user roles / group membership
        APIs related to the IDM service

Core Layers / Data
    Layers and data that are required for the core function of DCM and services provided through DCM.
    Data that is applicable but not specific to just one atomic service
    eg; Location Data
    eg; Rack Data

Business Data
    Data that is tangentional to realized atomic services, but not part of Core Data
    eg; Owner Business unit
    eg; Contact info