# Verified OpenCode SSE Event Types

## Overview

This document provides the **verified SSE event types** for OpenCode v1.2.10, extracted from the actual OpenAPI specification at `/doc?format=json`.

## SSE Event Format

All SSE events follow this format:

```
data: {"type":"event.type","properties":{...}}
```

Where:
- `type` is a constant string identifying the event type
- `properties` contains event-specific data

## Event Categories

### 1. Server Lifecycle Events

#### server.connected
Fired when a client connects to the SSE stream.

```json
{
  "type": "server.connected",
  "properties": {}
}
```

#### global.disposed
Fired when the server is shutting down.

```json
{
  "type": "global.disposed",
  "properties": {}
}
```

### 2. Message Events (CRITICAL for Ralph Loops)

#### message.updated
Fired when a message is updated/completed.

```json
{
  "type": "message.updated",
  "properties": {
    "info": {
      "id": "msg_abc123",
      "sessionID": "ses_xyz789",
      "role": "assistant",
      "time": {
        "created": 1771916688552,
        "completed": 1771916689000
      },
      "status": "complete",
      "tokens": {
        "in": 2345,
        "out": 8231
      }
    }
  }
}
```

**USE FOR COMPLETION DETECTION**: Check `info.status === "complete"` and parse `info.text` for promises like `<promise>TASK_COMPLETE</promise>`.

#### message.part.updated
Fired when a message part is updated.

```json
{
  "type": "message.part.updated",
  "properties": {
    "part": {
      "id": "prt_abc123",
      "messageID": "msg_xyz789",
      "sessionID": "ses_def456",
      "type": "text",
      "text": "I will build the authentication system..."
    }
  }
}
```

**USE FOR COMPLETION DETECTION**: Parse `part.text` for promise patterns like `<promise>COMPLETE</promise>`.

#### message.part.delta
Fired when a part field changes incrementally.

```json
{
  "type": "message.part.delta",
  "properties": {
    "sessionID": "ses_def456",
    "messageID": "msg_xyz789",
    "partID": "prt_abc123",
    "field": "text",
    "delta": "content delta"
  }
}
```

**USE FOR STREAMING**: Monitor streaming text output for patterns.

#### message.removed
Fired when a message is deleted.

```json
{
  "type": "message.removed",
  "properties": {
    "id": "msg_abc123"
  }
}
```

### 3. Part Types (Inside message.part.updated)

The `part` object can be one of these types:

| Part Type | Description | Key Fields for Ralph Loops |
|-----------|-------------|----------------------------|
| **TextPart** | Text content | `text` - check for promise patterns |
| **ReasoningPart** | AI reasoning | `text` - intermediate thoughts |
| **ToolPart** | Tool execution | `tool`, `status`, `output` |
| **StepStartPart** | Step开始 | `title`, `description` |
| **StepFinishPart** | Step完成 | `title`, `result.status` |
| **SnapshotPart** | State snapshot | Used for context |
| **PatchPart** | File patch | `file`, `diff` |
| **AgentPart** | Sub-agent | `agent`, `status` |
| **RetryPart** | Retry attempt | `iteration`, `reason` |
| **CompactionPart** | Compaction | Compaction status |

**EXAMPLE - TextPart**:
```json
{
  "type": "message.part.updated",
  "properties": {
    "part": {
      "id": "prt_abc123",
      "type": "text",
      "text": "I've completed the task.\n<promise>COMPLETE</promise>",
      "time": {"start": 1771916688552, "end": 1771916689000}
    }
  }
}
```

**EXAMPLE - ToolPart**:
```json
{
  "type": "message.part.updated",
  "properties": {
    "part": {
      "id": "prt_def456",
      "type": "tool",
      "tool": "bash",
      "command": "npm test",
      "status": "complete",
      "exitCode": 0,
      "output": "All tests passed"
    }
  }
}
```

### 4. Session Events

#### session.status
Fired when session status changes.

```json
{
  "type": "session.status",
  "properties": {
    "sessionID": "ses_abc123",
    "status": {
      "sessionID": "ses_abc123",
      "compacting": false,
      "compactingPaused": false,
      "activeMessageID": "msg_xyz789",
      "lastActivityAt": 1771916689000
    }
  }
}
```

#### session.created
Fired when a new session is created.

```json
{
  "type": "session.created",
  "properties": {
    "sessionID": "ses_abc123"
  }
}
```

#### session.updated
Fired when session metadata updates.

```json
{
  "type": "session.updated",
  "properties": {
    "session": {
      "id": "ses_abc123",
      "title": "Updated title",
      "slug": "new-slug",
      "version": "1.2.10"
    }
  }
}
```

#### session.compacted
Fired when session is compacted (context cleanup).

```json
{
  "type": "session.compacted",
  "properties": {
    "sessionID": "ses_abc123",
    "compact": {
      "messageIDs": ["msg_xyz789"]
    }
  }
}
```

#### session.idle
Fired when session becomes idle.

```json
{
  "type": "session.idle",
  "properties": {
    "sessionID": "ses_abc123"
  }
}
```

### 5. Tool/Command Events

#### command.executed
Fired when a command completes.

```json
{
  "type": "command.executed",
  "properties": {
    "name": "/run",
    "sessionID": "ses_abc123",
    "messageID": "msg_xyz789",
    "arguments": "test command"
  }
}
```

### 6. File Events

#### file.edited
Fired when a file is edited.

```json
{
  "type": "file.edited",
  "properties": {
    "path": "/path/to/file.ts",
    "directory": "/path/to"
  }
}
```

### 7. Error Events

#### session.error
Fired when a session error occurs.

```json
{
  "type": "session.error",
  "properties": {
    "sessionID": "ses_abc123",
    "error": {
      "message": "Error message",
      "code": "ERROR_CODE"
    }
  }
}
```

### 8. Todo Events

#### todo.updated
Fired when todo items are updated.

```json
{
  "type": "todo.updated",
  "properties": {
    "sessionID": "ses_abc123"
  }
}
```

## Ralph Loop Completion Detection

### Recommended Approach

1. **Monitor `message.part.updated` events**
   - Parse `part.text` when `part.type === "text"`
   - Look for patterns like `<promise>COMPLETE</promise>`
   - Check for completion keywords: "done", "finished", "complete"

2. **Monitor `message.updated` events**
   - Check `info.status === "complete"`
   - Parse completed message `info.text` for promises
   - Verify all tools executed successfully

3. **Fallback: Monitor ToolPart results**
   - Check `part.status === "complete"` for ToolPart
   - Verify `part.exitCode === 0`
   - Check `part.output` for success indicators

### Example: Parse SSE for Completion

```typescript
async function detectCompletion(): Promise<string | null> {
  const eventSource = new EventSource('http://localhost:4096/event')

  return new Promise((resolve) => {
    eventSource.addEventListener('message', (event) => {
      const data = JSON.parse(event.data)

      // Method 1: Check message.part.updated with text content
      if (data.type === 'message.part.updated' &&
          data.properties.part.type === 'text') {
        const text = data.properties.part.text || ''
        const match = text.match(/<promise>\s*(.*?)\s*<\/?promise>/)
        if (match) {
          resolve(match[1]) // "COMPLETE"
        }
      }

      // Method 2: Check message.updated status
      if (data.type === 'message.updated' &&
          data.properties.info.status === 'complete') {
        const text = data.properties.info.text || ''
        if (text.includes('<promise>COMPLETE</promise>')) {
          resolve('COMPLETE')
        }
      }

      // Method 3: Check ToolPart for failures
      if (data.type === 'message.part.updated' &&
          data.properties.part.type === 'tool' &&
          data.properties.part.status === 'error') {
        resolve('FAILED') // Or handle error
      }
    })

    // Timeout after reasonable time
    setTimeout(() => {
      eventSource.close()
      resolve(null)
    }, 60000)
  })
}
```

## SSE Endpoints

### /event
Subscribe to all events.

```bash
curl -N http://localhost:4096/event
```

### /global/event
Subscribe to global events (server-wide).

```bash
curl -N http://localhost:4096/global/event
```

### Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| directory | string | Filter by directory/project |

```bash
curl -N "http://localhost:4096/event?directory=/path/to/project"
```

## Unverified Events

The following events exist in the spec but have not been observed in real sessions:

- pty.created, pty.updated, pty.exited, pty.deleted
- worktree.ready, worktree.failed
- mcp.tools.changed, mcp.browser.open.failed
- lsp.client.diagnostics, lsp.updated
- tui.prompt.append, tui.command.execute, tui.toast.show, tui.session.select
- file.watcher.updated
- question.asked, question.replied, question.rejected

These may be UI-specific or require specific conditions to trigger.

## Verification Status

✅ **VERIFIED** - Extracted from OpenAPI 3.1.1 spec at `/doc?format=json`
- All event types listed are present in OpenCode v1.2.10 spec
- schemas match the documented structure
- Observed actual events: server.connected, message.part.updated

**Last Verified**: February 24, 2026
**OpenCode Version**: 1.2.10
