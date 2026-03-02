# Ralph Loop UI & Monitoring

## Overview

Ralph loops can run for hours or even overnight. A monitoring UI is essential for:

- **Tracking progress**: See which step/iteration you're on
- **Debugging failures**: View error logs and context
- **Cost management**: Watch token usage and API costs
- **Safety**: Have emergency controls (stop, pause, resume)
- **Visibility**: Understand what's happening vs what should happen

## UI Patterns

### 1. Terminal-Based Dashboard (TUI)

For terminal users, a text-based dashboard using libraries like `blessed` or `ink`:

```
┌──────────────────────────────────────────────────────────────┐
│                    Ralph Loop Monitor                        │
├──────────────────────────────────────────────────────────────┤
│ Status: Running │ Iteration: 12/20 │ Cost: $23.45            │
├──────────────────────────────────────────────────────────────┤
│ Current Step: Implementation (Builder Agent)                  │
│──────────────────────────────────────────────────────────────│
│                                                              │
│ Progress: ████████████░░░░░░░░░░░ 60%                        │
│                                                              │
│ Recent Activity:                                             │
│  ✓ Designed database schema                                 │
│  ✓ Created user models (retry 1)                             │
│  → Building login endpoint (3m ago)                         │
│  ⏳ Building registration endpoint                          │
│  ⏳ Writing tests                                           │
│                                                              │
│ Last Messages: [Space] Refresh [Q] Quit [S] Stop [P] Pause   │
│──────────────────────────────────────────────────────────────│
│ Builder Agent > Building login endpoint...                   │
│                                                              │
│ > src/auth/login.ts - Added authentication                   │
│ > src/auth/login.ts - Added error handling                   │
│ > npm test - Running tests...                                │
│                                                              │
│ [Press Space for more]                                       │
└──────────────────────────────────────────────────────────────┘
```

**Features:**
- Real-time iteration counter
- Cost estimation
- Current step indicator
- Progress bar
- Activity log
- Emergency controls (stop, pause)
- Agent output viewer

### 2. Web Dashboard

HTML/React dashboard served via `opencode serve`:

```typescript
// Web UI Components
import { createDashboard } from 'ralph-dashboard-ui'

const dashboard = createDashboard({
  theme: 'dark',
  refreshInterval: 1000, // 1 second
  
  panels: [
    {
      id: 'status',
      type: 'status-card',
      data: ['status', 'iteration', 'cost', 'time_remaining']
    },
    {
      id: 'workflow',
      type: 'mermaid-diagram',
      data: 'workflow_diagram'
    },
    {
      id: 'activity', 
      type: 'log-viewer',
      data: 'recent_activity'
    },
    {
      id: 'agents',
      type: 'agent-status',
      data: 'all_agents'
    }
  ]
})
```

**Dashboard Layout:**
```
┌────────────────────────────────────────────────────────────┐
│ 🟢 Ralph Loop Monitor                    [Stop] [Pause]     │
├────────────────────────────────────────────────────────────┤
│ Status     │ Iteration │ Cost       │ Time          │      │
│ Running    │ 12/20     │ $23.45     │ 1h 45m        │      │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  Workflow Diagram              Recent Activity              │
│                              ┌─────────────────┐            │
│  ┌─────┐    ┌─────┐        │ ✓ Design        │            │
│  │Plan │───>│Build │       │ ✓ Models        │            │
│  └─────┘    └─────┘        │ → Login         │            │
│      │         │           │ ⏳ Register     │            │
│      v         v           │ ⏳ Tests        │            │
│  ┌─────┐    ┌─────┐       └─────────────────┘            │
│  │Verify│    │Plan │                                          │
│  └─────┘    └─────┘                                          │
│                                                              │
│  Agent Status                                                │
│  ┌────────────────────────────────┐                          │
│  │ Builder                        │                          │
│  │ Status: 🔄 Active              │                          │
│  │ Task: Building login endpoint │                          │
│  │ Time: 3m 12s                   │                          │
│  │ Tokens: 15,345                 │                          │
│  └────────────────────────────────┘                          │
│                                                              │
│  ┌────────────────────────────────┐                          │
│  │ Verifier                       │                          │
│  │ Status: ⏸️ Waiting            │                          │
│  │ Last: Checked models (OK)      │                          │
│  └────────────────────────────────┘                          │
└────────────────────────────────────────────────────────────┘
```

### 3. VS Code Extension

VS Code extension for Ralph loops:

```json
{
  "contributes": {
    "views": {
      "ralph-monitor": [
        {
          "id": "ralphStatus",
          "name": "Status"
        },
        {
          "id": "ralphWorkflow",
          "name": "Workflow"
        },
        {
          "id": "ralphAgents",
          "name": "Agents"
        },
        {
          "id": "ralphLogs",
          "name": "Logs"
        }
      ]
    },
    "commands": [
      {
        "command": "ralph.start",
        "title": "Start Ralph Loop"
      },
      {
        "command": "ralph.stop",
        "title": "Stop Ralph Loop"
      },
      {
        "command": "ralph.pause",
        "title": "Pause Loop"
      }
    ]
  }
}
```

**Features:**
- Side panel status indicator (running, paused, stopped)
- Inline error highlighting
- Click to jump to errors
- Git diff integration for changes
- Terminal-like status view

## Real-Time Monitoring

### SSE Streaming

Using OpenCode's SSE endpoint to stream events:

```typescript
// OpenCode SSE endpoints: /event (session events) or /global/event (global events)
const eventSource = new EventSource('http://localhost:4096/event')

eventSource.addEventListener('message', (event) => {
  const data = JSON.parse(event.data)
  updateUI({
    type: 'message',
    agent: data.agent,
    content: data.content
  })
})

eventSource.addEventListener('state', (event) => {
  const data = JSON.parse(event.data)
  updateUI({
    type: 'state_change',
    agent: data.agent,
    state: data.state
  })
})

eventSource.addEventListener('tool', (event) => {
  const data = JSON.parse(event.data)
  updateUI({
    type: 'tool',
    tool: data.tool,
    status: data.status
  })
})

eventSource.addEventListener('error', (event) => {
  const data = JSON.parse(event.data)
  updateUI({
    type: 'error',
    message: data.message
  })
})
```

### WebSocket Alternative

For bidirectional communication (control commands):

```typescript
// Use OpenCode's /event SSE endpoint for real-time updates
const eventSource = new EventSource('http://localhost:4096/event')

// To control the session, use the REST API instead:
POST /session/:id/stop
// or openapi command line

// Receive updates
eventSource.addEventListener('message', (event) => {
  const data = JSON.parse(event.data)
  handleUpdate(data)
})
```

## State API

OpenCode provides REST APIs for programmatic monitoring.

**Get session status:**
```bash
GET /session/:id/status
```
Returns session status, time_compacting, iteration counts.

**Get messages:**
```bash
GET /session/:id/message?limit=50
```
Returns messages and parts for a session.

**Get sessions list:**
```bash
GET /session
```
Returns all sessions with metadata.

Example response:
```typescript
// GET /session/:id/status
{
  "id": "ses_abc123",
  "running": true,
  "time_compacting": 6321,
  "time_remaining": 1800,
}
{
  "logs": [
    {
      "timestamp": "2026-02-24T10:23:45Z",
      "level": "info",
      "agent": "builder",
      "message": "Started building login endpoint"
    },
    {
      "timestamp": "2026-02-24T10:25:12Z",
      "level": "error",
      "agent": "builder", 
      "message": "Database connection failed"
    },
    ...
  ]
}

// GET /api/ralph/history
{
  "iterations": [
    {
      "id": 1,
      "status": "completed",
      "result": "<promise>DESIGN_COMPLETE</promise>",
      "duration_ms": 45000,
      "tokens": 3500
    },
    {
      "id": 2,
      "status": "completed", 
      "result": "<promise>MODELS_COMPLETE</promise>",
      "duration_ms": 52000,
      "tokens": 4200
    }
  ]
}
```

## Control Commands

OpenCode exposes control commands via REST API:

**Stop a session:**
```bash
POST /session/:id/abort
```

**Get diff:**
```bash
GET /session/:id/diff?messageId=<id>
```

**Share session:**
```bash
POST /session/:id/share
```

**Fork session at a message:**
```bash
POST /session/:id/fork
```

See OpenCode server API docs for complete endpoint list:
```bash
# Get OpenAPI spec JSON
curl http://localhost:4096/doc.json
```

## Visual Workflow Diagrams

### Mermaid.js Integration

Render Mermaid diagrams from PROMPT.md:

```html
<div id="workflow-diagram"></div>
<script>
  import mermaid from 'mermaid'
  
  // Parse PROMPT.md
  const prompt = await fetch('/docs/PROMPT.md')
    .then(r => r.text())
    
  // Extract mermaid code block
  const match = prompt.match(/```mermaid\n([\s\S]*?)\n```/)
  const diagram = match[1]
  
  // Render
  mermaid.render('workflow-diagram', diagram)
    .then(svg => {
      document.getElementById('workflow-diagram').innerHTML = svg
    })
</script>
```

### Step Visualization

Visualize steps as boxes with status:

```typescript
function renderWorkflow(steps: WorkflowStep[]) {
  return (
    <div className="workflow">
      {steps.map((step, i) => (
        <div key={i} className="workflow-step">
          <div className={`step-status ${getStatusClass(step.status)}`}>
            {step.status}
          </div>
          <div className="step-name">{step.name}</div>
          <div className="step-iteration">
            Attempt {step.iteration} of {step.maxIterations}
          </div>
          {step.status === 'error' && (
            <div className="step-error">
              {step.lastError}
            </div>
          )}
        </div>
      ))}
    </div>
  )
}
```

## Cost Monitoring

Track token usage and costs:

```typescript
interface CostTracker {
  totalCost: number
  currentCost: number
  estimatedCompletionCost: number
  
  agents: {
    [name: string]: {
      tokensIn: number
      tokensOut: number
      cost: number
    }
  }
  
  predictions: {
    remainingIterations: number
    estimatedCost: number
    estimatedTime: number
  }
}

function calculateCost(iteration: number, history: Iteration[]): CostTracker {
  // Calculate costs based on usage
  const avgCostPerIteration = history.reduce((sum, h) => sum + h.cost, 0) / history.length
  
  const remaining = maxIterations - iteration
  const estimated = avgCostPerIteration * remaining
  
  return {
    totalCost: history.reduce((sum, h) => sum + h.cost, 0),
    currentCost: history[iteration]?.cost || 0,
    estimatedCompletionCost: estimated + totalCost,
    // ... agent breakdown
  }
}
```

## Alerting & Notifications

Alerts for important events:

```typescript
const alerts = {
  onMaxIterations: (iteration) => {
    console.warn(`⚠️  Approaching max iterations: ${iteration}`)
    webhook.send({
      level: 'warning',
      message: `Loop iteration ${iteration}/${maxIterations}`
    })
  },
  
  onCostExceeded: (cost, expected) => {
    console.error(`💰 Cost exceeded: $${cost} (expected $${expected})`)
    webhook.send({
      level: 'error',
      message: `Cost overrun detected`
    })
  },
  
  onFailureLoop: (failures) => {
    if (failures.length > 3) {
      console.error(`❌ Failure loop detected`)
      stopLoop('Failure loop')
    }
  },
  
  onSuccess: (result) => {
    console.log(`✅ Ralph loop completed: ${result}`)
    webhook.send({
      level: 'info',
      message: `Ralph loop successful`
    })
  }
}
```

## Example: Complete Monitor Implementation

See `skill/ui/monitor/` for complete implementation:
- TUI terminal dashboard
- Web dashboard with React
- SSE event streaming
- API endpoints
- Cost tracking
- Alert system

## Choosing Your UI

| UI Type | Best For | Complexity |
|---------|----------|------------|
| TUI | Terminal power users | Low |
| Web Dashboard | Visualization & control | High |
| VS Code Extension | IDE integration | Medium |
| CLI | Simple monitoring | Very Low |

## Best Practices

1. **Always have a stop button**: No matter what, let users stop the loop
2. **Show iteration count prominently**: Can't hide costs
3. **Display cost estimates**: Users need to know current spend
4. **Log everything**: Hard to debug without logs
5. **Color code status**: Easy to scan quickly
6. **Show progress**: Progress bars for long-running tasks
7. **Auto-scroll logs**: Don't make users scroll manually
8. **Save state checkpoints**: Can resume if interrupted
