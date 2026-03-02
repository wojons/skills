# OpenCode REST API - Verified Endpoints

**Verification Status**: Verified endpoints tested against OpenCode v1.2.10
**Last Tested**: February 24, 2026

## Correct Endpoint Patterns

Critical pattern rules for OpenCode REST API:

1. **Session endpoints use `/session/{sessionID}`** (NOT `/sessions/{id}`)
2. **Message endpoints use `/session/{sessionID}/message`** (NOT `/session/:id/message`)
3. **Parameters match OpenAPI schema exactly**
4. **Path spaces must be URL-encoded** (`/path/to/file` → `%2Fpath%2Fto%2Ffile`)

## Verified Sessions API

### List All Sessions
```bash
GET /session
```

Example:
```bash
curl http://localhost:4096/session
```

Returns:
```json
[
  {
    "id": "ses_abc123",
    "slug": "test-session",
    "projectID": "global",
    "directory": "/path/to/project",
    "title": "Test Session",
    "version": "1.2.10",
    "summary": {
      "additions": 100,
      "deletions": 0,
      "files": 5
    }
  }
]
```

### Get Single Session
```bash
GET /session/{sessionID}
```

Example:
```bash
curl http://localhost:4096/session/ses_abc123
```

### Get Session Status
```bash
GET /session/status
```

Example:
```bash
curl http://localhost:4096/session/status
```

Returns all session statuses.

## Verified Messages API

### Get Session Messages
```bash
GET /session/{sessionID}/message?limit=N
```

Example:
```bash
curl "http://localhost:4096/session/ses_abc123/message?limit=10"
```

Returns:
```json
[
  {
    "info": {
      "id": "msg_xyz789",
      "sessionID": "ses_abc123",
      "role": "assistant",
      "modelID": "model:identifier",
      "providerID": "provider",
      "agent": "build",
      "cost": 0.1234,
      "tokens": {
        "input": 1234,
        "output": 5678
      }
    },
    "parts": [
      {
        "type": "text",
        "text": "Message content...",
        "id": "prt_pqr456",
        "sessionID": "ses_abc123",
        "messageID": "msg_xyz789"
      }
    ]
  }
]
```

### Get Single Message
```bash
GET /session/{sessionID}/message/{messageID}
```

Example:
```bash
curl "http://localhost:4096/session/ses_abc123/message/msg_xyz789"
```

## Verified Files API

### Find Files by Name
```bash
GET /find/file?query=<search>
```

Example:
```bash
curl "http://localhost:4096/find/file?query=PROMPT"
```

Returns array of paths.

### Search Text in Files
```bash
GET /find?pattern=<pattern>&directory=<path>
```

Example:
```bash
curl "http://localhost:4096/find?pattern=promise&directory=/path/to/project"
```

Returns:
```json
[
  {
    "path": {
      "text": "/path/to/file.md"
    },
    "lines": {
      "text": "I found a promise here\n"
    },
    "line_number": 42,
    "absolute_offset": 1024,
    "submatches": [
      {
        "match": {
          "text": "promise"
        },
        "start": 5,
        "end": 12
      }
    ]
  }
]
```

### Get File Content
```bash
GET /file?path=<path> OR GET /file/content?path=<path>
```

**IMPORTANT**: Path must be URL-encoded (spaces become `%20`, `/` becomes `%2F`)

Example (Python):
```python
import urllib.parse
encoded_path = urllib.parse.quote('/path/to/file.md', safe='')
url = f"http://localhost:4096/file?path={encoded_path}"
```

Example (curl):
```bash
curl "http://localhost:4096/file?path=%2FUsers%2Fusername%2Fproject%2FREADME.md"
```

## Unverified Endpoints

The following endpoints exist in the OpenAPI spec but have NOT been tested:

### Session Operations
- `POST /session` - Create new session
- `PATCH /session/{sessionID}` - Update session properties
- `DELETE /session/{sessionID}` - Delete session
- `GET /session/{sessionID}/children` - Get child sessions
- `GET /session/{sessionID}/todo` - Get session todo list
- `POST /session/{sessionID}/init` - Initialize session with AGENTS.md
- `POST /session/{sessionID}/fork` - Fork session at message ID
- `POST /session/{sessionID}/abort` - Abort running session
- `POST /session/{sessionID}/share` - Share session
- `DELETE /session/{sessionID}/share` - Unshare session
- `GET /session/{sessionID}/diff` - Get session diff
- `POST /session/{sessionID}/summarize` - Summarize session
- `POST /session/{sessionID}/revert` - Revert message
- `POST /session/{sessionID}/unrevert` - Restore reverted messages

### Message Operations
- `POST /session/{sessionID}/message` - Send message (synchronous)
- `POST /session/{sessionID}/prompt_async` - Send message (asynchronous)
- `GET /session/{sessionID}/message/{messageID}/part/{partID}` - Get part details

### Command Shell Operations
- `POST /session/{sessionID}/command` - Execute slash command
- `POST /session/{sessionID}/shell` - Run shell command
- `POST /session/{sessionID}/permissions/{permissionID}` - Respond to permission

### LSP & MCP
- `GET /lsp` - Get LSP server status
- `GET /mcp` - Get MCP server status
- `POST /mcp` - Add MCP server dynamically

### Commands
- `GET /command` - List all slash commands

### Config
- `GET /config` - Get config info
- `PATCH /config` - Update config
- `GET /config/providers` - List providers

### Project
- `GET /project` - List all projects
- `GET /project/current` - Get current project

### Global
- `GET /global/health` - Server health (✅ verified)
- `GET /global/event` - Global SSE events (✅ verified)

### File Operations
- `GET /file?path=<path>` - List files (✅ verified)
- `GET /file/content?path=<path>` - Read file content
- `GET /file/status` - Get file status

### Tools
- `GET /experimental/tool/ids` - List all tool IDs
- `GET /experimental/tool?provider=<p>&model=<m>` - List tools

## Common Patterns

### Session ID Pattern
- Format: `ses_` + alphanumeric string
- Example: `ses_371890357ffe3dO4v67svWIPc9`

### Message ID Pattern
- Format: `msg_` + alphanumeric string
- Example: `msg_c8ed0c7ef001x3GtlTVGMncz4u`

### Part ID Pattern
- Format: `prt_` + alphanumeric string
- Example: `prt_c8ed0cebd002AKr31XpoxYNomo`

## URL Encoding Guidelines

**Always URL-encode**:
- File paths (spaces, slashes)
- Query parameters
- Special characters

Example:
```bash
# WRONG (will fail):
curl http://localhost:4096/file?path=/Users/name/file with spaces.md

# RIGHT:
curl "http://localhost:4096/file?path=%2FUsers%2Fname%2Ffile%20with%20spaces.md"
```

In JavaScript/TypeScript:
```typescript
import { encodeURI } from 'url'
const url = `http://localhost:4096/file?path=${encodeURI(filePath)}`
```

## Query Parameters

**Use exact parameter names** from OpenAPI spec:
| Endpoint | Parameters |
|----------|-------------|
| /find | `pattern` (required), `directory` (optional) |
| /find/file | `query` (required) |
| /file | `path` (required) |
| /session/{sessionID}/message | `limit` (optional) |

## Error Response Format

Unknown/untested - capture actual error responses from OpenCode server.

## Summary

**✅ TESTED AND VERIFIED:**
- `/session` - List all sessions
- `/session/{sessionID}` - Get session details
- `/session/status` - Get session status
- `/session/{sessionID}/message` - Get session messages
- `/find?pattern=` - Search text
- `/find/file?query=` - Find files
- `/file?path=` - Get file content
- `/global/health` - Server health

**⚠️ UNTESTED BUT IN SPEC:**
- All POST/PATCH/DELETE operations
- Most query parameters beyond basics above
- Error response formats
- All LSP, MCP, Tools endpoints

**Documentation Source:**
- OpenAPI 3.1.1 spec at `/doc?format=json`
- Live testing against OpenCode v1.2.10
