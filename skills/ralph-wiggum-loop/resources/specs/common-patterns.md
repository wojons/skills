# Common Ralph Loop Patterns & Implementations

## Overview

This document catalogs the most common Ralph loop implementations, patterns, and workflows in use today. Use this as a guide for choosing the right pattern for your needs.

## Classification

Patterns are classified by:
- **Agent Count**: Single vs Multi-Agent
- **Execution Model**: Sequential vs Parallel
- **Complexity**: Simple vs Complex
- **Goal Speed**: Fast vs Thorough

## Language Considerations

Ralph loops can be implemented in any programming language, but **dynamic languages are most common**:

| Language | Typical Use | Why |
|----------|-------------|-----|
| **Python** | Agent scripts, test runners | Easy to generate, great for LLMs |
| **JavaScript/TypeScript** | Web apps, frontends, APIs | Dynamic, flexible type hints help AI |
| **Bash/Shell** | Automation scripts, hooks | Simple, command-line oriented |
| Go | More complex systems | Possible but less common for AI generation |
| C++ | Performance-critical code | Rare - typically not needed for loops |

**Why dynamic languages dominate**:
- AI models generate dynamic language code more easily
- No compilation needed during iteration
- Less boilerplate means less to get wrong
- REPL-friendly for real-time testing
- Easier for agents to modify and debug

**When use Go/C++**:
- Performance-critical components
- Existing codebase already in those languages  
- When you need the specific strengths

**Rule of thumb**: If the task doesn't require C++ performance, use Python/JS/TS - it's easier for agents to work with and typically all that's needed for Ralph loops.

## Context Rot Management

### The Problem: Context Degradation ("Dumb Zone")

LLM context windows have a critical limitation: **context degradation**. As an agent iteratively plans, writes code, executes tools, and debugs within a single conversation:

- Accumulation of conversation history
- Failed tool outputs
- Superseded code drafts

This causes the model's attention mechanism to dilute, leading to:

- **"Dumb Zone"**: Past 60-70% context capacity, performance tanks
- Hallucinated APIs
- Forgotten system instructions  
- Cyclical logic errors
- "AI slop" - generating trivial tests instead of robust code

### The Solution: Fresh Context Per Iteration

Ralph loops solve this by:
1. **Forcing statelessness** - Each iteration starts fresh
2. **External state persistence** - Store state in files/Git, not conversation
3. **Minimal allocation** - Only what's needed each iteration
4. **Avoid compaction** - Don't summarize history

**Bash loop approach** (Geoffrey Huntley's original):
```bash
while true; do
  cat PROMPT.md | agent
done
```

This ensures:
- Every iteration gets clean context
- No accumulated conversational bloat
- Context window never enters "Dumb Zone"
- Agent stays oriented to current state

### Practical Implementation

**File-based state**:
```markdown
# PROMPT.md (dynamic, not static)
@prd.md                    # Current requirements
@activity.md              # What was just done
@next_task.md              # What to do next
```

**Agent behavior**:
1. Read PROMPT.md (gets fresh context from files)
2. Identify next task
3. Execute task
4. Write results to activity.md
5. Update state (files, git commits)
6. **Termination causes context purge**
7. Next iteration repeats with clean slate

**Result**: Agent approaches final iteration with same pristine context as first iteration.

### Key Principles

1. **Never rely on conversational memory**
   - Use PROMPT.md to point to current state files
   - Cross-reference prd.md + activity.md each iteration

2. **Keep specifications atomic**
   - Don't bloat prd.md with 50-page specs
   - Use "bidirectional planning" - developer + AI interrogate each other first
   - Leave "cognitive room" for actual code generation

3. **Avoid reusing sessions**
   - New instance = new context window
   - No contamination from previous tasks
   - Prevents pattern bleed between iterations

4. **Update activity logs immediately**
   - After each task, document:
     - Files modified
     - Tools executed
     - Shell commands run
     - Visual verification references
   - Next iteration cross-references to avoid repeats

5. **Context hygiene**
   - Don't reuse chats for unrelated tasks
   - Causes contamination and confusion
   - Fresh session per type of work

This is **the core insight** of Ralph loops: the file system becomes the persistent memory, not the LLM's context window.

## Pattern Catalog

### 1. Simple Retry (Naive Persistence)

**Type**: Single Agent, Sequential, Simple

**Description**: The most basic Ralph loop. One agent runs, fails, feeds error back, and retries.

**When to use**:
- Simple tasks with clear success criteria
- Quick prototyping
- Learning Ralph loops
- Tasks where errors are rare

**Example**:
```yaml
pattern: simple-retry
max_iterations: 20

agent:
  name: builder
  stop_condition: "<promise>TASK_COMPLETE</promise>"

on_failure:
  action: retry
  include_context:
    - error_message
    - stack_trace
    - suggestions
```

**Pros**:
- Easiest to implement
- Low token cost
- Works for straightforward tasks

**Cons**:
- Can get stuck in failure loops
- No verification step
- Doesn't learn from mistakes

---

### 2. Builder + Verifier

**Type**: Sequential, Multi-Agent, Simple → Medium

**Description**: Builder agent creates code, verifier agent checks it. Loop until verification passes.

**When to use**:
- Need quality assurance
- Want separate builder and verifier roles
- Code quality is important

**Example**:
```yaml
pattern: build-verify
sequence:
  - agent: builder
    stop_condition: "<promise>BUILD_COMPLETE</promise>"
    
  - agent: verifier
    input: builder_output
    task: |
      Review for:
      - Code quality
      - Test coverage
      - Security
      - Performance
      
      Output: <promise>VERIFIED</promise> or <promise>NEEDS_FIXES:...</promise>

loop:
  condition:
    if: "<promise>VERIFIED</promise>"
    action: success
    if: "<promise>NEEDS_FIXES:"
    action: retry
```

**Pros**:
- Quality assurance built-in
- Clear separation of concerns
- Better error handling

**Cons**:
- More tokens (2 agents)
- Slower (sequential verification)
- More complex setup

---

### 3. Builder + Verify + Plan (Adjust & Retry)

**Type**: Sequential, Multi-Agent, Medium

**Description**: Similar to Builder+Verifier but adds a Planning step after verification. Planner analyzes failures and suggests better approach.

**When to use**:
- Complex tasks where initial approach may be wrong
- Need strategy adjustment mid-flight
- Want to avoid repeating mistakes

**Example**:
```yaml
pattern: build-verify-plan
sequence:
  - agent: builder
    stop_condition: "<promise>BUILD_COMPLETE</promise>"
    
  - agent: verifier
    output: verdict.json
    
  - agent: planner
    depends_on: verifier
    if: verdict.needs_fixes
    task: |
      Analyze the failures:
      {verifier_feedback}
      
      Suggest new approach to avoid these issues.
      
      Output: <promise>PLAN_ADJUSTED</promise>
      
  - agent: builder
    depends_on: planner
    if: <promise>PLAN_ADJUSTED</promise>
    retry_with: new_plan
```

**Pros**:
- Adapts strategy based on failures
- Learns from mistakes
- Can adjust approach dynamically

**Cons**:
- More agents, more cost
- Slower iteration time
- Complex orchestration

---

### 4. Multi-Agent Pipeline (Parallel Builders)

**Type**: Multi-Agent, Parallel, Complex

**Description**: 3+ builder agents run in parallel on different aspects/s components, then verifier checks all, merging results.

**When to use**:
- Large features with multiple parts
- Code that can be built independently
- Want to speed up development

**Example**:
```yaml
pattern: parallel-pipeline
parallel_workers: 3

sequence:
  - agent: planner
    task: "Break task into 3 subtasks"
    output: tasks.json
    
  - agent: builder-1
    depends_on: planner
    parallel: true
    task: task_1
    
  - agent: builder-2  
    depends_on: planner
    parallel: true
    task: task_2
    
  - agent: builder-3
    depends_on: planner
    parallel: true
    task: task_3
    
  - agent: verifier
    depends_on: [builder-1, builder-2, builder-3]
    task: |
      Merge results and verify integration:
      {builder_outputs}
    
  - agent: planner
    depends_on: verifier
    if: needs_fixes
    task: "Plan coordination fixes"
```

**Pros**:
- Fast parallel execution
- Good for independent components
- Speeds up development

**Cons**:
- Harder to coordinate
- Merge conflicts
- Higher cost

---

### 5. Task Queue (Inbox Pattern)

**Type**: Multi-Agent, Queue-based, Medium

**Description**: Tasks are added to an inbox, agents pick them up, process, and mark complete.

**When to use**:
- Need to process many small tasks
- Want persistence
- Need task tracking

**Example**:
```yaml
pattern: task-queue
queue:
  inboxes:
    builder: tasks/
    verifier: verified/
    planner: planned/
  
  agents:
    - name: builder
      max_concurrent: 3
      
    - name: verifier
      max_concurrent: 2
      
flow:
  1. Planner adds tasks to builder queue
  2. Builders pick up tasks (up to 3 at once)
  3. Builders mark as done → verifier queue
  4. Verifiers check → planner queue if failed
  5. Loop until all verified
```

**Pros**:
- Flexible task management
- Good for many small items
- Persistent state

**Cons**:
- More complex infrastructure
- Need queue management
- Higher overhead

---

### 6. Human-in-the-Loop

**Type**: Interactive, Pauses for input, Variable Complexity

**Description**: Ralph loop that stops at key points for human approval, feedback, or decisions.

**When to use**:
- Need human verification at key points
- Expensive operations that need approval
- Sensitive code changes
- Learning new requirements

**Example**:
```yaml
pattern: human-in-the-loop
checkpoints:
  - id: "design_review"
    step: after_planning
    prompt: "Review the design and approve or modify?"
    
  - id: "code_review"
    step: after_implementation  
    prompt: "Review the implementation. Approve or request changes?"
    
  - id: "test_review"
    step: after_testing
    prompt: "Test results are ready. Approve deployment?"

human_intervention:
  - event: checkpoint_reached
    wait_for: approval
    timeout: 3600  # 1 hour
    
  - event: failure_threshold_exceeded
    action: ask_user
    message: "Failed 3 times. Continue or stop?"
```

**Pros**:
- Human oversight
- Can handle ambiguity
- Good for production

**Cons**:
- Slower (needs humans)
- Not autonomous
- Requires human attention

---

### 7. Adaptive (Self-Healing)

**Type**: Complex, Adaptive Learning, Advanced

**Description**: Ralph loop that learns from failures and autonomously adjusts strategy, prompts, parameters.

**When to use**:
- Complex tasks where trial and error is needed
- Want the system to learn optimal approaches
- Long-running tasks where optimization matters

**Example**:
```yaml
pattern: adaptive
learning:
  - track_failure_patterns
  - identify_recurring_errors
  - adjust_prompts_based_on_history
  
adaptations:
  - if: failure_count > 3
    action: increase_prompt_detail
    
  - if: token_cost > threshold
    action: switch_to_smaller_model
    
  - if: same_error_repeated
    action: try_alternative_approach
    
  - if: long_execution_time
    action: split_into_smaller_tasks
```

**Pros**:
- Learns optimal approach
- Can handle difficult tasks
- Self-optimizes

**Cons**:
- Most complex to implement
- Harder to debug
- Higher initial cost

---

### 8. Hierarchical (Swarm)

**Type**: Multi-level, Complex, Production-Grade

**Description**: Orchestrator agent coordinates multiple sub-agents, each specialized for different aspects.

**When to use**:
- Very complex workflows
- Need specialized agents
- Production systems
- Enterprise workflows

**Example**:
```yaml
pattern: hierarchical
orchestrator:
  agent: conductor
  subagents:
    builder_group:
      - builder_frontend
      - builder_backend
      - builder_infrastructure
      
    verifier_group:
      - verifier_security
      - verifier_performance
      - verifier_quality
      
    tester_group:
      - tester_unit
      - tester_integration
      - tester_e2e
      
flow:
  1. Conductor plans work
  2. Assigns to builders
  3. Builders complete → verifiers
  4. Verifiers pass → testers
  5. Testers pass → conductor reports
  6. On failure, conductor coordinates retry
```

**Pros**:
- Highly specialized
- Clear separation
- Scalable

**Cons**:
- Most complex
- High cost
- Need coordination

---

### 9. Manual Command Loop

**Type**: Interactive, Semi-Autonomous, Low-Medium Complexity

**Description**: Agent suggests or executes OpenCode `/` commands in the TUI. User sees each iteration in real-time, verifies results, and decides whether to continue or adjust.

**When to use**:
- Learning Ralph loops
- Debugging and experimentation
- Tasks requiring oversight
- Want manual control over iterations
- Need to understand what's happening

**Example**:
```markdown
# Define commands in .opencode/commands/

.opencode/commands/builder.md
---
description: Build authentication system
agent: build
---
Build auth system:
1. Create user models
2. Add login endpoint
3. Add registration endpoint

Output: <promise>AUTH_BUILT</promise>
```

**Usage**:
```
> /builder
Building authentication system...
✓ Created user models
✓ Added endpoints

Next: /verifier or continue?

> Continue
```

**Pros**:
- Full visibility of iterations
- Can ask questions mid-loop
- Can adjust approach anytime
- Lower token cost
- Best for learning

**Cons**:
- Slower execution
- Needs user presence
- Not overnight capable
- Higher mental overhead

**Key Feature**: Uses OpenCode slash commands (`/command`) for visibility and control


## Pattern Selection Matrix

| Pattern | Agents | Execution | Complexity | Speed | Cost | Control | Best For |
|---------|--------|-----------|------------|-------|------|--------|----------|
| Simple Retry | 1 | Sequential | Low | Fast | Low | Low | Quick prototypes |
| Build + Verify | 2 | Sequential | Low-Medium | Medium | Medium | Low | Quality needed |
| Build + Verify + Plan | 3 | Sequential | Medium | Slow | Medium-High | Low | Strategy adjustment |
| Parallel Pipeline | 3+ | Parallel | High | Fast | High | Low | Independent parts |
| Task Queue | 2+ | Queue-Based | Medium | Variable | Medium | Low | Many tasks |
| Human-in-the-Loop | 2+ | Interactive | Variable | Slow | Moderate | High | Production |
| Adaptive | 2+ | Adaptive | High | Variable | High | Low | Complex tasks |
| Hierarchical | Many | Hierarchical | Very High | Variable | High | Low | Enterprise |
| Manual Command | 2+ | Interactive | Low-Medium | Slow | Low-medium | High | Learning & Debugging |

---

## Real-World Examples

### Example 1: Bug Fix with Simple Retry

**Task**: Fix a broken authentication endpoint

**Pattern**: Simple Retry

**Configuration**:
```yaml
agent: bug-fixer
max_iterations: 10
stop_condition: "<promise>BUG_FIXED</promise>"

workflow:
  1. Reproduce the issue
  2. Identify the root cause
  3. Implement fix
  4. Write test reproducing bug
  5. Verify test passes
```

### Example 2: Multi-Feature Implementation

**Task**: Build complete authentication system with registration, login, and password reset

**Pattern**: Multi-Agent Pipeline

**Configuration**:
```yaml
parallel_workers: 3

builders:
  builder_frontend:
    task: "Build UI for auth"
    stop_condition: "<promise>UI_COMPLETE</promise>"

  builder_backend:
    task: "Build API endpoints"  
    stop_condition: "<promise>API_COMPLETE</promise>"

  builder_tests:
    task: "Write comprehensive tests"
    stop_condition: "<promise>TESTS_COMPLETE</promise>"

verifier:
  merges_results: true
  checks:
    - ui_quality
    - api_correctness
    - test_coverage
```

### Example 3: Refactoring Large Codebase

**Task**: Refactor legacy codebase to use modern patterns

**Pattern**: Adaptive with Task Queue

**Configuration**:
```yaml
queue:
  tasks:
    - analyze_codebase
    - identify_smells
    - plan_refactor
    - implement_changes
    - verify_no_regressions

learning:
  track_patterns: true
  adjust_approach: true
```

### Example 4: Production Feature with Quality Gates

**Task**: Add new payment processing feature

**Pattern**: Human-in-the-Loop

**Configuration**:
```yaml
checkpoints:
  - design_review
  - security_review
  - test_review
  - code_review
  - deployment_approval

approvals_required:
  - senior_engineer
  - security_lead
```

---

## Emerging Patterns

### Pattern: Self-Specifying

**Description**: Agent asks questions to the system/user to understand requirements before executing.

**Use Case**: Ambiguous tasks

**Example**:
```yaml
agent: spec_builder
discovery_mode: true
questions:
  - "What's the primary language?"
  - "What framework should I use?"
  - "Are there existing patterns to follow?"
  - "What's the success criteria?"
```

### Pattern: Documentation-First

**Description**: Write docs first, then implement to match.

**Use Case**: API development

**Example**:
```yaml
agents:
  - doc_writer
  - implementer
  - verifier_match

flow:
  1. Write comprehensive API docs
  2. Implement to match docs
  3. Verify implementation matches docs
```

### Pattern: Test-Driven Development

**Description**: Write failing tests first, then implement code to pass.

**Use Case**: New features

**Example**:
```yaml
agents:
  - test_writer
  - implementer
  - test_runner

flow:
  1. Write comprehensive tests
  2. Implement code to pass tests
  3. Run tests and verify
```

## Contributing Patterns

Have a new Ralph loop pattern? Add it to this catalog with:
- Clear description
- When to use
- Example configuration
- Pros/Cons
- Real-world example

---

## Implementation Code for Each Pattern

### Pattern 1: Simple Retry Loop - Implementation

```typescript
import { readFileSync, writeFileSync } from 'fs'
import { execSync } from 'child_process'

class SimpleRetryLoop {
  constructor(
    private promptPath: string,
    private maxIterations: number = 20,
    private outputFormat: string = 'json'
  ) {}

  async run(): Promise<LoopResult> {
    for (let iteration = 0; iteration < this.maxIterations; iteration++) {
      console.log(`\n=== Iteration ${iteration + 1}/${this.maxIterations} ===`)

      try {
        // Execute agent with prompt
        const output = this.executeAgent()

        // Check for completion
        if (this.isComplete(output)) {
          return {
            success: true,
            iterations: iteration + 1,
            result: this.extractResult(output)
          }
        }

        // Feedback into prompt for next iteration
        this.updatePromptWithError(iteration, output)

      } catch (error) {
        console.error('Agent execution failed:', error.message)

        // Try to recover
        if (iteration < this.maxIterations - 1) {
          console.log('Retrying...')
          continue
        }

        return {
          success: false,
          iterations: iteration + 1,
          error: error.message
        }
      }
    }

    return {
      success: false,
      iterations: this.maxIterations,
      reason: 'Max iterations exceeded'
    }
  }

  private executeAgent(): string {
    // Placeholder - actual agent execution depends on your OpenCode integration
    const command = `cat ${this.promptPath} | opencode run -`
    try {
      return execSync(command, { encoding: 'utf8' })
    } catch (error) {
      throw new Error(`Agent execution failed: ${error.message}`)
    }
  }

  private isComplete(output: string): boolean {
    return output.includes('<promise>COMPLETE</promise>') ||
           output.includes('<promise>SUCCESS</promise>') ||
           output.includes('<promise>DONE</promise>')
  }

  private extractResult(output: string): any {
    // Extract result from promise tags
    const match = output.match(/<promise>\s*(.*?)\s*<\/?promise>/)
    return match ? match[1] : 'UNKNOWN'
  }

  private updatePromptWithError(iteration: number, error: string): void {
    const prompt = readFileSync(this.promptPath, 'utf8')
    const updated = prompt.replace(
      /## Current State.*?##/,
      `## Current State\nIteration: ${iteration}\nLast Error: ${error}\n##`
    )
    writeFileSync(this.promptPath, updated)
  }
}

// Usage
const loop = new SimpleRetryLoop('./PROMPT.md', 20)
const result = await loop.run()
console.log('Result:', result)
```

### Pattern 2: Build + Verify Loop - Implementation

```typescript
class BuildVerifyLoop {
  async run(task: string): Promise<BuildVerifyResult> {
    let iteration = 0
    const maxIterations = 20

    while (iteration < maxIterations) {
      iteration++
      console.log(`\n=== Build+Verify Iteration ${iteration}/${maxIterations} ===`)

      // Step 1: Build phase
      console.log('🔨 Building...')
      const buildResult = await this.build(task)

      if (!buildResult.success) {
        console.error('Build failed:', buildResult.error)
        continue
      }

      console.log('✓ Build succeeded')
      this.buildArtifacts = buildResult.artifacts

      // Step 2: Verify phase
      console.log('✓ Verifying...')
      const verifyResult = await this.verify(this.buildArtifacts)

      if (verifyResult.success) {
        console.log('✅ Verification passed!')
        return {
          success: true,
          iterations: iteration,
          artifacts: this.buildArtifacts
        }
      }

      console.error('⛔ Verification failed:', verifyResult.issues)
      this.updateTaskWithFeedback(task, verifyResult.feedback)
    }

    return {
      success: false,
      iterations: maxIterations,
      reason: 'Max iterations reached without verification passing'
    }
  }

  private async build(task: string): Promise<BuildResult> {
    // Execute builder agent
    const prompt = `Build the following: ${task}
Output format: <promise>BUILD_COMPLETE</promise>
Include all files created.`

    try {
      // Use OpenCode agent to execute
      // This is simplified - actual implementation uses OpenCode API
      const output = execSync(`echo "${prompt}" | opencode run -`, { encoding: 'utf8' })

      if (!output.includes('<promise>BUILD_COMPLETE</promise>')) {
        return { success: false, error: 'Build did not complete' }
      }

      // Extract created files
      const files = this.parseCreatedFiles(output)

      return {
        success: true,
        artifacts: files
      }
    } catch (error) {
      return { success: false, error: error.message }
    }
  }

  private async verify(artifacts: any[]): Promise<VerifyResult> {
    // Execute verifier agent
    const fileList = artifacts.map(a => a.path).join(', ')

    try {
      const prompt = `Verify these files: ${fileList}
Check:
- Code quality and style
- Functionality correctness
- Edge cases covered

Output format: <promise>VERIFIED</promise> or <promise>NEEDS_FIXES:...</promise>`

      const output = execSync(`echo "${prompt}" | opencode run -`, { encoding: 'utf8' })

      if (output.includes('<promise>VERIFIED</promise>')) {
        return { success: true }
      }

      // Extract feedback
      const feedback = this.parseVerifyFeedback(output)

      return {
        success: false,
        issues: feedback
      }
    } catch (error) {
      return { success: false, issues: [error.message] }
    }
  }

  private updateTaskWithFeedback(task: string, feedback: string[]): void {
    // Add feedback to task description for next iteration
    this.task = `${task}\nFix these issues:\n${feedback.join('\n')}`
  }

  private parseCreatedFiles(output: string): Artifact[] {
    // Parse output for created/modified files
    // Simplified example
    return [
      { path: 'src/feature.ts', type: 'created' }
    ]
  }

  private parseVerifyFeedback(output: string): string[] {
    // Parse verification issues from output
    const issuePattern = /NEEDS_FIXES:(.*)/gu
    const matches = output.match(issuePattern)
    return matches ? [matches[1]] : ['Verification failed']
  }
}

// Usage
const loop = new BuildVerifyLoop()
const result = await loop.run('Create authentication with JWT tokens')

if (result.success) {
  console.log('Files created:', result.artifacts)
}
```

### Pattern 3: Build + Verify + Plan - Implementation

```typescript
class BuildVerifyPlanLoop {
  constructor(
    private builder: Agent,
    private verifier: Agent,
    private planner: Agent
  ) {}

  async run(task: string): Promise<PlanLoopResult> {
    let iteration = 0
    const maxIterations = 20

    while (iteration < maxIterations) {
      iteration++
      console.log(`\n=== Build+Verify+Plan Iteration ${iteration}/${maxIterations} ===`)

      // Phase 1: Build
      console.log('🔨 Building...')
      const buildResult = await this.builder.execute(task)

      if (!buildResult.success) {
        console.error('Build failed')
        // Ask planner what to do
        const guidance = await this.adjustStrategy(task, buildResult.error)
        task = this.updateTask(task, guidance)
        continue
      }

      // Phase 2: Verify
      console.log('✓ Verifying...')
      const verifyResult = await this.verifier.execute(buildResult.artifacts)

      if (!verifyResult.success) {
        console.error('Verification failed')
        // Ask planner what to do
        const guidance = await this.adjustStrategy(task, verifyResult.error)
        task = this.updateTask(task, guidance)
        continue
      }

      // Success!
      console.log('✅ Build+Verify succeeded!')
      return {
        success: true,
        iterations: iteration,
        artifacts: buildResult.artifacts
      }
    }

    return {
      success: false,
      iterations: maxIterations,
      reason: 'Max iterations exceeded'
    }
  }

  private async adjustStrategy(task: string, error: string): Promise<string> {
    const prompt = `Task: ${task}

Last error: ${error}

Analyze what went wrong and suggest a new approach.
Output format: <promise>PLAN_ADJUSTED: new approach description</promise>`

    const output = execSync(`echo "${prompt}" | opencode run -`, { encoding: 'utf8' })

    // Extract new approach
    const pattern = /PLAN_ADJUSTED:\s*(.*)/gu
    const match = output.match(pattern)
    return match ? match[1].trim() : 'Try again'
  }

  private updateTask(task: string, guidance: string): string {
    return `${task}\n\nGuidance: ${guidance}`
  }
}

// Usage
const loop = new BuildVerifyPlanLoop(
  new BuilderAgent(),
  new VerifierAgent(),
  new PlannerAgent()
)
const result = await loop.run('Create authentication with JWT tokens')
```

## Implementation Summary

**Key Concepts for All Patterns**:

1. **State Management**: Store loop state between iterations
2. **Error Recovery**: Handle failures and retry appropriately  
3. **Completion Detection**: Parse promise patterns from output
4. **Agent Execution**: Use OpenCode CLI or API to run agents
5. **Configuration**: YAML configs define parameters and behavior
6. **Orchestration**: Sequential vs. parallel pattern execution

**Building Blocks:**

- `SimpleRetryLoop` - Basic retry with prompt updates
- `BuildVerifyLoop` - Sequential build → verify → retry cycle
- `BuildVerifyPlanLoop` - Add planner for strategy adjustment

For other patterns (parallel, hierarchical, etc.), see related implementation examples in this documentation.

---

**Remember**: The "meta" point is that no single pattern is always right. Choose based on task complexity, time constraints, budget, and quality requirements. This skill helps you build the right pattern for YOUR needs.
