#!/bin/bash
set -e

# Ralph Loop Generator - Enterprise Edition
# Creates a working Ralph loop with plugin system, orchestration, and monitoring

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Parse arguments
TEMPLATE="basic"
WITH_PLUGINS=false
WITH_DASHBOARD=false
WITH_TESTS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --with-plugins)
            WITH_PLUGINS=true
            shift
            ;;
        --with-dashboard)
            WITH_DASHBOARD=true
            shift
            ;;
        --with-tests)
            WITH_TESTS=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            OUTPUT_DIR="$1"
            shift
            ;;
    esac
done

OUTPUT_DIR="${OUTPUT_DIR:-./ralph-loop}"

show_help() {
    cat <<'EOF'
Ralph Loop Generator - Enterprise Edition

Usage: bash generate-ralph-loop.sh [options] [output-directory]

Options:
  --template <name>       Workflow template: basic, advanced, dag, saga
  --with-plugins          Include example plugin directory
  --with-dashboard        Include monitoring dashboard config
  --with-tests            Include test suite for the loop
  --help                  Show this help

Templates:
  basic     - Simple build-verify loop (default)
  advanced  - Full workflow engine with plugins
  dag       - Directed Acyclic Graph workflow
  saga      - Distributed transactions with compensation

Examples:
  bash generate-ralph-loop.sh ./my-loop
  bash generate-ralph-loop.sh --template dag ./data-pipeline
  bash generate-ralph-loop.sh --with-plugins --with-dashboard ./enterprise-loop
EOF
}

echo "Ralph Loop Generator - Enterprise Edition" >&2
echo "========================================" >&2
echo "Template: $TEMPLATE" >&2

if [ -d "$OUTPUT_DIR" ]; then
    echo "Error: Directory '$OUTPUT_DIR' already exists" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/workflows"
mkdir -p "$OUTPUT_DIR/.ralph/logs"
mkdir -p "$OUTPUT_DIR/.ralph/snapshots"
mkdir -p "$OUTPUT_DIR/.ralph/cache"

# Copy the working example
cp "$SCRIPT_DIR/ralph-loop-example.py" "$OUTPUT_DIR/ralph-loop.py"

# Copy specialized agent prompts
cp "$SKILL_DIR/PROMPT-BUILDER.md" "$OUTPUT_DIR/PROMPT-BUILDER.md"
cp "$SKILL_DIR/PROMPT-VERIFIER.md" "$OUTPUT_DIR/PROMPT-VERIFIER.md"
cp "$SKILL_DIR/PROMPT-PLANNER.md" "$OUTPUT_DIR/PROMPT-PLANNER.md"

# Create enhanced requirements.txt
cat > "$OUTPUT_DIR/requirements.txt" <<'REQ'
# Core dependencies
pyyaml>=6.0
pydantic>=2.0
structlog>=23.0

# Plugin system
pluggy>=1.0

# Monitoring
opentelemetry-api>=1.20
opentelemetry-sdk>=1.20
opentelemetry-exporter-prometheus>=0.41
opentelemetry-exporter-jaeger>=1.20

# Circuit breaker
pybreaker>=1.0

# DAG execution
networkx>=3.0

# Configuration
python-dotenv>=1.0
jsonschema>=4.0
REQ

# Create enterprise ralph.yaml
cat > "$OUTPUT_DIR/ralph.yaml" <<'CONFIG'
# Ralph Loop - Enterprise Configuration
project:
  name: "My Project"
  description: "AI-driven development workflow"

# Core loop settings
loop:
  max_iterations: 100
  auto_commit: true
  parallel_agents: false

# Agent timeouts
timeouts:
  builder: 7200s      # 2 hours
  verifier: 3600s     # 1 hour
  planner: 1800s      # 30 minutes

# Retry configuration
retry:
  default:
    strategy: exponential_backoff
    max_attempts: 3
    base_delay: 5s
    max_delay: 300s
    jitter: 0.1
  
  transient_errors:
    strategy: linear
    max_attempts: 5
    delay: 10s
    retry_on:
      - TimeoutError
      - ConnectionError

# Circuit breaker
circuit_breaker:
  enabled: true
  failure_threshold: 5
  timeout: 300s
  half_open_max_calls: 3

# Plugin system (empty by default, add your plugins)
plugins:
  directory: ./plugins
  auto_discover: false

# Observability
observability:
  provider: opentelemetry
  
  traces:
    enabled: true
    sampling_rate: 1.0
  
  metrics:
    enabled: true
    port: 9090
  
  logs:
    level: INFO
    format: json
    file: .ralph/logs/ralph.log

# State management
state:
  persistence:
    type: file
    path: .ralph/loop-state.yaml
  
  snapshots:
    enabled: true
    interval: 60s
CONFIG

# Create workflow template based on selection
case "$TEMPLATE" in
    basic)
        cat > "$OUTPUT_DIR/workflows/default.yaml" <<'WORKFLOW'
workflow:
  type: state_machine
  
  states:
    - building
    - verifying
    - complete
  
  transitions:
    - from: building
      to: verifying
      condition: build_success
      else: building
    
    - from: verifying
      to: complete
      condition: verified
      else: building
WORKFLOW
        ;;
    
    advanced)
        cat > "$OUTPUT_DIR/workflows/default.yaml" <<'WORKFLOW'
workflow:
  type: state_machine
  
  states:
    - planning
    - building
    - verifying
    - complete
  
  transitions:
    - from: planning
      to: building
      condition: plan_complete
    
    - from: building
      to: verifying
      condition: build_success
      else: planning
    
    - from: verifying
      to: complete
      condition: verified
      else: planning
WORKFLOW
        
        cat > "$OUTPUT_DIR/workflows/ci.yaml" <<'WORKFLOW'
workflow:
  type: dag
  
  nodes:
    - id: lint
      agent: builder
      args:
        task: "Run linting"
    
    - id: test
      agent: verifier
      depends_on: [lint]
    
    - id: build
      agent: builder
      depends_on: [test]
    
    - id: verify
      agent: verifier
      depends_on: [build]
WORKFLOW
        ;;
    
    dag)
        cat > "$OUTPUT_DIR/workflows/default.yaml" <<'WORKFLOW'
workflow:
  type: dag
  
  nodes:
    - id: lint
      agent: builder
      args:
        task: "Run linter"
    
    - id: unit_test
      agent: verifier
      depends_on: [lint]
    
    - id: integration_test
      agent: verifier
      depends_on: [lint]
    
    - id: security_scan
      agent: verifier
      depends_on: [lint]
    
    - id: build
      agent: builder
      depends_on: [unit_test, integration_test, security_scan]
    
    - id: verify
      agent: verifier
      depends_on: [build]
WORKFLOW
        ;;
    
    saga)
        cat > "$OUTPUT_DIR/workflows/default.yaml" <<'WORKFLOW'
workflow:
  type: saga
  
  steps:
    - name: update_schema
      action:
        agent: builder
        args:
          task: "Update database schema"
      compensate:
        agent: builder
        args:
          task: "Rollback schema changes"
    
    - name: migrate_data
      action:
        agent: builder
        args:
          task: "Migrate existing data"
      compensate:
        agent: builder
        args:
          task: "Rollback data migration"
    
    - name: deploy
      action:
        agent: builder
        args:
          task: "Deploy to production"
      compensate:
        agent: builder
        args:
          task: "Rollback deployment"
WORKFLOW
        ;;
esac

# Create plugin examples if requested
if [ "$WITH_PLUGINS" = true ]; then
    mkdir -p "$OUTPUT_DIR/plugins"
    
    cat > "$OUTPUT_DIR/plugins/__init__.py" <<'PLUGIN'
"""Ralph Loop Plugins

This directory contains custom plugins that extend the Ralph Loop.
"""

__version__ = "1.0.0"
PLUGIN
    
    cat > "$OUTPUT_DIR/plugins/slack_notifier.py" <<'PLUGIN'
"""Slack notification plugin for Ralph Loop"""

import os
from typing import Any, Dict

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

class SlackNotifier:
    """Sends notifications to Slack"""
    
    def __init__(self, config: Dict[str, Any]):
        self.webhook_url = config.get('webhook') or os.getenv('SLACK_WEBHOOK_URL')
        self.channel = config.get('channel', '#builds')
        
    def on_start(self, context: Dict[str, Any]):
        """Called when loop starts"""
        self._send(f"🚀 Ralph Loop started for {context.get('project_name', 'Unknown')}")
    
    def on_complete(self, context: Dict[str, Any]):
        """Called when loop completes successfully"""
        iterations = context.get('iterations', 0)
        self._send(f"✅ Ralph Loop completed in {iterations} iterations")
    
    def on_failure(self, context: Dict[str, Any]):
        """Called when loop fails"""
        error = context.get('error', 'Unknown error')
        self._send(f"❌ Ralph Loop failed: {error}")
    
    def _send(self, message: str):
        """Send message to Slack"""
        if not self.webhook_url or not HAS_REQUESTS:
            print(f"[Slack] {message}")
            return
        
        try:
            requests.post(
                self.webhook_url,
                json={"text": message, "channel": self.channel}
            )
        except Exception as e:
            print(f"[Slack Error] {e}")

def register():
    """Register plugin"""
    return SlackNotifier
PLUGIN

    echo "✓ Created plugins/ directory with examples" >&2
fi

# Create dashboard config if requested
if [ "$WITH_DASHBOARD" = true ]; then
    mkdir -p "$OUTPUT_DIR/monitoring/grafana"
    
    cat > "$OUTPUT_DIR/monitoring/grafana/dashboard.yaml" <<'DASHBOARD'
apiVersion: 1
providers:
  - name: 'Ralph Loop Dashboard'
    orgId: 1
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards
      
dashboards:
  - title: "Ralph Loop Overview"
    panels:
      - title: "Success Rate"
        type: stat
        targets:
          - expr: "ralph_success_rate"
      
      - title: "Iteration Duration"
        type: graph
        targets:
          - expr: "ralph_iteration_duration_seconds"
      
      - title: "Agent Performance"
        type: table
        targets:
          - expr: "ralph_agent_duration_seconds"
DASHBOARD

    echo "✓ Created monitoring/grafana/ dashboard config" >&2
fi

# Create tests if requested
if [ "$WITH_TESTS" = true ]; then
    mkdir -p "$OUTPUT_DIR/tests"
    
    cat > "$OUTPUT_DIR/tests/__init__.py" <<'TEST'
"""Tests for Ralph Loop"""
TEST
    
    cat > "$OUTPUT_DIR/tests/test_loop.py" <<'TEST'
"""Test suite for Ralph Loop workflow engine"""

import unittest
from pathlib import Path
import tempfile
import shutil

class TestRalphLoop(unittest.TestCase):
    """Test Ralph Loop functionality"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.test_dir)
    
    def test_state_persistence(self):
        """Test that state is persisted correctly"""
        # TODO: Implement test
        pass
    
    def test_retry_mechanism(self):
        """Test retry with exponential backoff"""
        # TODO: Implement test
        pass
    
    def test_circuit_breaker(self):
        """Test circuit breaker pattern"""
        # TODO: Implement test
        pass
    
    def test_plugin_hooks(self):
        """Test plugin hook system"""
        # TODO: Implement test
        pass

if __name__ == '__main__':
    unittest.main()
TEST

    echo "✓ Created tests/ directory with test suite" >&2
fi

# Create enhanced README
cat > "$OUTPUT_DIR/README.md" <<README
# Ralph Loop - Enterprise Workflow Engine

AI-driven development workflow with plugin system, agent orchestration, and monitoring.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run with default configuration
python ralph-loop.py loop

# Run with custom workflow
python ralph-loop.py loop --workflow workflows/ci.yaml

# Run with monitoring
python ralph-loop.py loop --observability
```

## Configuration

Edit \`ralph.yaml\` to customize:
- Agent timeouts and retry policies
- Circuit breaker settings
- Plugin configuration
- Observability settings

## Workflow Types

### State Machine (default)
Sequential phases with explicit state transitions.

### DAG
Parallel execution with dependency graph.

### Saga
Distributed transactions with compensation.

## Plugin Development

See \`plugins/slack_notifier.py\` for an example.

## Monitoring

Access dashboard at http://localhost:8080 (if --with-dashboard)

## Documentation

Full documentation: https://github.com/wojons/skills/tree/main/skills/ralph-wiggum-loop
README

chmod +x "$OUTPUT_DIR/ralph-loop.py"

echo "" >&2
echo "✓ Ralph Loop (Enterprise Edition) created in $OUTPUT_DIR" >&2
echo "" >&2
echo "Template: $TEMPLATE" >&2
echo "Plugins: $WITH_PLUGINS" >&2
echo "Dashboard: $WITH_DASHBOARD" >&2
echo "Tests: $WITH_TESTS" >&2
echo "" >&2
echo "Quick start:" >&2
echo "  cd $OUTPUT_DIR" >&2
echo "  pip install -r requirements.txt" >&2
echo "  python ralph-loop.py loop" >&2
