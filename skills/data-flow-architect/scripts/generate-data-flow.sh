#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO" >&2; exit 1' ERR

echo "Data Flow Documentation Generator"
echo "================================"
echo ""

cleanup() {
    if [ -n "${OUTPUT_DIR:-}" ] && [ -d "$OUTPUT_DIR" ]; then
        rm -f "$OUTPUT_DIR"/*.tmp 2>/dev/null || true
    fi
}

sanitize_path() {
    local path="$1"
    # Allow relative paths without traversal
    if [[ "$path" =~ \.\./ ]]; then
        echo "Error: Path traversal not allowed: $path" >&2
        exit 1
    fi
    # Allow absolute paths but warn (for /tmp, standard paths)
    if [[ "$path" =~ ^/ ]]; then
        # Only allow known-safe absolute paths
        if [[ "$path" =~ ^/tmp/|^/var/folders/ ]]; then
            echo "$path"
        else
            echo "Error: Absolute paths not allowed (except /tmp): $path" >&2
            exit 1
        fi
    else
        echo "$path"
    fi
}

sanitize_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_\ -]*$ ]]; then
        echo "Error: System name contains invalid characters. Use only letters, numbers, hyphens, underscores, and spaces." >&2
        exit 1
    fi
    echo "$name"
}

SYSTEM_NAME=""
OUTPUT_DIR="./docs/data-flows"
FORMAT="markdown"

while [[ $# -gt 0 ]]; do
    case $1 in
        --system)
            SYSTEM_NAME="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: generate-data-flow.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --system NAME      System name for documentation"
            echo "  --output-dir DIR   Output directory"
            echo "  --format FORMAT   Output format (markdown, mermaid, both)"
            echo ""
            echo "Example:"
            echo '  ./generate-data-flow.sh --system "order-service" --output-dir "./docs"'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$SYSTEM_NAME" ]; then
    echo "Error: --system is required"
    exit 1
fi

SYSTEM_NAME=$(sanitize_name "$SYSTEM_NAME")
OUTPUT_DIR=$(sanitize_path "$OUTPUT_DIR")

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

mkdir -p "$OUTPUT_DIR"

echo "Generating data flow documentation for: $SYSTEM_NAME"
echo "Output directory: $OUTPUT_DIR"
echo "Format: $FORMAT"
echo ""

# Create main documentation with quoted EOF to prevent injection
cat > "$OUTPUT_DIR/data-flow-architecture.md" << 'MDEOF'
# Data Flow Architecture: SYSTEM_NAME

**Generated**: TIMESTAMP_PLACEHOLDER
**System**: SYSTEM_NAME_PLACEHOLDER

---

## Executive Summary

[Brief description of data architecture and business value]

## System Context

### External Entities
| Entity | Type | Description |

### Trust Boundaries
| Boundary | From | To | Security Controls |

## Data Sources

| Source | Type | Format | Frequency | Volume | Schema |

## Data Destinations

| Destination | Type | Format | Consumer |

## Data Flows

### [Flow Name]

**Purpose**: [What this flow accomplishes]
**Source**: [Origin entity]
**Destination**: [Final destination]
**Criticality**: [High/Medium/Low]

#### Path

| Step | From | To | Protocol | Format | Security |

#### Data Transformation

| Stage | Input | Transformation | Output |

#### Error Handling

| Error Condition | Handling Strategy | Retry Policy |

### [Additional flows...]

## Storage Architecture

| Store | Type | Purpose | Schema | Retention |

## Network Architecture

| Zone | Components | Security Controls |

## Protocol Specifications

### HTTP/REST
- Methods: GET, POST, PUT, DELETE
- Authentication: Bearer Token / API Key
- Rate Limiting: [Details]

### gRPC
- Services: [List]
- Authentication: [Method]
- Protobuf Version: [Version]

### Message Queue
- Broker: [Type]
- Topics/Queues: [List]
- Delivery Guarantees: [At-least-once / Exactly-once]

## Security

### Authentication
| Service | Method |

### Authorization
| Resource | Permission |

### Encryption
- In Transit: TLS 1.3
- At Rest: AES-256

### Data Classification
| Data Type | Classification | Handling Requirements |

## Appendix

### Glossary
| Term | Definition |

### Revision History
| Date | Change | Author |
MDEOF

# Replace placeholders safely
sed -i.bak "s/SYSTEM_NAME_PLACEHOLDER/$SYSTEM_NAME/g" "$OUTPUT_DIR/data-flow-architecture.md"
sed -i.bak "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" "$OUTPUT_DIR/data-flow-architecture.md"
rm -f "$OUTPUT_DIR/data-flow-architecture.md.bak"

echo "✓ Created: $OUTPUT_DIR/data-flow-architecture.md"

# Create Mermaid diagram template
if [ "$FORMAT" = "mermaid" ] || [ "$FORMAT" = "both" ]; then
    cat > "$OUTPUT_DIR/data-flow-diagram.mmd" << 'MERMAIDEOF'
%% Data Flow Diagram: SYSTEM_NAME_PLACEHOLDER
%% Generated: TIMESTAMP_PLACEHOLDER

graph TD
    subgraph External["External Entities"]
        User[User]
        ExternalAPI[External API]
    end

    subgraph Gateway["API Gateway"]
        APIGateway[API Gateway]
        RateLimiter[Rate Limiter]
    end

    subgraph Services["Microservices"]
        AuthService[Auth Service]
        BusinessService[Business Service]
        NotificationService[Notification Service]
    end

    subgraph Storage["Data Layer"]
        UserDB[(User DB)]
        BusinessDB[(Business DB)]
        Cache[(Cache)]
        MessageQueue[Message Queue]
    end

    User -->|HTTPS| APIGateway
    ExternalAPI -->|Webhook| APIGateway
    
    APIGateway -->|mTLS| RateLimiter
    RateLimiter -->|gRPC| AuthService
    RateLimiter -->|gRPC| BusinessService
    
    AuthService -->|SQL| UserDB
    AuthService -->|SET| Cache
    BusinessService -->|SQL| BusinessDB
    BusinessService -->|PUBLISH| MessageQueue
    
    MessageQueue -->|CONSUME| NotificationService
    NotificationService -->|SMTP/API| User

    classDef external fill:#f9f,stroke:#333,stroke-width:2px
    classDef gateway fill:#bbf,stroke:#333,stroke-width:2px
    classDef service fill:#dfd,stroke:#333,stroke-width:2px
    classDef storage fill:#ffd,stroke:#333,stroke-width:2px
    
    class User,ExternalAPI external
    class APIGateway,RateLimiter gateway
    class AuthService,BusinessService,NotificationService service
    class UserDB,BusinessDB,Cache,MessageQueue storage
MERMAIDEOF

    sed -i.bak "s/SYSTEM_NAME_PLACEHOLDER/$SYSTEM_NAME/g" "$OUTPUT_DIR/data-flow-diagram.mmd"
    sed -i.bak "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" "$OUTPUT_DIR/data-flow-diagram.mmd"
    rm -f "$OUTPUT_DIR/data-flow-diagram.mmd.bak"

    echo "✓ Created: $OUTPUT_DIR/data-flow-diagram.mmd"
fi

# Create container-level template
cat > "$OUTPUT_DIR/container-level.md" << 'CNTEOF'
# Container Level Data Flow: SYSTEM_NAME_PLACEHOLDER

**Level**: Container Diagram (L1)
**Generated**: TIMESTAMP_PLACEHOLDER

## Container Overview

| Container | Technology | Responsibility | External Dependencies |

## Container Interactions

| From | To | Protocol | Data Format | Authentication |

## Data Transformation Per Container

### [Container Name]
| Input | Transformation | Output |

## Error Handling Between Containers

| From | To | Failure Mode | Handling |

## Sequence Diagrams

### [Critical Path Name]
```mermaid
sequenceDiagram
    participant Client
    participant Gateway
    participant Service
    participant DB
    
    Client->>Gateway: Request
    Gateway->>Service: Forward
    Service->>DB: Query
    DB-->>Service: Result
    Service-->>Gateway: Response
    Gateway-->>Client: HTTP Response
```
CNTEOF

sed -i.bak "s/SYSTEM_NAME_PLACEHOLDER/$SYSTEM_NAME/g" "$OUTPUT_DIR/container-level.md"
sed -i.bak "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" "$OUTPUT_DIR/container-level.md"
rm -f "$OUTPUT_DIR/container-level.md.bak"

echo "✓ Created: $OUTPUT_DIR/container-level.md"

# Create validation checklist
cat > "$OUTPUT_DIR/validation-checklist.md" << 'VALEOF'
# Data Flow Documentation Validation Checklist

**System**: SYSTEM_NAME_PLACEHOLDER
**Date**: TIMESTAMP_PLACEHOLDER

## Completeness Check

- [ ] All data sources documented
- [ ] All data destinations documented
- [ ] All data flows mapped with paths
- [ ] All protocols specified
- [ ] All storage systems documented
- [ ] All security boundaries marked

## Consistency Check

- [ ] Component names consistent across diagrams
- [ ] Arrow meanings consistent (sync vs async)
- [ ] Protocol specifications match
- [ ] Security annotations consistent

## Clarity Check

- [ ] Non-technical stakeholders can understand conceptual view
- [ ] Developers can implement from logical view
- [ ] Operators can deploy from physical view
- [ ] Diagrams are labeled clearly

## Accuracy Check

- [ ] Data formats match actual system
- [ ] Protocols are current (not deprecated)
- [ ] Storage schemas are up to date
- [ ] Security controls reflect actual implementation

## Edge Cases Verified

- [ ] Error handling documented for each flow
- [ ] Retry logic specified
- [ ] Circuit breakers documented
- [ ] Dead letter queues defined

## Review Sign-off

- [ ] Architecture Review: _________ Date: _______
- [ ] Security Review: _________ Date: _______
- [ ] Engineering Review: _________ Date: _______
VALEOF

sed -i.bak "s/SYSTEM_NAME_PLACEHOLDER/$SYSTEM_NAME/g" "$OUTPUT_DIR/validation-checklist.md"
sed -i.bak "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" "$OUTPUT_DIR/validation-checklist.md"
rm -f "$OUTPUT_DIR/validation-checklist.md.bak"

echo "✓ Created: $OUTPUT_DIR/validation-checklist.md"

# Create compliance template (addressing Sherlock's GDPR concern)
cat > "$OUTPUT_DIR/compliance-data-flows.md" << 'COMPEOF'
# Compliance and Data Privacy: SYSTEM_NAME_PLACEHOLDER

**Generated**: TIMESTAMP_PLACEHOLDER

## Data Classification

| Data Type | Classification | Examples | Handling Requirements |

## PII Data Flows

### Data Subject Access Request Flow
1. Request received from data subject
2. Identity verified
3. All instances of PII located across systems
4. Data aggregated and formatted
5. Response delivered securely
6. Audit trail maintained

### Right to be Forgotten Flow
1. Deletion request received
2. Identity verified
3. All PII located across all data stores
4. Cascade deletions executed
5. Anonymization where deletion not possible
6. Confirmation sent
7. Third-party notifications (if data was shared)
8. Audit trail maintained

## Data Retention

| Data Type | Retention Period | Storage Location | Disposal Method |

## Geographic Data Flows

| Data Type | Source Region | Processing Region | Storage Regions | Transfer Mechanism |

## Audit Logging

| Event Type | Logged | Retention | Access Control |
|-----------|--------|-----------|----------------|
| Data Access | | | |
| Data Modification | | | |
| Data Deletion | | | |
| Security Events | | | |

## Security Controls at Data Boundaries

| Boundary | From Zone | To Zone | Security Controls |
|----------|-----------|---------|-------------------|
COMPEOF

sed -i.bak "s/SYSTEM_NAME_PLACEHOLDER/$SYSTEM_NAME/g" "$OUTPUT_DIR/compliance-data-flows.md"
sed -i.bak "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" "$OUTPUT_DIR/compliance-data-flows.md"
rm -f "$OUTPUT_DIR/compliance-data-flows.md.bak"

echo "✓ Created: $OUTPUT_DIR/compliance-data-flows.md"

echo ""
echo "✅ Data flow documentation generated successfully!"
echo ""
echo "Files created:"
echo "  • $OUTPUT_DIR/data-flow-architecture.md"
if [ "$FORMAT" = "mermaid" ] || [ "$FORMAT" = "both" ]; then
    echo "  • $OUTPUT_DIR/data-flow-diagram.mmd"
fi
echo "  • $OUTPUT_DIR/container-level.md"
echo "  • $OUTPUT_DIR/validation-checklist.md"
echo "  • $OUTPUT_DIR/compliance-data-flows.md"
echo ""
echo "Next steps:"
echo "1. Fill in the template sections with actual system details"
echo "2. Generate Mermaid diagrams using https://mermaid.live/"
echo "3. Have stakeholders review for accuracy"
echo "4. Validate consistency across all documentation"
echo "5. Review compliance section for GDPR/HIPAA requirements"