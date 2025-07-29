Sequence Prompts - List services for User

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
Web UI requests services from Ingress API
Ingress API requests services from Service Catalog
Service Catalog forwards Service list and User to Rules Engine
Rules Engine requests User Group / Role membership from IDM
IDM returns Groups / Roles to Rules Engine
Rules Engine retrieves appropriate rules from Rules Store
Rules Store returns rules to Rules Engine
Rules Engine returns list of authorized services to Service Catalog
Service Catalog returns Service Catalog items to Web UI
Web UI returns Service UI to User
