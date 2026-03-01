# Skills Collection

A personal collection of AI agent skills following the [Agent Skills](https://agentskills.io) open standard.

## Installation

Install all skills using the [skills CLI](https://github.com/vercel-labs/skills):

```bash
npx skills add <your-username>/skills
```

Or install specific skills:

```bash
npx skills add <your-username>/skills --skill git-release
```

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd skills

# Setup symlinks for local development
npm run setup-symlinks

# Create a new skill
npm run create-skill -- my-new-skill "Description of my new skill"

# Validate all skills
npm run validate

# Install locally for testing
npx skills add . --skill my-new-skill
```

## Available Skills

### Core Skills

#### git-release
Create consistent releases and changelogs from merged PRs.

**Use when:** Preparing a tagged release, generating release notes, proposing version bumps.

#### react-review
Review React components for best practices and performance issues.

**Use when:** Reviewing React component code, optimizing performance, checking best practices.

#### vercel-deploy
Deploy applications to Vercel with automatic framework detection.

**Use when:** Deploying web applications, setting up hosting, testing deployment configuration.

#### skill-builder
Build basic to intermediate Agent Skills using structured templates and validation tools.

**Use when:** Creating simple to moderately complex skills, validating skill structure, analyzing requirements.

#### hypercognitive-skill-compiler
Transform complex skill requirements into complete Agent Skills using exhaustive hypercognitive compiler thinking patterns.

**Use when:** Building production-ready, complex skills with rigorous quality gates, error handling, and comprehensive validation.

#### index
Maintain directory organization with index files (_index.md/_index.yaml/_index.json) and consistency prompts (_prompt.md).

**Use when:** Setting up project structure, maintaining directory documentation, ensuring file consistency, reducing context switching.

#### opencode-config
Configure OpenCode settings using JSON or Markdown files for project-specific or global preferences.

**Use when:** Setting up OpenCode configuration, understanding precedence, creating custom modes/agents, verifying configuration details.

#### best-practice-guide
Analyze project documentation to identify missing context, then generate and store best practice guides using web search when available.

**Use when:** Starting work on new projects with incomplete documentation, identifying knowledge gaps, creating reusable best practice assets, preparing comprehensive project onboarding.

#### workflow-orchestrator
Build and orchestrate AI-driven development workflows (Ralph loops) that iterate until success using configurable patterns and multi-agent coordination.

**Use when:** Building complex features requiring multiple AI agent passes, implementing automated development workflows with verification steps, coordinating parallel AI agents for different aspects of a task, creating self-correcting loops that iterate until success criteria met.

#### dogfooding
Test and validate the skills repository using the skills system itself, practicing "eating your own dog food".

**Use when:** Validating that the skills repository actually works with the skills CLI, ensuring all skills follow Agent Skills specification, running automated validation of skill quality, demonstrating the power of the skills system by using it to test itself.

### Logging & Observability

#### logging-fundamentals
Implement proper logging practices including log levels, structured logging, context propagation, and logging best practices for applications and systems.

**Use when:** Setting up logging for new applications or services, reviewing existing logging implementations, establishing logging standards, debugging issues with incomplete or poor logging.

#### log-management-system
Implement comprehensive log management including rotation, retention, forwarding, aggregation, storage, and lifecycle management for scalable observability.

**Use when:** Designing log management infrastructure, implementing log rotation and retention policies, setting up log forwarding to centralized systems, planning log storage strategies.

#### log-analysis-parsing
Parse, analyze, search, and extract insights from logs using various techniques including regex, parsing engines, and log analysis tools.

**Use when:** Need to extract specific information from unstructured log files, building log parsing pipelines, searching through large volumes of logs for patterns or errors.

#### distributed-tracing-logs
Implement distributed tracing using logs, including trace context propagation, span logging, correlation IDs, and OpenTelemetry integration for observability.

**Use when:** Building or maintaining distributed systems (microservices, serverless), need to trace requests across multiple service boundaries, debugging issues spanning multiple components.

#### logging-performance-optimization
Optimize logging performance including overhead reduction, async logging, buffering, sampling, and performance impact analysis for high-throughput systems.

**Use when:** Logging overhead is impacting application performance, building high-throughput systems where logging cost matters, optimizing latency-sensitive applications.

#### observability-logging
Use logs as part of comprehensive observability strategy including metrics, traces, alerts, and dashboards for system understanding and operational excellence.

**Use when:** Building comprehensive observability platforms, integrating logs with metrics and tracing for full observability, designing alerting and monitoring systems based on log patterns.

### Development Tools

#### dependency-upgrade
Comprehensive dependency analysis with breaking change detection and impact analysis.

**Use when:** Analyzing dependency upgrades, detecting breaking changes, planning migration strategies, assessing upgrade impact.

#### code-migration
Framework/library migration with incremental strategies and automated tools.

**Use when:** Migrating between frameworks or libraries, planning incremental migrations, analyzing breaking changes, implementing migration tools.

### Performance Optimization

#### performance-profiling
Linux kernel-level (perf, eBPF, ftrace) and application-level profiling.

**Use when:** Profiling system performance, identifying bottlenecks, optimizing application performance, analyzing kernel-level performance issues.

### Security & Compliance

#### security-scan
Comprehensive security scanning across applications, infrastructure, and dependencies with LLM-based analysis.

**Use when:** Conducting security audits, scanning for vulnerabilities, mapping to compliance frameworks, implementing security controls.

### Documentation

#### api-documentation
Generate comprehensive API documentation for REST/HTTP, gRPC, GraphQL, and RPC APIs.

**Use when:** Documenting APIs, generating interactive documentation, ensuring consistency between implementation and documentation.

### Cloud Management

#### cloud-cost-optimization
Analyze and optimize cloud costs across multiple cloud providers (AWS, Azure, GCP).

**Use when:** Analyzing cloud spending, identifying cost savings opportunities, optimizing resource utilization, implementing FinOps practices.

### Data Management

#### data-validation
Validate data quality, types, schemas, and consistency across systems.

**Use when:** Ensuring data quality, validating data schemas, detecting data anomalies, implementing data validation rules.

### Database Optimization

#### database-optimization
Optimize database performance, schema design, indexing, and query performance across different database systems.

**Use when:** Optimizing database performance, analyzing query performance, tuning database configuration, optimizing indexes.

### Operations

#### accessibility-audit
Comprehensive accessibility auditing including WCAG compliance, legal requirements mapping, and user testing with disabilities.

**Use when:** Conducting accessibility audits, ensuring WCAG compliance, mapping to legal requirements, testing with assistive technologies.

#### incident-response
Manage incidents and conduct post-mortem analysis to improve system reliability and security.

**Use when:** Managing incidents, conducting post-mortem analysis, improving incident response processes, tracking incident metrics.

### Testing Ecosystem

#### Basic Test Types
- **testing-unit**: Run unit tests for individual code components
- **testing-integration**: Run integration tests for component interactions
- **testing-e2e**: Run end-to-end tests for complete user workflows
- **testing-api**: Test API endpoints and contracts
- **testing-performance**: Test application performance and load handling
- **testing-security**: Test application security vulnerabilities
- **testing-accessibility**: Test application accessibility compliance

#### Specialized Test Types
- **testing-regression**: Run regression tests to ensure new changes don't break existing functionality
- **testing-smoke**: Run smoke tests to verify basic application functionality
- **testing-compatibility**: Test application compatibility across browsers, devices, and platforms
- **testing-usability**: Test application usability and user experience
- **testing-database**: Test database interactions, schemas, and data integrity
- **testing-chaos**: Run chaos engineering tests to build resilient systems

#### Test Coordination & Management
- **test-orchestrator**: Orchestrate and coordinate different test types in proper order
- **test-dependency-mapper**: Map dependencies and relationships between different test types
- **test-planning**: Create comprehensive test plans considering all test types and dependencies
- **test-coverage**: Measure and report test coverage across all test types
- **testing-ecosystem**: Understand the complete testing ecosystem and relationships between test types

#### Testing Level Strategies
- **testing-level-poc**: Testing strategy for Proof of Concept projects
- **testing-level-mvp**: Testing strategy for Minimum Viable Product
- **testing-level-production**: Testing strategy for production deployment
- **testing-level-selector**: Select appropriate testing level based on project stage

#### Test Suites
- **testing-functional-suite**: Run comprehensive functional test suite
- **testing-nonfunctional-suite**: Run comprehensive non-functional test suite

#### Gap Analysis
- **gap-analysis**: Identify discrepancies between documentation and implementation through systematic analysis
- **spec-gap-analysis**: Analyze gaps between specifications (OpenAPI, Protobuf, GraphQL) and actual implementation
- **test-gap-analysis**: Analyze gaps between requirements/features that should be tested and actual test coverage

#### Skeptical Verification
- **trust-but-verify**: Verify system claims and test results through independent validation rather than trusting assumptions
- **assumption-testing**: Identify, document, and explicitly test assumptions rather than leaving them implicit and untested
- **reality-validation**: Compare system behavior against real-world expectations and domain knowledge rather than just technical specifications

#### Adversarial Thinking
- **devils-advocate**: Challenge ideas, assumptions, and decisions by playing devil's advocate to identify weaknesses and prevent groupthink
- **assumption-buster**: Aggressively challenge and attempt to disprove assumptions through counterexamples, edge cases, and adversarial thinking
- **redteam**: Think and act like an attacker to identify security vulnerabilities, weaknesses, and penetration vectors through adversarial security testing
- **white-hat**: Build defensive security capabilities, implement security by design, and practice ethical hacking to protect systems proactively
- **adversarial-thinking**: Apply systematic adversarial thinking patterns including devil's advocate, assumption busting, red teaming, and white hat security approaches

## Skill Reference

| Skill | Description | Directory | Documentation |
|-------|------------|-----------|---------------|
| git-release | Create consistent releases and changelogs | [skills/git-release/](./skills/git-release/) | [references/README.md](./skills/git-release/references/README.md) |
| react-review | Review React components for best practices | [skills/react-review/](./skills/react-review/) | [references/README.md](./skills/react-review/references/README.md) |
| vercel-deploy | Deploy applications to Vercel | [skills/vercel-deploy/](./skills/vercel-deploy/) | [references/README.md](./skills/vercel-deploy/references/README.md) |
| skill-builder | Build basic to intermediate Agent Skills | [skills/skill-builder/](./skills/skill-builder/) | [references/README.md](./skills/skill-builder/references/README.md) |
| hypercognitive-skill-compiler | Transform complex skill requirements | [skills/hypercognitive-skill-compiler/](./skills/hypercognitive-skill-compiler/) | [references/README.md](./skills/hypercognitive-skill-compiler/references/README.md) |
| index | Maintain directory organization with index files | [skills/index/](./skills/index/) | [references/README.md](./skills/index/references/README.md) |
| testing-unit | Run unit tests for individual components | [skills/testing-unit/](./skills/testing-unit/) | [references/README.md](./skills/testing-unit/references/README.md) |
| testing-integration | Run integration tests | [skills/testing-integration/](./skills/testing-integration/) | [references/README.md](./skills/testing-integration/references/README.md) |
| testing-e2e | Run end-to-end tests | [skills/testing-e2e/](./skills/testing-e2e/) | [references/README.md](./skills/testing-e2e/references/README.md) |
| testing-api | Test API endpoints and contracts | [skills/testing-api/](./skills/testing-api/) | [references/README.md](./skills/testing-api/references/README.md) |
| testing-performance | Test application performance | [skills/testing-performance/](./skills/testing-performance/) | [references/README.md](./skills/testing-performance/references/README.md) |
| testing-security | Test security vulnerabilities | [skills/testing-security/](./skills/testing-security/) | [references/README.md](./skills/testing-security/references/README.md) |
| testing-accessibility | Test accessibility compliance | [skills/testing-accessibility/](./skills/testing-accessibility/) | [references/README.md](./skills/testing-accessibility/references/README.md) |
| testing-regression | Run regression tests | [skills/testing-regression/](./skills/testing-regression/) | [references/README.md](./skills/testing-regression/references/README.md) |
| testing-smoke | Run smoke tests | [skills/testing-smoke/](./skills/testing-smoke/) | [references/README.md](./skills/testing-smoke/references/README.md) |
| testing-compatibility | Test compatibility across platforms | [skills/testing-compatibility/](./skills/testing-compatibility/) | [references/README.md](./skills/testing-compatibility/references/README.md) |
| testing-usability | Test usability and UX | [skills/testing-usability/](./skills/testing-usability/) | [references/README.md](./skills/testing-usability/references/README.md) |
| testing-database | Test database interactions | [skills/testing-database/](./skills/testing-database/) | [references/README.md](./skills/testing-database/references/README.md) |
| testing-chaos | Run chaos engineering tests | [skills/testing-chaos/](./skills/testing-chaos/) | [references/README.md](./skills/testing-chaos/references/README.md) |
| test-orchestrator | Orchestrate test execution | [skills/test-orchestrator/](./skills/test-orchestrator/) | [references/README.md](./skills/test-orchestrator/references/README.md) |
| test-dependency-mapper | Map test dependencies | [skills/test-dependency-mapper/](./skills/test-dependency-mapper/) | [references/README.md](./skills/test-dependency-mapper/references/README.md) |
| test-planning | Create comprehensive test plans | [skills/test-planning/](./skills/test-planning/) | [references/README.md](./skills/test-planning/references/README.md) |
| test-coverage | Measure test coverage | [skills/test-coverage/](./skills/test-coverage/) | [references/README.md](./skills/test-coverage/references/README.md) |
| testing-ecosystem | Understand testing ecosystem | [skills/testing-ecosystem/](./skills/testing-ecosystem/) | [references/README.md](./skills/testing-ecosystem/references/README.md) |
| testing-level-poc | Testing for Proof of Concept | [skills/testing-level-poc/](./skills/testing-level-poc/) | [references/README.md](./skills/testing-level-poc/references/README.md) |
| testing-level-mvp | Testing for Minimum Viable Product | [skills/testing-level-mvp/](./skills/testing-level-mvp/) | [references/README.md](./skills/testing-level-mvp/references/README.md) |
| testing-level-production | Testing for production deployment | [skills/testing-level-production/](./skills/testing-level-production/) | [references/README.md](./skills/testing-level-production/references/README.md) |
| testing-level-selector | Select testing level based on project | [skills/testing-level-selector/](./skills/testing-level-selector/) | [references/README.md](./skills/testing-level-selector/references/README.md) |
| testing-functional-suite | Run functional test suite | [skills/testing-functional-suite/](./skills/testing-functional-suite/) | [references/README.md](./skills/testing-functional-suite/references/README.md) |
| testing-nonfunctional-suite | Run non-functional test suite | [skills/testing-nonfunctional-suite/](./skills/testing-nonfunctional-suite/) | [references/README.md](./skills/testing-nonfunctional-suite/references/README.md) |
| gap-analysis | Identify discrepancies between documentation and implementation | [skills/gap-analysis/](./skills/gap-analysis/) | [references/README.md](./skills/gap-analysis/references/README.md) |
| spec-gap-analysis | Analyze gaps between specifications and actual implementation | [skills/spec-gap-analysis/](./skills/spec-gap-analysis/) | [references/README.md](./skills/spec-gap-analysis/references/README.md) |
| test-gap-analysis | Analyze gaps between requirements/features and actual test coverage | [skills/test-gap-analysis/](./skills/test-gap-analysis/) | [references/README.md](./skills/test-gap-analysis/references/README.md) |
| trust-but-verify | Verify claims skeptically | [skills/trust-but-verify/](./skills/trust-but-verify/) | [references/README.md](./skills/trust-but-verify/references/README.md) |
| assumption-testing | Test implicit assumptions | [skills/assumption-testing/](./skills/assumption-testing/) | [references/README.md](./skills/assumption-testing/references/README.md) |
| reality-validation | Validate against real-world | [skills/reality-validation/](./skills/reality-validation/) | [references/README.md](./skills/reality-validation/references/README.md) |
| opencode-config | Configure OpenCode settings | [skills/opencode-config/](./skills/opencode-config/) | [references/README.md](./skills/opencode-config/references/README.md) |
| best-practice-guide | Analyze project docs to identify gaps and generate best practice guides | [skills/best-practice-guide/](./skills/best-practice-guide/) | [references/README.md](./skills/best-practice-guide/references/README.md) |
| devils-advocate | Challenge ideas as devil's advocate | [skills/devils-advocate/](./skills/devils-advocate/) | [references/README.md](./skills/devils-advocate/references/README.md) |
| assumption-buster | Aggressively disprove assumptions | [skills/assumption-buster/](./skills/assumption-buster/) | [references/README.md](./skills/assumption-buster/references/README.md) |
| redteam | Think like attacker for security testing | [skills/redteam/](./skills/redteam/) | [references/README.md](./skills/redteam/references/README.md) |
| white-hat | Build defensive security capabilities | [skills/white-hat/](./skills/white-hat/) | [references/README.md](./skills/white-hat/references/README.md) |
| adversarial-thinking | Apply systematic adversarial thinking | [skills/adversarial-thinking/](./skills/adversarial-thinking/) | [references/README.md](./skills/adversarial-thinking/references/README.md) |
| dependency-upgrade | Comprehensive dependency analysis with breaking change detection and impact analysis | [skills/dependency-upgrade/](./skills/dependency-upgrade/) | [references/README.md](./skills/dependency-upgrade/references/README.md) |
| performance-profiling | Linux kernel-level (perf, eBPF, ftrace) and application-level profiling | [skills/performance-profiling/](./skills/performance-profiling/) | [references/README.md](./skills/performance-profiling/references/README.md) |
| code-migration | Framework/library migration with incremental strategies and automated tools | [skills/code-migration/](./skills/code-migration/) | [references/README.md](./skills/code-migration/references/README.md) |
| security-scan | Comprehensive security scanning across applications, infrastructure, and dependencies with LLM-based analysis | [skills/security-scan/](./skills/security-scan/) | [references/README.md](./skills/security-scan/references/README.md) |
| api-documentation | Generate comprehensive API documentation for REST/HTTP, gRPC, GraphQL, and RPC APIs | [skills/api-documentation/](./skills/api-documentation/) | [references/README.md](./skills/api-documentation/references/README.md) |
| cloud-cost-optimization | Analyze and optimize cloud costs across multiple cloud providers (AWS, Azure, GCP) | [skills/cloud-cost-optimization/](./skills/cloud-cost-optimization/) | [references/README.md](./skills/cloud-cost-optimization/references/README.md) |
| data-validation | Validate data quality, types, schemas, and consistency across systems | [skills/data-validation/](./skills/data-validation/) | [references/README.md](./skills/data-validation/references/README.md) |
| accessibility-audit | Comprehensive accessibility auditing including WCAG compliance, legal requirements mapping, and user testing with disabilities | [skills/accessibility-audit/](./skills/accessibility-audit/) | [references/README.md](./skills/accessibility-audit/references/README.md) |
| database-optimization | Optimize database performance, schema design, indexing, and query performance across different database systems | [skills/database-optimization/](./skills/database-optimization/) | [references/README.md](./skills/database-optimization/references/README.md) |
| incident-response | Manage incidents and conduct post-mortem analysis to improve system reliability and security | [skills/incident-response/](./skills/incident-response/) | [references/README.md](./skills/incident-response/references/README.md) |
| dogfooding | Test and validate the skills repository using the skills system itself, practicing "eating your own dog food" | [skills/dogfooding/](./skills/dogfooding/) | [references/README.md](./skills/dogfooding/references/README.md) |

## Local Development

This repository includes a `.opencode/skills/` directory with symlinks to the main `skills/` directory. This allows OpenCode to discover skills locally while keeping the canonical source in the `skills/` folder.

Each skill includes comprehensive documentation:
- **SKILL.md**: Primary skill definition with usage instructions, examples, and output format
- **references/README.md**: Detailed reference documentation, implementation notes, and additional context
- **scripts/**: Optional executable scripts for skill functionality

To add a new skill:

1. Create a directory in `skills/<skill-name>/`
2. Add a `SKILL.md` file with proper frontmatter
3. Add skill documentation in `references/README.md`
4. Create a symlink in `.opencode/skills/`:

```bash
ln -s ../../skills/<skill-name> .opencode/skills/<skill-name>
```

## Development

### Scripts

The repository includes several helper scripts:

- `npm run setup-symlinks` - Create symlinks in `.opencode/skills/`
- `npm run validate` - Validate all skills
- `npm run validate-skill` - Validate a specific skill
- `npm run create-skill` - Create a new skill from template

### Creating Skills

See [TEMPLATE.md](./TEMPLATE.md) for a complete skill template and best practices.

For quick creation:

```bash
npm run create-skill -- my-new-skill "Description of my new skill" [category]
```

Categories: development, deployment, productivity, testing, documentation, security

### Testing

Test skills locally:

```bash
# Validate skill structure
npm run validate

# Test with skills CLI
npx skills add . --skill <skill-name> --list

# Install to OpenCode locally
npm run setup-symlinks
```

## Skill Structure

Each skill follows the standard Agent Skills format:

```
skills/
  <skill-name>/
    SKILL.md          # Required: skill definition with YAML frontmatter
    scripts/          # Optional: executable scripts
    references/       # Optional: supporting documentation
```

### SKILL.md Requirements

- Must start with YAML frontmatter containing `name` and `description`
- `name` must be lowercase alphanumeric with hyphens (1-64 chars)
- `description` must be 1-1024 characters
- Follows the [Agent Skills specification](https://agentskills.io/specification)

## Compatibility

Skills are compatible with any agent that supports the Agent Skills standard, including:

- OpenCode
- Claude Code
- Cursor
- Codex
- Antigravity
- And [37+ more agents](https://github.com/vercel-labs/skills#supported-agents)

## License

MIT