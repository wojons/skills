# Ralph Loop Error Handling Handbook

**Purpose**: Comprehensive error recovery strategies for Ralph loops - what can go wrong and how to handle it.

## Error Categories

### 1. Network Errors

#### Client Disconnection
**Scenario**: SSE stream disconnects unexpectedly

**Symptoms**:
- SSE `onerror` event fires
- No new events arriving
- Connection timeout

**Recovery Strategy**:
```typescript
async function reconnectWithBackoff(eventSource: EventSource): Promise<void> {
  const delays = [1000, 2000, 5000, 10000, 30000] // 1s, 2s, 5s, 10s, 30s
  
  for (const delay of delays) {
    try {
      await testConnection()
      reconnect()
      return // Success
    } catch (error) {
      console.warn(`Reconnection failed, retrying in ${delay}ms...`)
      await new Promise(resolve => setTimeout(resolve, delay))
    }
  }
  
  throw new Error('Could not reconnect after all retries')
}

async function testConnection(): Promise<void> {
  const response = await fetch('http://localhost:4096/global/health')
  if (!response.ok) throw new Error('Health check failed')
}
```

#### Request Timeout
**Scenario**: REST API call hangs

**Symptoms**:
- Promise never resolves
- No error, but also no response

**Recovery Strategy**:
```typescript
async function fetchWithTimeout<T>(url: string, timeoutMs: number = 30000): Promise<T> {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs)
  
  try {
    const response = await fetch(url, { signal: controller.signal })
    clearTimeout(timeoutId)
    return await response.json()
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new TimeoutError(`Request to ${url} timed out after ${timeoutMs}ms`, url)
    }
    throw error
  }
}
```

### 2. API Errors

#### Rate Limiting
**Scenario**: Too many requests to LLM provider

**Symptoms**:
- 429 Too Many Requests
- Rate limit exceeded error

**Recovery Strategy**:
```typescript
class RateLimitHandler {
  private lastRequest: number = 0
  private minInterval: number = 1000 // 1 second between requests
  
  async executeWithBackoff<T>(request: () => Promise<T>): Promise<T> {
    while (true) {
      const now = Date.now()
      const timeSinceLast = now - this.lastRequest
      
      if (timeSinceLast < this.minInterval) {
        await new Promise(resolve => setTimeout(resolve, this.minInterval - timeSinceLast))
      }
      
      try {
        this.lastRequest = Date.now()
        return await request()
      } catch (error) {
        if (isRateLimitError(error)) {
          const retryAfter = error.headers.get('Retry-After') || 5
          console.warn(`Rate limited, retrying after ${retryAfter}s`)
          await new Promise(resolve => setTimeout(resolve, retryAfter * 1000))
          continue
        }
        throw error
      }
    }
  }
}
```

#### Context Window Overflow
**Scenario**: Prompt + history exceeds model context limit

**Symptoms**:
- `Context overflow error`
- Token limit exceeded

**Recovery Strategy**:
```typescript
async function handleContextOverflow(session: RalphSession): Promise<void> {
  // Strategy 1: Compact history
  await session.compact()
  
  // Strategy 2: Remove old messages
  await session.trimHistory(maxMessages: 100)
  
  // Strategy 3: Switch strategy (less verbose prompts)
  session.strategy = 'minimal-logging'
  
  // Retry after recovery
  await session.runNextIteration()
}
```

### 3. Tool Execution Errors

#### Command Timeout
**Scenario**: Shell command hangs indefinitely

**Symptoms**:
- Command never completes
- No output received

**Recovery Strategy**:
```typescript
async function executeWithTimeout(
  command: string[],
  timeoutMs: number = 60000 // 1 minute default
): Promise<ExecResult> {
  const process = Bun.spawn(command, { stdout: 'pipe', stderr: 'pipe' })
  const timeout = setTimeout(() => process.kill('SIGKILL'), timeoutMs)
  
  try {
    const output = await process.exited
    clearTimeout(timeout)
    return { code: process.exitCode, output }
  } catch (error) {
    clearTimeout(timeout)
    throw new CommandTimeoutError(`Command timed out after ${timeoutMs}ms`, command.join(' '))
  }
}
```

#### Tool Not Available
**Scenario**: Required MCP tool or git hook not found

**Symptoms**:
- `Tool not available` error
- `Cannot find hook` error

**Recovery Strategy**:
```typescript
async function handleMissingTool(toolName: string, fallback?: string): Promise<void> {
  console.warn(`⚠️  Tool ${toolName} not available`)
  
  // Option 1: Skip and continue without tool
  if (fallback) {
    console.log(`  Using fallback: ${fallback}`)
    return
  }
  
  // Option 2: Error out if tool is required
  throw new RequiredToolNotFoundError(
    `Required tool ${toolName} not found. Please install: bun install ${toolName}`
  )
  
  // Option 3: Prompt user to install
  console.error(`  To use: bun install ${toolName}`)
  process.exit(1)
}
```

### 4. State Errors

#### Corrupted State File
**Scenario**: State JSON is invalid or corrupted

**Symptoms**:
- JSON parse error
- Can't read state file

**Recovery Strategy**:
```typescript
interface StateRecovery {
  shouldRetry: boolean
  recoveredFromBackup?: string
  defaultState?: any
}

async function recoverState(statePath: string): Promise<StateRecovery> {
  // Try 1: Parse main state file
  try {
    const content = fs.readFileSync(statePath, 'utf8')
    JSON.parse(content)
    return { shouldRetry: true }
  } catch (error) {
    if (!(error instanceof SyntaxError)) {
      throw error
    }
  }
  
  // Try 2: Restore from backup
  try {
    const backupPath = `${statePath}.backup`
    const content = fs.readFileSync(backupPath, 'utf8')
    JSON.parse(content)
    console.log(`✅ Recovered from backup: ${backupPath}`)
    return { shouldRetry: true, recoveredFromBackup: backupPath }
  } catch (error) {
    // Try 3: Use default state
    console.warn('No valid backup, using default state')
    return {
      shouldRetry: true,
      defaultState: { iteration: 0, status: 'initialized' }
    }
  }
}
```

#### State Conflict
**Scenario**: Multiple processes writing to same state file

**Symptoms**:
- File write conflicts
- Race conditions

**Recovery Strategy**:
```typescript
class StateManager {
  async atomicUpdate(statePath: string, update: (state: any) => any): Promise<void> {
    for (let attempt = 0; attempt < 10; attempt++) {
      try {
        // Read current state
        const content = fs.readFileSync(statePath, 'utf8')
        const currentState = JSON.parse(content)
        
        // Apply update
        const newState = update(currentState)
        
        // Write atomically
        const tempPath = `${statePath}.tmp.${Date.now()}`
        fs.writeFileSync(tempPath, JSON.stringify(newState, null, 2))
        fs.renameSync(tempPath, statePath)
        
        return // Success
      } catch (error) {
        if (error.code === 'ENOENT') {
          // File doesn't exist yet, create it
          const newState = update({ iteration: 0, status: 'initialized' })
          fs.writeFileSync(statePath, JSON.stringify(newState, null, 2))
          return
        }
        
        if (attempt === 9) {
          throw new StateConflictError('Failed to update state after 10 attempts')
        }
        
        // Wait before retrying
        await new Promise(resolve => setTimeout(resolve, 100 * Math.pow(2, attempt)))
      }
    }
  }
}
```

### 5. LLM Provider Errors

#### Provider Auth Failure
**Scenario**: Invalid or expired API credentials

**Symptoms**:
- 401 Unauthorized
- Invalid API key

**Recovery Strategy**:
```typescript
async function handleAuthError(): Promise<void> {
  // Option 1: Check if key exists
  const apiKey = process.env.OPENCODE_API_KEY
  
  if (!apiKey) {
    console.error('❌ OPENCODE_API_KEY not set')
    console.error('  Set it with: export OPENCODE_API_KEY=your_key')
    console.error('  Or configure in: ~/.opencode/config.json')
    throw new AuthError('API key not configured')
  }
  
  // Option 2: Verify key format
  if (!apiKey.startsWith('sk-') && !apiKey.startsWith('fp-')) {
    console.warn('⚠️  API key format may be incorrect')
  }
  
  // Option 3: Prompt for new key
  console.log('API key may be expired. Please refresh your credentials.')
  throw new AuthError('API key invalid or expired')
}
```

#### Model Unavailable
**Scenario**: Requested model is down or unavailable

**Symptoms**:
- `Model unavailable` error
- Service temporarily down

**Recovery Strategy**:
```typescript
class ModelFallback {
  private fallbackModels = [
    'anthropic/claude-sonnet-4-20250514',
    'openai/gpt-4o',
    'openai/gpt-4-turbo'
  ]
  
  async executeWithFallback<T>(
    model: string,
    request: (model: string) => Promise<T>
  ): Promise<T> {
    // Try requested model first
    try {
      return await request(model)
    } catch (error) {
      if (!this.isModelUnavailable(error)) {
        throw error
      }
    }
    
    // Try fallback models
    for (const fallback of this.fallbackModels) {
      try {
        console.log(`Model ${model} unavailable, trying ${fallback}...`)
        return await request(fallback)
      } catch (error) {
        if (!this.isModelUnavailable(error)) {
          throw error
        }
      }
    }
    
    throw new Error('No available models')
  }
  
  private isModelUnavailable(error: any): boolean {
    return (
      error.message?.includes('unavailable') ||
      error.message?.includes('temporarily down') ||
      error.code === 'MODEL_UNAVAILABLE'
    )
  }
}
```

### 6. Integration Errors

#### MCP Server Startup Failure
**Scenario**: MCP server won't start or crashes

**Symptoms**:
- Process exits with error code
- Server not responding

**Recovery Strategy**:
```typescript
async function startMCPServerWithRetry(command: string[], maxAttempts: number = 5): Promise<Process> {
  let lastError: Error
  
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      console.log(`Starting MCP server (attempt ${attempt + 1}/${maxAttempts})...`)
      
      const process = Bun.spawn(command, {
        stdout: 'pipe',
        stderr: 'pipe'
      })
      
      // Wait for it to be ready
      await this.waitForServerReady(process)
      
      return process
      
    } catch (error) {
      console.warn(`MCP server start failed: ${error.message}`)
      lastError = error
      
      if (attempt === maxAttempts - 1) {
        throw new MCPServerStartError(
          `Failed to start MCP server after ${maxAttempts} attempts`,
          lastError
        )
      }
      
      // Wait before retry
      await new Promise(resolve => setTimeout(resolve, 2000 * (attempt + 1)))
    }
  }
  
  private async waitForServerReady(process: Process, timeoutMs: number = 30000): Promise<void> {
    const startTime = Date.now()
    
    while (Date.now() - startTime < timeoutMs) {
      // Check if server is running
      const exited = process.exited
      
      if (await exited) {
        const exitCode = await process.exitCode
        const stderr = await process.stderr.text()
        throw new Error(`Server exited with code ${exitCode}: ${stderr}`)
      }
      
      // Health check
      try {
        const response = await fetch('http://localhost:8080/health')
        if (response.ok) return // Ready
      } catch {
        // Not ready yet
      }
      
      await new Promise(resolve => setTimeout(resolve, 500))
    }
    
    throw new TimeoutError('Server did not become ready')
  }
}
```

### 7. Data Errors

#### Malformed Response
**Scenario**: API returns invalid JSON or unexpected format

**Symptoms**:
- JSON parse error
- Type mismatch

**Recovery Strategy**:
```typescript
function safeParse<T>(json: string, fallback: T): T {
  try {
    return JSON.parse(json)
  } catch (error) {
    console.warn('JSON parse failed, using fallback:', error.message)
    return fallback
  }
}

// Usage in SSE event parsing
eventSource.onmessage = (event) => {
  try {
    const data = JSON.parse(event.data)
    processEvent(data)
  } catch (error) {
    // Log but don't crash
    console.error('Failed to parse SSE event:', error)
    console.error('  Raw data:', event.data)
    // Try to extract useful info or skip
  }
}
```

## Error Handling Patterns

### Pattern 1: Circuit Breaker

Prevent cascading failures by breaking the circuit after repeated failures:

```typescript
class CircuitBreaker {
  private failureCount = 0
  private lastFailureTime = 0
  private circuitOpen = false
  
  async execute<T>(
    operation: () => Promise<T>,
    threshold: number = 3,
    timeoutMs: number = 60000
  ): Promise<T> {
    // Check if circuit is open
    if (this.circuitOpen) {
      const timeSinceFailure = Date.now() - this.lastFailureTime
      
      if (timeSinceFailure < timeoutMs) {
        throw new CircuitBreakerOpenError('Circuit is open, blocking operation')
      } else {
        // Circuit expired, try closing it
        this.circuitOpen = false
        this.failureCount = 0
      }
    }
    
    try {
      return await operation()
    } catch (error) {
      this.failureCount++
      this.lastFailureTime = Date.now()
      
      if (this.failureCount >= threshold) {
        this.circuitOpen = true
        console.error('Circuit opened due to repeated failures')
      }
      
      throw error
    }
  }
}
```

### Pattern 2: Exponential Backoff with Jitter

Retry with increasing delays and random jitter:

```typescript
async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  maxAttempts: number = 5,
  baseDelayMs: number = 1000
): Promise<T> {
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await operation()
    } catch (error) {
      const delay = baseDelayMs * Math.pow(2, attempt)
      const jitter = Math.random() * delay * 0.1 // 10% jitter
      const waitTime = delay + jitter
      
      if (attempt === maxAttempts - 1) {
        throw new RetryExhaustedError(
          `Operation failed after ${maxAttempts} attempts`,
          error
        )
      }
      
      console.log(`Retry ${attempt + 1}/${maxAttempts} in ${waitTime.toFixed(0)}ms...`)
      await new Promise(resolve => setTimeout(resolve, waitTime))
    }
  }
  
  throw new Error('Should never reach here')
}
```

### Pattern 3: Fallback Chain

Try multiple alternatives before failing:

```typescript
async function withFallbacks<T>(...operations: (() => Promise<T>)[]): Promise<T> {
  const errors: Error[] = []
  
  for (const i in operations) {
    try {
      const operation = operations[i]
      return await operation()
    } catch (error) {
      console.warn(`Fallback ${i + 1} failed:`, error.message)
      errors.push(error)
    }
  }
  
  throw new AllFallbacksFailedError(
    `All ${operations.length} fallbacks failed`,
    errors
  )
}

// Usage
const result = await withFallbacks(
  () => fetchFromProvider1(),
  () => fetchFromProvider2(),
  () => fetchFromCache(),
  () => fetchFromDefault()
)
```

## Error Logging and Telemetry

### Structured Error Logging

```typescript
interface ErrorLog {
  timestamp: string
  errorType: string
  message: string
  stack?: string
  context?: any
  recovered: boolean
}

class ErrorLogger {
  private logs: ErrorLog[] = []
  private logPath = './ralph-errors.jsonl'
  
  log(error: Error, type: string, context?: any, recovered = false): void {
    const logEntry: ErrorLog = {
      timestamp: new Date().toISOString(),
      errorType: type,
      message: error.message,
      stack: error.stack,
      context,
      recovered
    }
    
    this.logs.push(logEntry)
    
    // Append to log file (JSONL format - one line per error)
    const logLine = JSON.stringify(logEntry) + '\n'
    fs.appendFileSync(this.logPath, logLine)
    
    console.error(`[${type}] ${error.message}`)
    if (context) {
      console.error('  Context:', JSON.stringify(context, null, 2))
    }
    console.error('  Recovered:', recovered ? 'Yes' : 'No')
  }
  
  getStats(): ErrorStats {
    const stats = {
      total: this.logs.length,
      byType: {} as Record<string, number>,
      recovered: 0,
      unrecovered: 0
    }
    
    for (const log of this.logs) {
      stats.byType[log.errorType] = (stats.byType[log.errorType] || 0) + 1
      if (log.recovered) stats.recovered++
      else stats.unrecovered++
    }
    
    return stats
  }
}
```

### Error Alerts and Notifications

```typescript
class ErrorAlerter {
  sendAlert(error: Error, level: 'warning' | 'error' | 'critical'): void {
    const message = `[${level.toUpperCase()}] ${error.message}`
    
    // Console alert
    if (level === 'critical') console.error(message)
    else if (level === 'error') console.error(message)
    else console.warn(message)
    
    // Webhook for monitoring systems
    this.sendWebhook({
      level,
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    })
  }
  
  private sendWebhook(payload: any): void {
    try {
      const webhookUrl = process.env.ERROR_WEBHOOK_URL
      if (!webhookUrl) return
      
      fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      }).catch(() => null) // Don't fail if webhook fails
    } catch (error) {
      // Silently ignore webhook errors
    }
  }
}
```

## Testing Error Recovery

When testing error handling:

```typescript
describe('Error Recovery', () => {
  it('should recover from SSE disconnection', async () => {
    // Mock disconnection
    const mockEventSource = {
      onmessage: () => {},
      onerror: () => {}
    }
    
    // Simulate reconnection
    const reconnected = await reconnectWithBackoff(mockEventSource)
    expect(reconnected).toBe(true)
  })
  
  it('should handle rate limiting with backoff', async () => {
    const handler = new RateLimitHandler()
    let requestCount = 0
    
    await handler.executeWithBackoff(async () => {
      requestCount++
      if (requestCount < 5) {
        throw new RateLimitError('Too many requests')
      }
      return 'success'
    })
    
    expect(requestCount).toBe(5)
  })
  
  it('should recover from corrupted state', async () => {
    // Write corrupted state
    fs.writeFileSync('.ralph/state.json', '{invalid json')
    
    const recovery = await recoverState('.ralph/state.json')
    expect(recovery.shouldRetry).toBe(true)
    expect(recovery.defaultState).toBeDefined()
  })
})
```

## Error Handling Checklist

When implementing Ralph loops, ensure you handle:

Network Errors:
- [ ] SSE reconnection with exponential backoff
- [ ] Request timeouts with abort controllers
- [ ] Connection pool limits
- [ ] Keep-alive management

API Errors:
- [ ] Rate limiting with Retry-After
- [ ] Context overflow with compaction
- [ ] Model fallback chains
- [ ] Auth failure with clear prompts

Tool Errors:
- [ ] Command timeout with kill
- [ ] Missing tools with fallbacks
- [ ] Tool availability checks
- [ ] Error response parsing

State Errors:
- [ ] Corrupted state recovery
- [ ] Atomic state updates
- [ ] Conflict resolution
- [ ] Backup and restore

Integration Errors:
- [ ] MCP server startup retry
- [ ] Health checks before use
- [ ] Startup order dependencies
- [ ] Shutdown cleanup

Data Errors:
- [ ] Safe JSON parsing
- [ ] Type validation
- [ ] Default values
- [ ] Error logging

## Common Error Types

```typescript
class RalphLoopError extends Error {
  constructor(
    message: string,
    public readonly type: 'network' | 'api' | 'tool' | 'state' | 'integration' | 'data' | 'llm'
  ) {
    super(message)
    this.name = 'RalphLoopError'
  }
}

class TimeoutError extends RalphLoopError {
  constructor(message: string, public readonly operation: string) {
    super(message, 'network')
    this.name = 'TimeoutError'
  }
}

class RateLimitError extends RalphLoopError {
  constructor(message: string, public readonly retryAfter?: number) {
    super(message, 'api')
    this.name = 'RateLimitError'
  }
}

class CommandTimeoutError extends RalphLoopError {
  constructor(message: string, public readonly command: string) {
    super(message, 'tool')
    this.name = 'CommandTimeoutError'
  }
}

// Add more as needed...
```

## Summary

Effective error handling is critical for robust Ralph loops:
- Use structured error types
- Implement retry with exponential backoff
- Add circuit breakers for cascading failures
- Log everything for debugging
- Test error recovery scenarios
- Provide clear error messages to users

See also:
- `testing-ralph-loops.md` - Testing error scenarios
- `integration-patterns.md` - Complete integration examples
