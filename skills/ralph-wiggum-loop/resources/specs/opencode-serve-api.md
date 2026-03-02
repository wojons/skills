# OpenCode Server API

## Overview

`opencode serve` starts an HTTP server that provides:
- Real-time session management
- SSE (Server-Sent Events) streaming
- API documentation via `/doc?format=json`
- Full programmatic control over OpenCode

**⚠️ Note**: This documentation was verified against OpenCode v1.2.10. API may change between versions.

## Getting Started

```bash
# Start the server
opencode serve --port 4096

# Get health check
curl http://localhost:4096/global/health

# Get OpenAPI spec JSON
curl http://localhost:4096/doc?format=json | jq

# Access the web UI
open http://localhost:4096
```

## Verified Endpoints

### `/doc?format=json` - OpenAPI Specification
Returns the OpenAPI 3.1.1 specification for the server in JSON format.

**Note**: The `/doc.json` endpoint returns HTML; use `/doc?format=json` for JSON.

```bash
# Get OpenAPI spec JSON
curl http://localhost:4096/doc?format=json | jq > openapi-spec.json
```

**Verified response format**:
```json
{
  "openapi": "3.1.1",
  "info": {
    "title": "opencode",
    "description": "opencode api",
    "version": "0.0.3"
  },
  "paths": {
    "/global/health": { ... },
    "/session": { ... },
    ...
  }
}
```

**Use case**:
- Programmatically discover endpoints
- Generate SDKs
- Stay current with OpenCode changes

### `/global/health` - Health Check
Returns server status and version.

```bash
curl http://localhost:4096/global/health
```

**Verified response**:
```json
{
  "healthy": true,
  "version": "1.2.10"
}
```

### `/event` and `/global/event` - SSE Streams
Server-Sent Events provide real-time updates.

### SSE Streams
Server-Sent Events provide real-time updates about:
- Message completions
- Agent state changes
- Tool execution
- Session events

**Stream format**:
```text
data: {"type":"server.connected"}

data: {"type":"message","content":"..."}

data: {"type":"error","message":"..."}
```

**⚠️ Note**: Exact SSE event types and formats should be verified using the actual SSE stream or OpenAPI spec at `/doc?format=json`.

## REST API Endpoints

### Sessions
```bash
# List all sessions
GET /session

# Get session status
GET /session/status

# Get session details
GET /session/:id

# Create a new session
POST /session

# Update session properties
PATCH /session/:id

# Delete a session
DELETE /session/:id
```

### Messages
```bash
# List messages in a session
GET /session/:id/message

# Send a message
POST /session/:id/message

# Get message details
GET /session/:id/message/:messageID
```

### Files
```bash
# Search for text in files
GET /find?pattern=<pattern>

# Find files by name
GET /find/file?query=<query>

# Get file content
GET /file/content?path=<path>

# List files
GET /file?path=<path>
```

## Ralph Loop Integration

For Ralph loops, the server is ideal because:

1. **Easy Parsing**
   - Each SSE event is discrete JSON
   - No need to interpret terminal output
   - Easy to detect state changes

2. **Stop Condition Detection**
   ```javascript
   // Detect completion promise in message content
   const events = await fetch('/event')
   const reader = events.body.getReader()

   while (true) {
     const { value } = await reader.read()
     const lines = new TextDecoder().decode(value).split('\n')
     for (const line of lines) {
       if (line.startsWith('data: ')) {
         const event = JSON.parse(line.slice(6))
         if (event.content?.includes('<promise>COMPLETE</promise>')) {
           // Stop loop
           break
         }
       }
     }
   }
   ```

3. **API Spec Discovery**
   ```javascript
   // Get OpenAPI spec at runtime
   const spec = await fetch('/doc?format=json').then(r => r.json())

   // Find sessions endpoint
   const sessionPath = Object.keys(spec.paths).find(p => p.includes('/session'))

   // Use it to interact dynamically
   ```

## Architecture for Ralph Loops

```
┌─────────────┐
│  opencode   │
│   serve     │
└──────┬──────┘
        │
        ├──> /doc?format=json (OpenAPI spec - VERIFIED)
        ├──> /global/health (Health check - VERIFIED)
        ├──> /event (SSE stream - VERIFIED)
        │
        ├──> REST API
        │     ├── /session (List/create)
        │     ├── /session/:id (Get/update/delete)
        │     ├── /session/:id/message (List/send)
        │     ├── /find?pattern=... (Search)
        │     └── /file?path=... (File operations)
        │
        └──> Web UI
```

## Best Practices

1. **Always verify spec first**
   - Don't hardcode endpoints
   - Fetch `/doc.json` for current version
   - Spec may change between versions

2. **Handle SSE gracefully**
   - Reconnect on disconnect
   - Buffer partial messages
   - Parse JSON with error handling

3. **HTTP Authentication**
   - Set `OPENCODE_SERVER_PASSWORD` for protection
   - Username defaults to `opencode`
   - Use HTTP Basic Auth

## Example: Complete Loop Workflow

```javascript
// 1. Start server (or check if already running)
const server = await startOrConnectServer()

// 2. Get OpenAPI spec
const spec = await fetch('/doc?format=json').then(r => r.json())

// Find sessions endpoint
const sessionPath = Object.keys(spec.paths).find(p => p.includes('/session'))

// Use it to interact dynamically
```

---

## Verification Disclaimer

**The following endpoints have been verified against OpenCode v1.2.10**:
- ✅ `/doc.json` - Returns OpenAPI 3.1.1 spec
- ✅ `/global/health` - Returns health status and version
- ✅ `/event` - SSE event stream
- ✅ `/global/event` - Global SSE events
- ✅ REST endpoints listed in OpenAPI spec (sessions, messages, files, etc.)

**The following need verification or may differ**:
- ⚠️ Exact SSE event types and field names
- ⚠️ Specific error response formats
- ⚠️ All optional query parameters

To verify endpoints for your OpenCode version:
```bash
curl http://localhost:4096/doc?format=json | jq '.paths' | keys
```
