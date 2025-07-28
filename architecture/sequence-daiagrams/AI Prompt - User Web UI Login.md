Sequence Prompts - User Web UI Login

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
User initiates login to Web UI
Web UI sends authentication request to the Ingress API
Ingress API validates user login credentials via IDM
IDM Service authenticates user with target Auth source
Auth Source returns authentication success to IDM Service
IDM returns authentication token to Ingress API
Ingress API returns token to Web UI
Web UI returns token and entry page to User 