# Ralph Loop Integration Guide

**Purpose**: How to combine SSE monitoring, cost tracking, state persistence, and other patterns into production-ready Ralph loops.

## Overview

Individual patterns are useful, but real-world Ralph loops require **integrating multiple components**. This guide shows how to wire together the building blocks.

## Core Integration Patterns

### Pattern 1: SSE-Controlled Ralph Loop

Combine SSE event monitoring with loop control:

```typescript
import { EventSource } from 'eventsource'

class SSEControlledLoop {
  private eventSource: EventSource
  private running: boolean = false

  constructor(private sessionId: string, private baseUrl: string = 'http://localhost:4096') {
    this.eventSource = new EventSource(`${this.baseUrl}/event`)
  }

  async run(promptPath: string): Promise<void> {
    this.running = true

    // Set up SSE event handlers
    this.monitorEvents()
      .on('completion', (result) => {
        console.log('✅ Loop completed:', result)
        this.running = false
      })
      .on('error', (error) => {
        console.error('❌ SSE error:', error)
        this.handleReconnection()
      })
      .on('budget_exceeded', () => {
        console.warn('⚠️  Budget exceeded, stopping')
        this.running = false
      })

    // Run loop with SSE monitoring
    await Promise.all([
      this.executeRalphLoop(promptPath),
      this.monitorCost()
    ])
  }

  private monitorEvents() {
    this.eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data)

      // Detect completion from message.part.updated
      if (data.type === 'message.part.updated' &&
          data.properties.part?.text?.includes('<promise>COMPLETE</promise>')) {
        this.emit('completion', 'COMPLETE')
      }

      // Detect completion from message.updated
      if (data.type === 'message.updated' &&
          data.properties.info?.status === 'complete') {
        this.emit('completion', data.properties.info.text?.match(/<promise>\s*(.*?)\s*<\/?promise>/)?.[1])
      }

      // Detect tool failures
      if (data.type === 'message.part.updated' &&
          data.properties.part?.type === 'tool' &&
          data.properties.part?.status === 'error') {
        this.emit('tool_error', {
          tool: data.properties.part.tool,
          error: data.properties.part.output
        })
      }
    }

    this.eventSource.onerror = () => {
      console.error('SSE stream disconnected, reconnecting in 5s...')
      setTimeout(() => {
        if (this.running) {
          this.eventSource = new EventSource(`${this.baseUrl}/event`)
        }
      }, 5000)
    }
  }

  private emit(event: string, data: any) {
    // Simple pub/sub pattern
    this.eventSource.emit(event, data)
  }

  private async handleReconnection() {
    // Implement logic to recover from disconnection
    // Potentially replay missed events or verify current state
  }

  private async executeRalphLoop(promptPath: string): Promise<void> {
    // Implementation here...
    console.log('Executing Ralph loop with prompt:', promptPath)
    while (this.running) {
      // Execute iteration
      await new Promise(resolve => setTimeout(resolve, 1000))
    }
  }

  private async monitorCost(): Promise<void> {
    // Implementation here...
  }
}
```

**Key concepts:**
- SSE events control loop execution
- Reconnection logic with exponential backoff
- Event-driven completion detection
- Error handling for tool failures

### Pattern 2: Cost-Tracking Loop Control

Integrate cost tracking with loop flow control:

```typescript
interface BudgetConfig {
  maxCost: number
  warningThreshold: number
  stopOnExceed: boolean
}

class BudgetAwareLoop {
  private currentCost: number = 0
  private checkInterval: NodeJS.Timeout

  constructor(
    private sessionId: string,
    private config: BudgetConfig,
    private costTracker: CostTracker
  ) {}

  async runWithBudget(promptPath: string, loop: RalphLoop): Promise<void> {
    // Start cost monitoring
    this.startCostMonitoring()

    try {
      await loop.run(promptPath)

      // Check final cost vs budget
      if (this.currentCost > this.config.maxCost) {
        if (this.config.stopOnExceed) {
          throw new BudgetExceededError(
            `Cost ${this.currentCost} exceeded budget ${this.config.maxCost}`
          )
        }
      }
    } finally {
      // Cleanup
      this.stopCostMonitoring()
    }
  }

  private startCostMonitoring() {
    this.checkInterval = setInterval(async () => {
      this.currentCost = await this.costTracker.getSessionCost(this.sessionId)

      const progress = this.currentCost / this.config.maxCost

      // Warning threshold
      if (progress >= this.config.warningThreshold && progress < 1) {
        console.warn(
          `⚠️  Budget warning: $${this.currentCost.toFixed(2)} of $${this.config.maxCost}`
        )
      }

      // Budget exceeded
      if (progress >= 1) {
        this.emit('budget_exceeded', this.currentCost)
      }
    }, 5 * 60 * 1000) // Check every 5 minutes
  }

  private stopCostMonitoring() {
    if (this.checkInterval) {
      clearInterval(this.checkInterval)
    }
  }
}
```

**Key concepts:**
- Periodic cost checks vs. real-time monitoring
- Warning thresholds before hard stops
- Emit events for external listeners
- Cleanup on completion/failure

### Pattern 3: Multi-Step Integration (Build + Verify + Plan)

Combine three patterns into a cohesive workflow:

```typescript
class BuildVerifyPlanLoop {
  constructor(
    private builderAgent: Agent,
    private verifierAgent: Agent,
    private plannerAgent: Agent
  ) {}

  async run(task: string): Promise<Result> {
    let iteration = 0
    const maxIterations = 20

    while (iteration < maxIterations) {
      iteration++

      console.log(`\n=== Iteration ${iteration}/${maxIterations} ===`)

      // Step 1: Build phase
      console.log('🔨 Building...')
      const buildResult = await this.builderAgent.execute(task)

      if (!buildResult.success) {
        // Ask planner what to do
        const guidance = await this.plannerAgent.adjustStrategy(task, buildResult.error)
        console.log('📋 Planner guidance:', guidance.strategy)

        // Apply guidance to task
        task = this.updateTask(task, guidance)
        continue
      }

      // Step 2: Verify phase
      console.log('✓ Verifying...')
      const verifyResult = await this.verifierAgent.verify(buildResult.artifacts)

      if (!verifyResult.success) {
        const guidance = await this.plannerAgent.adjustStrategy(task, verifyResult.error)
        console.log('📋 Planner guidance:', guidance.strategy)
        task = this.updateTask(task, guidance)
        continue
      }

      // Success
      console.log('✅ Build + Verify succeeded!')
      return {
        success: true,
        iterations: iteration,
        artifacts: buildResult.artifacts
      }
    }

    // Max iterations reached
    return {
      success: false,
      reason: 'Max iterations exceeded',
      iterations: maxIterations
    }
  }

  private updateTask(task: string, guidance: Guidance): string {
    // Apply planner's guidance to the task
    // This could be prompting refinement, strategy change, etc.
    return `${task}\n\nGuidance: ${guidance.strategy}`
  }
}
```

**Key concepts:**
- Sequential pattern execution
- Fail-fast with planner intervention
- Dynamic task updates based on feedback
- Clear iteration tracking

### Pattern 4: State Persistence + Interruption Recovery

Graceful shutdown and state recovery:

```typescript
interface LoopState {
  sessionId: string
  iteration: number
  lastCheckpoint: string
  inProgressFiles: string[]
  currentTask: string
}

class PersistentLoop {
  private statePath = './.ralph/state.json'

  async run(task: string): Promise<void> {
    // Resume from interrupted state if exists
    const interruptedState = this.loadState()

    if (interruptedState) {
      console.log('🔄 Resuming from interrupted state:')
      console.log(`  Iteration: ${interruptedState.iteration}`)
      console.log(`  Task: ${interruptedState.currentTask}`)
      
      task = interruptedState.currentTask
      this.cleanupInProgress(interruptedState.inProgressFiles)
    }

    // Set up signal handlers for graceful shutdown
    this.setupInterruptHandlers()

    try {
      // Run loop with periodic state-saving
      await this.runLoop(task)
    } catch (error) {
      if (error instanceof InterruptedError) {
        console.log('⏸️  Interrupted, saving state...')
        this.saveState({
          sessionId: this.sessionId,
          iteration: this.currentIteration,
          lastCheckpoint: this.lastCheckpoint,
          inProgressFiles: this.getInProgressFiles(),
          currentTask: this.getCurrentTask()
        })
      }
      throw error
    }
  }

  private setupInterruptHandlers() {
    process.on('SIGINT', () => {
      throw new InterruptedError('User interrupted')
    })
    process.on('SIGTERM', () => {
      throw new InterruptedError('Process terminated')
    })
  }

  private loadState(): LoopState | null {
    try {
      const content = fs.readFileSync(this.statePath, 'utf8')
      return JSON.parse(content)
    } catch {
      return null
    }
  }

  private saveState(state: LoopState): void {
    const dir = path.dirname(this.statePath)
    fs.mkdirSync(dir, { recursive: true })
    fs.writeFileSync(this.statePath, JSON.stringify(state, null, 2))
    console.log('✅ State saved to', this.statePath)
  }

  private cleanupInProgress(files: string[]): void {
    files.forEach(file => {
      try {
        fs.unlinkSync(file)
        console.log('🗑️  Cleaned up:', file)
      } catch (error) {
        console.warn('Could not clean up file:', file, error.message)
      }
    })
  }

  private async runLoop(task: string): Promise<void> {
    // Implementation...
  }
}

class InterruptedError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'InterruptedError'
  }
}
```

**Key concepts:**
- Save state at checkpoints
- Load and resume from interrupted state
- Cleanup in-progress files
- Signal handling for graceful shutdown

## Tool Integration

### MCP Server Manager

Integrate MCP tools (searxng, browsers) with Ralph loops:

```typescript
class MCPServerManager {
  private servers: Map<string, Process> = new Map()

  async startServers(config: MCPConfig): Promise<void> {
    // Start SearXNG
    if (config.searxng) {
      const searxngProc = await this.startSearxng(config.searxng.url)
      this.servers.set('search', searxngProc)
      await this.waitForMCPReady('search', 'http://localhost:8080/health')
    }

    // Start Playwright browser
    if (config.playwright) {
      const playwrightProc = await this.startPlaywright()
      this.servers.set('playwright', playwrightProc)
      await this.waitForMCPReady('playwright')
    }

    // Start browser automation
    if (config.browser) {
      const browserProc = await this.startBrowser()
      this.servers.set('browser', browserProc)
      await this.waitForMCPReady('browser')
    }

    console.log('✅ All MCP servers started')
  }

  private async startSearxng(url: string): Promise<Process> {
    console.log('Starting SearXNG MCP server...')
    return Bun.spawn(['mcp-searxng', url], {
      env: { SEARXNG_URL: url }
    })
  }

  private async waitForMCPReady(server: string, healthUrl?: string): Promise<void> {
    console.log(`Waiting for ${server} to be ready...`)

    // Ping MCP server
    for (let i = 0; i < 30; i++) {
      try {
        await new Promise(resolve => setTimeout(resolve, 1000))
        // Assuming health check or ready signal
        console.log(`✅ ${server} ready`)
        return
      } catch (error) {
        if (i === 29) {
          throw new Error(`${server} failed to start`)
        }
      }
    }
  }

  async stopServers(): Promise<void> {
    console.log('Stopping MCP servers...')

    for (const [name, proc] of this.servers) {
      try {
        proc.kill()
        console.log(`�Stopped ${name}`)
      } catch (error) {
        console.warn(`Could not stop ${name}:`, error.message)
      }
    }

    this.servers.clear()
  }
}
```

**Key concepts:**
- Start and stop MCP servers in order
- Wait for servers to be ready
- Cleanup on failure/completion
- Health checks where available

### Git Hook Integration

Integrate git hooks as quality gates:

```typescript
class GitHookManager {
  private hooksPath = '.ralph/hooks'

  async executeHooks(stage: GitStage): Promise<boolean> {
    const hooks = this.getHooksForStage(stage)

    for (const hook of hooks) {
      console.log(`\n🪝 Running ${hook.name}...`)

      const result = await this.executeHook(hook)

      if (!result.approved) {
        console.error(`❌ ${hook.name} failed`)
        console.error(`  Message: ${result.message}`)

        if (block(stage, hook.severity)) {
          return false
        }
      }

      console.log(`✅ ${hook.name} passed`)
    }

    return true
  }

  private async executeHook(hook: GitHook): Promise<HookResult> {
    // Read hook instructions
    const content = fs.readFileSync(hook.path, 'utf8')

    // Execute hook as agent prompt
    const result = await this.executeAgent(content)

    // Check for approval
    const approved = result.includes('✓') || result.includes('approved')

    return {
      approved,
      message: result
    }
  }
}

function block(stage: GitStage, severity: 'error' | 'warning' | 'info'): boolean {
  if (severity === 'error') {
    return true // Always block on errors
  }

  if (stage === 'pre-push' && severity !== 'info') {
    return true // Block non-info on pre-push
  }

  return false
}
```

**Key concepts:**
- Execute hooks as agent prompts
- Check for approval patterns
- Block behavior based on severity and stage
- Pass/fail feedback

## Complete Production Examples

### Example 1: Full-Stack Ralph Loop

Combine SSE monitoring, cost tracking, state persistence, and MCP integration:

```typescript
class ProductionRalphLoop {
  private sseMonitor: SSEControlledLoop
  private budgetTracker: BudgetAwareLoop
  private mcpServers: MCPServerManager
  private gitHooks: GitHookManager

  constructor(
    config: ProductionConfig
  ) {
    this.sseMonitor = new SSEControlledLoop(config.sessionId, config.serverUrl)
    this.budgetTracker = new BudgetAwareLoop(
      config.sessionId,
      config.budget,
      config.costTracker
    )
    this.mcpServers = new MCPServerManager(config.mcp)
    this.gitHooks = new GitHookManager()
  }

  async run(task: string): Promise<void> {
    try {
      // 1. Start MCP servers
      await this.mcpServers.startServers()

      // 2. Run git hooks for pre-commit checks
      const hooksPassed = await this.gitHooks.executeHooks('pre-commit')
      if (!hooksPassed) {
        throw new Error('Pre-commit hooks failed, aborting')
      }

      // 3. Execute Ralph loop with all integrations
      await this.budgetTracker.runWithBudget(task, this.sseMonitor)

      console.log('✅ Ralph loop completed successfully')

    } finally {
      // 4. Cleanup MCP servers
      await this.mcpServers.stopServers()
    }
  }
}

// Usage
const config: ProductionConfig = {
  sessionId: 'ses_abc123',
  serverUrl: 'http://localhost:4096',
  budget: {
    maxCost: 50.0,
    warningThreshold: 0.8,
    stopOnExceed: true
  },
  mcp: {
    searxng: { url: 'http://localhost:8080' },
    playwright: true,
    browser: true
  },
  costTracker: new CostTracker()
}

const loop = new ProductionRalphLoop(config)
await loop.run('Build authentication system with JWT tokens')
```

**This example shows:**
- Complete integration of 5 major components
- Error handling and cleanup
- Resource management
- Production-ready patterns

## Integration Checklist

When combining patterns, consider:

- [ ] Startup order (what needs to start first?)
- [ ] Shutdown order (what needs to stop last?)
- [ ] Error propagation (how do errors flow through?)
- [ ] State synchronization (how do components share state?)
- [ ] Resource cleanup (what needs to be freed?)
- [ ] Signal handling (how do we handle interruption?)
- [ ] Retry logic (what should be retried?)
- [ ] Monitoring (how do we observe runtime?)
- [ ] Testing (how do we test integrations?)
- [ ] Documentation (how do we document the combined system?)

## Common Integration Pitfalls

### Pitfall 1: Circular Dependencies
**Problem**: Component A depends on B, B depends on A
**Solution**: Introduce intermediate abstraction or event mediator

```typescript
// Good pattern
class EventMediator {
  on(event: string, handler: Function) { /* ... */ }
  emit(event: string, data: any) { /* ... */ }
}

// Both components depend on mediator, not each other
```

### Pitfall 2: Blocking the Event Loop
**Problem**: Synchronous operations block async patterns
**Solution**: Use Promise.all() and non-blocking I/O

```typescript
// Good pattern
await Promise.all([
  componentA.start(),
  componentB.start(),
  componentC.start()
])
```

### Pitfall 3: Unhandled Promise Rejections
**Problem**: Async errors swallow exceptions
**Solution**: Global error handlers and try/catch

```typescript
process.on('unhandledRejection', (error) => {
  console.error('Unhandled promise rejection:', error)
  process.exit(1)
})
```

### Pitfall 4: Resource Leaks
**Problem**: Processes, sockets, files not cleaned up
**Solution:** Use finally blocks and cleanup on interruption

```typescript
try {
  await process.run()
} finally {
  await cleanup()
}
```

## Testing Integrated Systems

When testing integrations:

1. Unit test each component
2. Integration test components together
3. End-to-end test with mock external services
4. Performance test with realistic workloads
5. Chaos test for failure scenarios

Example test pattern:
```typescript
describe('Production Ralph Loop', () => {
  it('should complete with SSE monitoring', async () => {
    const loop = new ProductionRalphLoop(testConfig)
    await loop.run('Test task')
    expect(loop.completed).toBe(true)
  })

  it('should stop on budget exceeded', async () => {
    const loop = new ProductionRalphLoop({
      budget: { maxCost: 0.1, stopOnExceed: true },
      // ...
    })
    await loop.run('Expensive task')
    expect(loop.stoppedDueToBudget).toBe(true)
  })
})
```

## Next Steps

To build integrated Ralph loops:

1. Start with SSE-controlled loop (foundation)
2. Add cost monitoring for budget awareness
3. Integrate MCP tools as needed
4. Add state persistence for reliability
5. Use git hooks for quality gates
6. Test integrations thoroughly

See also:
- `sse-events-verified.md` - SSE event details
- `rest-api-verified.md` - OpenCode server integration
- `error-handling.md` - Error recovery strategies
- `testing-ralph-loops.md` - Testing strategies
