Sequence Prompts - Service Realization

Objects:
User
Web UI
Ingress API
IDM Service
Auth Source
Service Catalog
Request Payload Processor
Entity Layer Store
Rules Engine
Rules Store
Core Data
Service API
Service
Service Automation
Provisioned Store

Messages:
API Gateway sends prepared request payload to appropriate Service Provider
Service Provider converts unified payload data to tool naturalized
Service Provider send native tool payload to Service Automation
Service Automation performs the required actions to realized the payload
Service Automation sends realized data payload with status to Service Provider
Service Provider converts realized data payload to unified payload format
Service Provider sends realized unified data payload to API Gateway
API Gateway stores realized data payload in Provisioned Data Store
API Gateway sends status back to Web UI
Web UI displays status to User