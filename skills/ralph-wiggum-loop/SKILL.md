---
name: ralph-wiggum-loop
description: Build customizable Ralph loops - AI-driven development workflows that iterate until success
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: workflow
---

# Ralph Wiggum Skill

A meta-skill for building Ralph loops - customizable AI-driven development workflows that leverage OpenCode's HTTP server and SSE streaming.

## Overview

This skill enables users to create and execute Ralph loops through:
- Configurable workflow patterns (YAML-based)
- Multi-agent composition (sequential, parallel, or hybrid)
- OpenCode server integration (opencode serve with /docs API)
- Stop hook patterns and completion promises
- Custom agent orchestration

## Quick Start

1. Load this skill in your OpenCode project
2. Run the workflow builder agent to configure your loop
3. Choose from patterns or create custom workflows
4. The skill generates the necessary agents, tools, and configs

## Architecture

### Skill Components
- **agents/**: Ready-to-use agent configurations
- **tools/**: Server integration and workflow orchestration
- **generators/**: YAML-to-config and loop builder utilities

### Resources
- **specs/**: OpenCode server API, streaming patterns, workflow composition
- **patterns/**: Pre-configured YAML workflow templates
- **examples/**: Real-world usage scenarios
- **templates/**: Schema definitions and config templates

## Workflow Options

### Built-in Patterns
- `builder-only`: Simple build until success
- `build-verify`: Build → Verify → Retry loop
- `build-verify-plan`: Build → Verify → Plan → Retry
- `multi-agent-pipeline`: Parallel agent execution with merging
- `custom`: User-defined YAML workflow

### Agent Types
- **Primary**: Main conversational agents (Build, Plan)
- **Subagent**: Specialized helpers (General, Explore, Verify, Merge)
- **Custom**: User-defined roles

### Execution Modes
- **Sequential**: One agent at a time
- **Parallel**: Multiple agents run simultaneously
- **Hybrid**: Mix of sequential and parallel
- **Conditional**: Branch based on conditions

## Configuration

Edit `ralph-wiggum.yaml` to customize:
- Workflow patterns
- Agent permissions
- Stop conditions
- Iteration limits
- Server settings

## Usage

```bash
# Start the workflow builder
@workflow-builder

# Questions help define:
# - What type of loop?
# - Success conditions?
# - Max iterations?
# - Parallel or sequential?
# - Which agents involved?
```

## Safety

Always configure:
- Max iterations (escape hatches)
- Sandbox environment
- Permission controls
- Stop hook verification
