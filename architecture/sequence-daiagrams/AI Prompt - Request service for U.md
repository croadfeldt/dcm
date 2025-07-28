Sequence Prompts - Request service for User

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
User selects and enters data for service to Web UI
Web UI sends service data to Ingress API
Ingress API send service data to Request Processor
Request Processor retrieves appropriate data layers from Core Layer Store
Core Layer Store returns appropriate data layers to Request Processor
Request Processor retrieves appropriate data layers via Service Layer Cache
Service Layer Cache returns appropriate data layers to Request Processor
Request Processor sends prepared request payload to Rules Engine
Rules Engine evaluates rules, approves request and updates request payload as needed
Rules Engine returns prepared request payload to Request Processor
Request Processor stores request payload in Requested Widget Store
Requested Widget Store returns confirmation to Request Processor
Request Processor sends request payload to API Gateway