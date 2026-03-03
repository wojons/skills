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

Generate working Ralph loops - AI-driven development workflows that iterate until tasks succeed.

## Quick Start

```bash
# Generate a working Ralph loop
bash scripts/generate-ralph-loop.sh python builder-only ./my-loop

cd my-loop
./run.sh
```

## What This Skill Provides

### 1. Runnable Loop Generator
**Script**: `scripts/generate-ralph-loop.sh`

Generates complete, working loop implementations:

```bash
# Single agent: build until success
bash scripts/generate-ralph-loop.sh python builder-only ./my-loop

# Two agents: build → verify → retry
bash scripts/generate-ralph-loop.sh python build-verify ./my-loop

# Three agents: plan → build → verify
bash scripts/generate-ralph-loop.sh python build-verify-plan ./my-loop

# Node.js version
bash scripts/generate-ralph-loop.sh node builder-only ./my-loop
```

Output includes:
- Executable loop implementation (`loop.py` or `loop.ts`)
- Configuration file (`LOOP_CONFIG.yaml`)
- Dependencies (`requirements.txt` or `package.json`)
- Run script (`run.sh`)

### 2. Configurable Behavior

Edit `LOOP_CONFIG.yaml` to customize:

```yaml
workflow:
  name: "my-task"
  max_iterations: 20
  
  agent:
    role: "builder"
    tools: ["read", "write", "edit", "bash", "question"]
    stop_condition: "<promise>TASK_COMPLETE</promise>"
```

### 3. Three Proven Patterns

#### Pattern 1: Builder Only
One agent builds, retries until success. Fast, simple, low cost.

#### Pattern 2: Build + Verify
Builder creates → Verifier checks quality → Retry if fails. Better quality.

#### Pattern 3: Build + Verify + Plan
Planner plans → Builder implements → Verifier checks. Best for complex tasks.

## How Loops Work

1. **Start loop** with defined pattern
2. **Agent executes** (builds, verifies, plans)
3. **Check success** - tests pass? code compiles? feature works?
4. **If success** → loop completes
5. **If failure** → retry next iteration
6. **Stop at** max iterations if not complete

## Configuration Examples

### Simple Loop:
```yaml
workflow:
  max_iterations: 20
  stop_on_success: true
  
  task:
    description: "Build feature X"
    success_criteria:
      - "Tests pass"
      - "Code compiles"
```

### Build + Verify:
```yaml
agents:
  builder:
    role: "Build the feature"
    stop_condition: "<promise>BUILT</promise>"
    
  verifier:
    role: "Verify quality"
    stop_condition: "<promise>VERIFIED</promise>"
    
sequence:
  - agent: builder
  - agent: verifier
```

## Usage

```bash
# Generate loop
bash scripts/generate-ralph-loop.sh python builder-only ./auth-loop

# Edit config
vim ./auth-loop/LOOP_CONFIG.yaml

# Run loop
cd ./auth-loop
./run.sh
```

## Implementation Details

The generated loops include:

- **Iteration tracking**: Counts and displays progress
- **Success detection**: Checks tests pass, code compiles, etc.
- **Configuration driven**: All behavior from YAML config
- **Error handling**: Graceful failure with iteration limits
- **Dependency management**: Auto-installs required packages

## Notes

- Loops run until success or max_iterations reached
- Success depends on your tests/checks passing
- Edit LOOP_CONFIG.yaml to change behavior
- Use simple patterns first, scale up as needed
- Generated code actually runs, not just demos
