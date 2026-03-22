# Data Flow Architecture Methodology

## Overview

Data flow architecture documentation captures how information moves through a system—from entry points through processing stages to final destinations. This methodology provides a systematic approach to mapping, documenting, and validating data flows across complex distributed systems.

## The Three Views

### Conceptual View (Business/PM Focus)
**Audience**: Product managers, business analysts, non-technical stakeholders

**Purpose**: Communicate what the system does in terms of business value

**Content**:
- Key business entities and their relationships
- User-visible data flows and their outcomes
- High-level system boundaries
- Business rules governing data transformations

**Example**:
> "When a customer places an order, the system verifies inventory, processes payment, and sends a confirmation email. The order is stored for fulfillment and analytics."

### Logical View (Developer/Architect Focus)
**Audience**: Software engineers, solution architects

**Purpose**: Define how the system achieves data flow requirements

**Content**:
- Services and their responsibilities
- API contracts and interfaces
- Data transformation logic
- Protocol specifications
- Schema definitions

**Example**:
> "The Order Service exposes a REST endpoint at POST /orders. It validates the order against the Inventory Service via gRPC, publishes an OrderCreated event to Kafka, and stores the order in PostgreSQL."

### Physical View (Operations/DevOps Focus)
**Audience**: Infrastructure engineers, SREs, operations teams

**Purpose**: Define how the system is deployed and operated

**Content**:
- Container/pod specifications
- Network topology and security zones
- Scalability and performance characteristics
- Monitoring and observability points
- Disaster recovery configurations

**Example**:
> "The Order Service runs in a Kubernetes deployment with 3 replicas behind an internal Ingress. It connects to the Inventory Service in the same namespace via ClusterIP service. All gRPC traffic uses mTLS."

## Data Flow Levels (C4 Model)

### Level 0: System Context
Shows the entire system as a single process with external entities.

**Purpose**: Establish scope and boundaries

**Elements**:
- System as a single process
- External entities (people, systems)
- Trust boundaries
- Input/output data flows

### Level 1: Container Diagram
Shows the major containers (services, databases) and their interactions.

**Purpose**: Identify architectural components

**Elements**:
- Containers (services, apps, databases)
- Interactions between containers
- Technology choices per container
- External system connections

### Level 2: Component Diagram
Shows components within each container.

**Purpose**: Detail implementation within services

**Elements**:
- Components within each container
- Data transformations
- Internal queues and buffers
- Component responsibilities

### Level 3: Sequence/Activity Diagrams
Shows detailed flow for critical paths.

**Purpose**: Enable implementation and debugging

**Elements**:
- Detailed sequence of operations
- Timing and ordering
- Error handling and recovery
- Full data transformation chain

## Documentation Components

### For Each Data Flow

1. **Identity**
   - Unique name
   - Purpose description
   - Business value

2. **Source**
   - Origin entity
   - Format/schema
   - Frequency/volume
   - Authentication

3. **Transport**
   - Protocol (HTTP, gRPC, Kafka, etc.)
   - Network path
   - Serialization format
   - Security controls

4. **Processing**
   - Transformations
   - Validations
   - Business logic
   - State changes

5. **Storage**
   - Persistence layer
   - Schema/indexes
   - Retention policies
   - Access patterns

6. **Destinations**
   - Downstream consumers
   - SLA requirements
   - Delivery guarantees

## Common Patterns

### Synchronous Request-Response
- Client sends request, waits for response
- Low latency, tight coupling
- Failure immediately visible

### Asynchronous Messaging
- Producer sends message, continues processing
- Loose coupling, delivery guarantees
- Retry and dead-letter handling

### Event Streaming
- Immutable event log
- Multiple consumers independently
- Replay capability

### Batch Processing
- Large volume, scheduled processing
- Checkpoint and restart
- Audit trails

## Best Practices

### 1. Audience-Based Documentation
Adapt detail level and terminology based on who will read the documentation. Use appendices for deep technical details that different audiences can reference as needed.

### 2. Consistent Notation
Establish and enforce naming conventions across all diagrams and documentation. Inconsistency leads to confusion and errors.

### 3. Traceability
Link data flows to requirements, use cases, and system components. This enables impact analysis when requirements change.

### 4. Living Documentation
Treat data flow docs as living artifacts that evolve with the system. Version control, review, and update regularly.

### 5. Multiple Representations
Use different diagram types for different purposes:
- Context diagrams for scope
- Container diagrams for architecture
- Sequence diagrams for behavior
- Entity diagrams for data models

## Common Mistakes

### Missing Error Flows
Documenting only happy paths creates incomplete understanding. Always include:
- What happens when services fail
- Retry and backoff strategies
- Circuit breaker behavior
- Dead letter handling

### Inconsistent Naming
Using different names for the same component across documents creates confusion. Maintain a glossary and enforce consistency.

### Over-Abstraction
Too high-level documentation lacks implementation guidance. Too detailed documentation becomes hard to maintain. Balance based on audience needs.

### Static Diagrams
Diagrams that can't be version-controlled become stale. Use "diagrams as code" approaches (Mermaid, PlantUML) that can be reviewed with code changes.

## Tools

### Diagrams as Code
- **Mermaid**: Markdown-based diagrams, GitHub-native
- **PlantUML**: Text-to-diagram, extensive notation
- **C4-PlantUML**: C4 model specifically

### Documentation Platforms
- **Confluence**: Enterprise wiki with diagrams
- **Notion**: Flexible workspace
- **GitHub Wiki**: Code-proximate documentation

### Visualization Tools
- **Draw.io**: Free, collaborative
- **Figma**: Design tool integration
- **Cloudcraft**: AWS architecture specifically

## Integration with Other Skills

### With Sherlock Debugging
When debugging data-related issues, the data flow documentation provides the map for tracing problems to their source.

### With Adversarial Thinking
Attack your data flow design by:
- Identifying single points of failure
- Finding security vulnerabilities in data paths
- Testing error handling assumptions

### With Trust but Verify
Validate that documented data flows match actual system behavior through:
- Tracing requests through the system
- Comparing documentation to implementation
- Identifying undocumented flows

## Validation Checklist

Before considering data flow documentation complete:

- [ ] All data sources identified and documented
- [ ] All data destinations identified and documented
- [ ] All protocols specified correctly
- [ ] Security boundaries marked
- [ ] Error handling documented
- [ ] Storage systems described
- [ ] Naming is consistent
- [ ] Diagrams match text descriptions
- [ ] Multiple audiences can understand
- [ ] Technical accuracy verified

## Conclusion

Good data flow documentation is essential for:
- Onboarding team members
- Debugging complex issues
- Planning system changes
- Ensuring security compliance
- Enabling architectural decisions

Invest the time to create accurate, maintainable data flow documentation and it will pay dividends throughout the system lifecycle.