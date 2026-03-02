# OpenCode Ralph Wiggum Skill

**The definitive resource for building Ralph loops** - configurable AI-driven development workflows that iterate until tasks complete successfully.

## What is a Ralph Loop?

Ralph loops are AI-driven development workflows that iterate until a task completes successfully. Named after the *Ralph Wiggum* character from The Simpsons (known for persistent, naive optimism), the technique involves:

- Feeding failures back into the AI's input
- Creating "contextual pressure cookers"
- Using stop hooks to detect completion promises
- Iterating until success conditions are met

## What This Skill Provides

This is a **meta-skill** - a comprehensive resource that gives you everything you need to build ANY type of Ralph loop:

### 📚 Complete Knowledge Base (resources/specs/)

**7 comprehensive guides** (~4,700 lines covering all aspects):

1. **[OpenCode Serve API](resources/specs/opencode-serve-api.md)**
   - HTTP server integration with `/doc?format=json` endpoint (verified)
   - SSE streaming for real-time event parsing
   - Session management and API discovery
   - Best practices for server-based loops

2. **[File & State Management](resources/specs/file-state-patterns.md)**
   - PROMPT.md and PROMPT-step.md patterns
   - Inboxes and agent task queues
    - Beads tool (1.7k stars on GitHub)
   - Markdown vs structured task management
   - State persistence strategies

3. **[UI & Monitoring](resources/specs/ui-monitoring.md)**
   - TUI (terminal) dashboards
   - Web dashboards with cost tracking
   - SSE event streaming patterns
   - Alert systems and notifications

4. **[Common Patterns Catalog](resources/specs/common-patterns.md)**
   - **10 pattern catalog** with pros/cons
   - Selection matrix by complexity, speed, cost, control
   - Real-world examples for each pattern
   - When to use each approach

5. **[Manual Command Loop](resources/specs/manual-command-loop.md)**
   - OpenCode `/` slash commands in TUI
   - Interactive agent suggestions
   - User control and visibility
   - Comparison with automated approaches

6. **[Steering Packets](resources/specs/steering-packets.md)**
   - XML-based agent orchestration
   - 4 routing patterns (linear, conditional, parallel, unblocking)
   - Fail behavior (open vs closed)
   - Complete real-world examples

7. **[TUI Command Experience](resources/specs/tui-command-experience.md)**
   - Complete interactive flow walkthrough
   - 8-step user journey
   - Agent command suggestion patterns
   - Error recovery and debugging

8. **[Git Hooks & Steering](resources/specs/git-hooks-steering.md)**
   - Natural language hooks for agent guidance
   - Pre-commit protection and quality gates
   - Git lifecycle management
   - Branching strategies (Git Flow, GitHub Flow, trunk-based)

### 🛠️ Skill Implementation (skill/)

**Agent + Tools** for building loops:

- **[Workflow Builder Agent](skill/agents/workflow-builder.md)**: Questions, pattern selection, config generation
- **OpenCode Server Tool**: Start/stop server, fetch docs
- **SSE Parser Tool**: Parse events, detect completion promises

### 📦 Ready-to-Use Templates (resources/patterns/)

**3 pattern templates** with YAML schemas:

- `builder-only.yaml` - Simple single-agent loop
- `build-verify-plan.yaml` - Sequential + verification
- `multi-agent-pipeline.yaml` - Parallel execution
- `workflow-schema.json` - YAML validation

### 🔧 Generators (TODO)

Coming soon:
- `yaml-config.ts` - Convert questions to YAML configs
- `ralph-loop-generator.ts` - Generate full implementations

---

## Quick Start

### Option 1: Use Workflow Builder Agent

```bash
# In your project
opencode
/agent use @workflow-builder

# Agent will ask about your needs and generate configuration
```

### Option 2: Start from Pattern Template

```bash
# 1. Choose a pattern
cp resources/patterns/builder-only.yaml ralph-wiggum.yaml

# 2. Customize configuration
vim ralph-wiggum.yaml

# 3. Run your loop
python ralph-loop.py
```

### Option 3: Learn About Patterns First

Start with `resources/specs/common-patterns.md` to understand which pattern suits your needs.

---

## Complete Documentation Index

### 📘 Getting Started Guides

| Document | What to Learn | When to Use |
|----------|---------------|-------------|
| **[Common Patterns](resources/specs/common-patterns.md)** | 10 pattern catalog + selection matrix | Choosing your approach |
| **[MCP Tools & Patterns](resources/specs/mcp-tools-patterns.md)** | searxng, browser tools, agent inbox | Adding search, automation, async |
| **[Language Considerations](resources/specs/common-patterns.md#language-considerations)** | Python/JS/TS vs Go/C++ | Deciding which language to use |

### 📖 Core Concepts

| Document | What to Learn | When to Use |
|----------|---------------|-------------|
| **[OpenCode Server API](resources/specs/opencode-serve-api.md)** | Server integration, SSE streams | Using opencode serve |
| **[File & State Patterns](resources/specs/file-state-patterns.md)** | PROMPT.md, inboxes, Beads | Managing loop state |
| **[Steering Packets](resources/specs/steering-packets.md)** | Agent orchestration, routing | Multi-agent coordination |
| **[Git Hooks](resources/specs/git-hooks-steering.md)** | Agent guidance, protection | Adding steering/protection |

### 🎛️ Implementation Options

| Document | What to Learn | When to Use |
|----------|---------------|-------------|
| **[Manual Command Loop](resources/specs/manual-command-loop.md)** | TUI slash commands | Learning, debugging, control |
| **[TUI Command Experience](resources/specs/tui-command-experience.md)** | Interactive agent flow | Understanding local TUI workflows |
| **[UI Monitoring](resources/specs/ui-monitoring.md)** | Dashboards, cost tracking | Overnight builds, production |

---

## Pattern Catalog Overview

### 10 Documented Patterns

| # | Pattern | Type | Speed | Control | Best For |
|---|---------|------|-------|---------|----------|
| 1 | Simple Retry | Single Agent | Fast | Low | Quick prototypes |
| 2 | Build + Verify | Sequential | Medium | Low | Quality needed |
| 3 | Build + Verify + Plan | Sequential | Slow | Low | Strategy adjustment |
| 4 | Parallel Pipeline | Multi-Agent | Fast | Low | Independent parts |
| 5 | Task Queue | Queue-Based | Variable | Low | Many tasks |
| 6 | Human-in-the-Loop | Interactive | Slow | High | Production |
| 7 | Adaptive | Adaptive | Variable | Low | Complex tasks |
| 8 | Hierarchical | Many Agents | Variable | Low | Enterprise |
| 9 | Manual Command | Interactive | Slow | High | Learning & debugging |
| 10 | Steering Packets | Orchestration | Variable | High | Multi-agent coordination |

**See**: [`common-patterns.md`](resources/specs/common-patterns.md) for detailed descriptions, examples, and pros/cons.

---

## Core Patterns in Detail

### Single Agent Patterns

**Builder Only**
- One agent builds and retries
- Simple failures iterate automatically
- Easiest to implement

**Build + Verify**
- Builder creates code → Verifier checks quality
- Loop if verification fails
- Simple pattern for quality assurance

**Build + Verify + Plan**
- Builder + Verifier + Planner
- Planner adjusts strategy based on failures
- Better for complex tasks

### Multi-Agent Patterns

**Parallel Pipeline**
- 3 builders run in parallel
- 3 verifiers check results
- Merger combines findings
- Best for speed on independent tasks

**Task Queue (Inbox)**
- Tasks added to inbox
- Agents pick up work
- Persistent task tracking
- Best for many small tasks

**Hierarchical**
- Orchestrator coordinates sub-agents
- Specialized roles for each agent
- Best for enterprise workflows

### Interactive Patterns

**Manual Command Loop**
- Agent suggests `/` commands
- User executes to see output
- Full visibility and control
- Best for learning and debugging

**Human-in-the-Loop**
- Approval gates at key points
- Quality checks before proceeding
- Best for production deployments

**Steering Packets**
- XML-based routing control
- Agent orchestration and decision-making
- Fail behavior (open/closed)
- Best for complex workflows

---

## Implementation Layers

### Layer 1: Pattern Selection

1. **Understand your task**: Bug fix? Feature? Refactoring?
2. **Choose a pattern**: Use the selection matrix
3. **Get the template**: Copy from `resources/patterns/`
4. **Configure**: Edit YAML with your settings

### Layer 2: Integration Options

**Option A: OpenCode Server** (`opencode serve`)
- `/doc.json` API discovery (verified endpoint)
- SSE event streaming (/event, /global/event)
- Web dashboard
- Best for automation

**Option B: TUI Commands** (local)
- Interactive agent suggestions
- Real-time terminal visibility
- User control
- Best for learning/debugging

**Option C: Hybrid**
- Use both as needed
- Server for automation
- TUI for interactive work

### Layer 3: Orchestration

**Steering Packets**
- Decide what agent acts next
- Carry context between agents
- Handle blocked states
- Resolve failures

### Layer 4: Quality & Protection

**Git Hooks** (or equivalent)
- Pre-commit quality checks
- Natural language guidance
- Protect from bad code
- Explain failures

---

## File System Structure

```
opencode-ralph-wiggum-skill/
├── README.md                         # This file - complete overview
├── skill.md                          # Skill metadata
├── init.sh                           # Setup script
│
├── skill/                           # Implementation
│   ├── agents/
│   │   └── workflow-builder.md      # Questions agent
│   ├── tools/
│   │   ├── opencode-server.ts      # Server integration
│   │   └── sse-parser.ts           # Stream parsing
│   └── generators/                  # TODO
│
├── resources/                       # Knowledge base
│   ├── specs/                      # 7 detailed guides (~4,700 lines)
│   │   ├── common-patterns.md     # 10 pattern catalog
│   │   ├── file-state-patterns.md # PROMPT.md, Beads, inboxes
│   │   ├── ui-monitoring.md       # Dashboards, cost tracking
│   │   ├── manual-command-loop.md # TUI commands
│   │   ├── steering-packets.md    # Agent orchestration
│   │   ├── tui-command-experience.md # Interactive flows
│   │   ├── git-hooks-steering.md  # Protection & guidance
│   │   └── opencode-serve-api.md  # Server integration
│   │
│   ├── patterns/                    # Ready-to-use templates
│   │   ├── builder-only.yaml
│   │   ├── build-verify-plan.yaml
│   │   └── multi-agent-pipeline.yaml
│   │
│   ├── templates/                   # Schemas
│   │   └── workflow-schema.json
│   │
│   └── examples/                    # TODO: Workflow examples
│       ├── parallel-tasks/
│       ├── sequential-workflows/
│       └── custom-agents/
│
└── RESEARCH.md                      # Research plan (for adding more)
```

---

## Sample Workflow: Building a Ralph Loop

### Step 1: Choose Your Pattern

```
I need to build an authentication system.
Is this a complex feature? Yes.
Do I need quality checks? Yes.
Team size? Just me.

→ Best pattern: Build + Verify or Build + Verify + Plan
```

### Step 2: Select Implementation

```
Will I run this overnight? No.
Do I want to watch it work? Yes.
Need user control? Yes.

→ Best approach: Manual Command Loop (TUI)
```

### Step 3: Configure Hooks

```
Don't want broken code committed.
Need to enforce patterns.
Want automatic guidance.

→ Add: Git hooks pre-commit checks
```

### Step 4: Set Up State Management

```
Need to track progress.
Want to maintain history.
Need task coordination.

→ Use: Beads (1.7k stars) or PROMPT.md files
```

### Step 5: Run and Iterate

```
1. Define commands in `.opencode/commands/`
2. Agent suggests commands as it works
3. User sees output in TUI
4. Hooks check quality
5. Loop until success
```

**See**: Each spec file for implementation details!

---

## Safety Best Practices

**Always configure for safety**:

1. **Max iterations** (escape hatches)
   ```yaml
   settings:
     max_iterations: 20
   ```

2. **Sandbox environments** (container isolation)
   ```yaml
   safety:
     sandbox: true
   ```

3. **Stop hooks** (completion promises)
   ```yaml
   stop_condition: "<promise>TASK_COMPLETE</promise>"
   ```

4. **Permission controls** (ask/allow/deny)
   ```yaml
   permissions:
     file_edits: ask
     bash_commands: allow
   ```

5. **Rate limits** (don't burn tokens)
   ```yaml
   safety:
     max_cost: 50  # $50 USD
   ```

6. **Git hooks** (quality protection)
   ```yaml
   git_hooks:
     pre_commit: true
     reject_on_failure: true
   ```

---

## Language Considerations

**Ralph loops can be implemented in any language**, but **dynamic languages are most common**:

| Language | Typical Use | Why |
|----------|-------------|-----|
| **Python** | Agent scripts, test runners | Easy to generate, LLM-friendly |
| **JavaScript/TypeScript** | Web apps, APIs | Dynamic, flexible types |
| **Bash/Shell** | Automation, hooks | Simple, CLI-oriented |
| Go, C++ | Performance-critical | Rare, only when needed |

**Why dynamic languages**:
- Easier for AI models to generate
- No compilation step during iterations
- Less boilerplate = fewer mistakes
- REPL-friendly for real-time testing

---

## Contributing

Areas to contribute to make this the definitive Ralph loop resource:

- ✅ More workflow patterns
- ✅ Additional example workflows
- ✅ Custom tool integrations
- ✅ Documentation improvements
- ✅ Error handling patterns
- ✅ Real-world case studies
- 🔄 Example implementations in `resources/examples/`
- 🔄 Generators in `skill/generators/`

---

## Roadmap

### Phase 1 (Current) ✅
- **Comprehensive documentation**: 7 spec files (~4,700 lines)
- **Pattern catalog**: 10 patterns with examples
- **Skill foundation**: Agent + tools
- **Template schemas**: YAML validation

### Phase 2 (Next)
- **Generators**: Auto-generate configs
- **Examples**: Complete workflow implementations
- **Testing**: End-to-end validation

### Phase 3 (Future)
- **Web UI builder**: Visual configuration tool
- **Pattern analyzer**: Auto-suggest based on task
- **More patterns**: Community contributions

---

## Acknowledgments

- The Ralph Wiggum technique community
- OpenCode team for extensibility
- Steve Yegge for Beads (1.7k stars)
- Everyone pushing the boundaries of agentic coding

---

## License

MIT

---

**Remember**: This isn't just one implementation - it's **the complete resource** for building Ralph loops. No matter what type of loop you need, everything you need to know is documented here.

**Question**: Not sure where to start? Begin with [`resources/specs/common-patterns.md`](resources/specs/common-patterns.md) to understand which pattern fits your needs!
