sequenceDiagram
    participant User
    participant Authentication Server
    participant Core Data Store
    participant Service Catalog
    participant Service Operational Store
    participant Compute Service Provider

    User->>Authentication Server: Login with Credentials
    activate Authentication Server
    Authentication Server->>Authentication Server: Verify Credentials
    alt Authentication Successful
        Authentication Server-->>User: Login Successful
        deactivate Authentication Server
        User->>Compute Service Provider: Request Compute Offering
        activate Compute Service Provider
        Compute Service Provider->>Core Data Store: Retrieve Available VPCs (based on Role)
        activate Core Data Store
        Core Data Store-->>Compute Service Provider: Available VPCs
        deactivate Core Data Store
        Compute Service Provider->>Service Catalog: Retrieve Compute Offering Details
        activate Service Catalog
        Service Catalog-->>Compute Service Provider: Offering Details
        deactivate Service Catalog
        Compute Service Provider->>Service Operational Store: Retrieve Policies & Rules
        activate Service Operational Store
        Service Operational Store-->>Compute Service Provider: Policies & Rules
        deactivate Service Operational Store
        Compute Service Provider->>Compute Service Provider: Validate Request (Policies, Rules, VPC)
        alt Request Valid
            Compute Service Provider->>Compute Service Provider: Build Request Payload (Common Data Format)
            Compute Service Provider->>Compute Service Provider: Transform Payload
            Compute Service Provider->>Compute Service Provider: Provision VM (via Provider API)
            Compute Service Provider <-- Compute Service Provider: Provision Status
            Compute Service Provider->>Compute Service Provider: Update Provision Status
            Compute Service Provider --> User: Report Success
        else Request Invalid
            Compute Service Provider --> User: Report Failure (Error Details)
        end
        deactivate Compute Service Provider
    else Authentication Failed
        Authentication Server --> User: Login Failed (Error Details)
        deactivate Authentication Server
    end
