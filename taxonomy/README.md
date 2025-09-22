# Taxonomy of DCM

This taxonomy of DCM achieves three key goals. First, it defines the top-level domains that distinguish  the functions and roles of the DCM architecture. Next, it defines a specific vocabulary with the intent of enabling precision and clarity by eliminating ambiguity. Finally, an "anti-vocabulary" defines a list of ambiguous phrases and "weasel words" to avoid and recommends more specific terms to use instead.

## Top-level architectural domains

The taxonomy defines the functional areas enabled by the DCM architectural as five top-level domains. Each domain maps a set of DCM services and resources defined by the architecture to the different roles and teams across an organization that experience them.

The top-level domains are defined as follows:

1. **Developer Experience** - This domain focuses on the unified interface that developers and application owners use to interact with DCM. It includes the self-service catalog, templates, and all user-facing documentation. This is where the DCM abstractions are consumed. Multi-tenancy is experienced at this level.
2. **Control Plane** - This is the central nervous system of DCM. It provides the unified API and maintains the DCM data model including the inventory of resources. It also enforces authentication and role-based access control.
3. **Orchestration & Automation** - This domain contains the code and workflows for provisioning and managing resources. It provides the engines that execute commands from the control plane to interact with the underlying Composable Infrastructure.
4. **Composable Infrastructure** - This domain represents the physical and virtual assets in the data center. It includes the compute, storage, and networking resources that are managed by the automation domain.
5. **Governance & FinOps** - This domain is a set of overarching requirements that ensure that DCM operations are secure, compliant, and cost-effective. It encompasses policy management, real-time metrics, and cost allocation.

Everything in the DCM architecture exists under one of these domains.

How these domains are connected can be easily understood using a layer cake analogy.

![Layer cake analogy drawing described below](./images/layer_cake.png)

Each layer of cake represents a domain that interacts only with the domains directly above and below it. For example, the architecture prohibits a direct connection from the Developer Experience domain to the Orchestration & Automation domain, Instead, Developer Experience must always use the Control Plane to request and manage resources available from the lower domains.

The exception to this rule is the Governance & FinOps domain. It is the frosting of our cake and it touches all the layers. This aligns with the overarching functions of the Governance & FinOps domain requiring observability at every level of the architecture.

## Vocabulary

DCM is a complex technology architecture stretching from the depths of bare metal on data center floor up to the high-level abstractions required to achieve secure multi-tenancy in the service of cloud consuming application owners and developers.

The vocabulary we use to define this architecture demands precision and clarity. By allowing a term to have a distinct, contextual definition within each architectural domain, we can eliminating ambiguity even when using the same words.

For example, the "resource" a developer requests for their application is a logical entity, for example, a "Web App Service." However, the "resource" that the Infrastructure Operations team manages is a physical asset like a specific VM with a particular IP address. By providing distinct definitions for the same term in each domain, we confusion as we navigate through the architectural domains.

When adding new terms to the vocabulary, take care to map the terms to the roles and functions relevant to each applicable domain.

### Multi-tenant

DCM multi-tenancy is experienced at the Developer Experience domain and enforced by the Control Plane.

The Orchestration & Automation and Composable Infrastructure domains operate in "privileged mode” to implement the isolation and confinement required for multi-tenancy.

The Governance & FinOps domain has access to the tenant-wide scope required to implement policy management, monitoring and billing.

### User

In the absence of further context, a "User" is the human consumer of cloud computing resources and services experiencing DCM from the Developer Experience domain. Of course, other humans "use" DCM within the other domains, so consider using Developer or Application Owner instead.

To avoid confusion, avoid using "User" when referring to humans acting within the the other DCM domains. Consider more specific persona alternative terms such as Platform Engineer, Infrastructure Operations, Risk and Compliance Manager, etc.

### Workload placement

Workload placement policies are managed within the Governance & FinOps domain and enforced within the Control Plane domain.

## Anti-vocabulary

FIXME: explain what is anti-vocabulary.

### Realize

To realize can mean to bring something into existence, to make something intangible less so, to achieve a goal, or even just to understand as in "Ah, now I realize what's going on." Given all these meanings, avoid using this word. Consider more precise words like provision as in a VM, install as in a software package, fulfill as in a request, etc.

### Tangible

Nothing in the DCM architecture is intangible. Tangible and intangible are weasel words that sound important but don't add any clarity or meaning. Avoid using these words.

### Widgets

Widget are things, but what things exactly? Rather than saying widgets, find the precise word for the resource or service for the thing you are talking about.
