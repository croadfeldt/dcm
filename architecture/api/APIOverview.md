## API Overview

The DCM design has two layers of APIs; the control Plane APIs, where users and other services interact, and Service APIs, that encompass the functions encapsulated within a service boundary. Each handles the API payload differently, due to the declarative nature of DCM.

The Control Plane APIs are designed to capture the user declarations and add them to the DCM datastore as the “requested state”. These APIs can also read from the “realized state” to return the status of the request, and provide any inventory specific information to the user.

Service APIs work in reverse; they read from the “requested state” to pass along to the Execution Engine to affect the environment. When the Execution Engine completes the request, the metadata from the realized entity is saved in the “realized state” section.

The metadata used for both the requested state and the realized state must align to the DCM data model. The Control Plane APIs and Service APIs can pull additional metadata from source controlled repos to fill in any additional information required to fulfill the request.
