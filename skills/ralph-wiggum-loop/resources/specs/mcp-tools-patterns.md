# MCP Tools & Agent Communication Patterns

**Verification Status**: Packages verified on February 24, 2026 from npm registry

## Overview

Model Context Protocol (MCP) tools are essential for Ralph loops to:
- Perform web searches (searxng MCP)
- Automate browsers (Playwright MCP, Browser MCP, Chrome DevTools)
- Communicate asynchronously (Agent Inbox)

This guide covers the most important MCP tools for autonomous workflows.

---

## Web Search: searxng MCP

### What It Is

[searxng](https://searxng.github.io/searxng/) is a privacy-respecting metasearch engine. The MCP wrapper allows agents to perform web searches.

### Why Important for Ralph Loops

Agents need to:
- Look up documentation during implementation
- Research libraries and APIs
- Find best practices and patterns
- Debug errors by searching for similar issues

### Verified Package

**Package**: `mcp-searxng`
**Version**: 0.9.1 (verified Feb 24, 2026)
**Repository**: https://github.com/ihor-sokoliuk/mcp-searxng
**npm install**: `npm install -g mcp-searxng`

### Installation

```bash
# Install the MCP server globally
npm install -g mcp-searxng

# Or locally for your project
npm install mcp-searxng
```

### Configuration

The package provides a CLI binary: `mcp-searxng`

Configuration options from npm package keywords:
- MCP server for SearXNG integration
- Web search with pagination
- URL reader functionality

### Setup Options

**Option 1: Docker Container** (Recommended for production)

```bash
# Pull the searxng image
docker pull searxng/searxng

# Run with persistent storage
docker run -d \
  --name searxng-mcp \
  -p 8080:8080 \
  -v searxng-data:/etc/searxng \
  searxng/searxng

# Now your agent can search via http://localhost:8080/search
```

**Option 2: Self-Hosted Instance**

```bash
# Clone the repo
git clone https://github.com/searxng/searxng.git
cd searxng

# Install dependencies
pip install -r requirements.txt

# Start the server
python searxng/webapp.py
```

**Option 3: Public Instance**

Use a public searxng instance (ensure it has JSON output enabled):
- Verify JSON API is available
- `/api/v1/search?format=json`
- Check CORS settings

### Configuration in Ralph Loops

**OpenCode Server Integration**:
```yaml
server:
  mcp_servers:
    - name: searxng
      type: http
      url: http://localhost:8080/search
      description: Web search for agents
      
  environment:
    SEARCH_JSON_ENABLED: true
```

**Agent usage in PROMPT.md**:
```markdown
# Search for Documentation

When you need to look up documentation or research an API, use searxng:

Example search query:
"python async await best practices 2025"

Format your queries as concise, specific questions aimed at finding:
- Official documentation
- Stack Overflow discussions
- Best practice guides
- API references
```

### JSON Flag Requirement

**Critical**: searxng must output JSON for agents to parse:

```bash
# When starting instance, ensure JSON format:
curl "http://localhost:8080/search?q=test&format=json&language=en"

# Expected JSON response:
{
  "query": "test",
  "results": [
    {
      "title": "Test Page",
      "url": "https://example.com/test",
      "content": "...",
      "score": 0.95
    }
  ]
}
```

**Enable in searxng settings.yaml**:
```yaml
search:
  formats:
    - json  # MUST be first for agent compatibility
```

---

## Browser Automation Tools

**Verification Status**: Packages verified on February 24, 2026 from npm registry

### Tool 1: MCPBrowser (Recommended)

**Package**: `mcpbrowser`
**Version**: 0.3.29 (verified Feb 24, 2026)
**Repository**: https://github.com/cherchyk/MCPBrowser
**npm install**: `npm install -g mcpbrowser`

**What It Is**: Browser automation MCP server that uses real Chrome/Edge/Brave browsers. Handles authentication, SSO, CAPTCHAs, and anti-bot protection.

**Why Important**:
- Real browser rendering (not headless simulation)
- Handles authentication and SSO
- Bypasses anti-bot protections (Cloudflare, detection)
- JavaScript rendering for SPAs
- Supports authentication, web scraping, automation

**Features**:
- Chrome/Edge/Brave browser support
- CDP (Chrome DevTools Protocol) integration
- Puppeteer-based automation
- Authentication and SSO handling
- CAPTCHA handling
- Anti-bot protection bypass

**Setup**:
```bash
# Install globally
npm install -g mcpbrowser

# Or locally
npm install mcpbrowser

# Binary: mcpbrowser
```

**Configuration**:
The package provides a CLI binary: `mcpbrowser`

Dependencies from npm:
- `@modelcontextprotocol/sdk` (^1.25.1)
- `puppeteer-core` (^23.4.1)

### Tool 2: Playwright MCP

**Package**: `@playwright/mcp`
**Version**: 0.0.68 (verified Feb 24, 2026)
**Repository**: https://playwright.dev
**Maintained by**: Microsoft's Playwright team
**npm install**: `npm install -g @playwright/mcp`

**What It Is**: Official Playwright-based browser automation MCP, maintained by the Playwright team.

**Why Important**:
- Official Playwright support
- Multi-browser testing (Chrome, Firefox, Safari)
- Network monitoring and interception
- Cross-browser reliability
- Active maintenance by Playwright team

**Features**:
- Multi-browser support
- Network request/response interception
- File download/upload
- Geolocation mocking
- Accessibility testing
- Visual regression testing

**Setup**:
```bash
# Install globally
npm install -g @playwright/mcp

# Binary: playwright-mcp
```

**Install Browsers**:
```bash
# Install browser binaries
npx playwright install
# or
npx playwright install --with-deps
```

**Dependencies**:
- `playwright` (1.59.0-alpha)
- `playwright-core` (1.59.0-alpha)

### Tool 3: Chrome DevTools Protocol MCP

**Package**: `chrome-devtools-mcp`
**Status**: Found in npm registry

**What It Is**: MCP tool that exposes Chrome DevTools Protocol capabilities to agents.

**Why Important**:
- Inspect web pages
- Take screenshots
- Navigate to URLs
- Execute JavaScript

**Setup**:
```bash
# Install MCP server
npm install -g chrome-devtools-mcp

# Start Chrome remote debugging
google-chrome --remote-debugging-port=9222

# Connect MCP
chrome-devtools-mcp --port 9222
```

**Agent Usage**:
```markdown
# Visual Verification Capabilities

You can:
1. Navigate to URLs: Navigate to http://localhost:3000
2. Take screenshots: Capture screenshot as file
3. Execute JavaScript: Run script in page context
4. Inspect DOM: Get information about page structure

Example tasks:
- "Open http://localhost:3000 and verify the login button is visible"
- "Take a screenshot of the dashboard"
- "Check if the form submission succeeded by reading DOM"
```

### Tool 2: Vercel Agent Browser CLI

**What It Is**: Command-line interface for headless browser automation, optimized for agent use.

**Features**:
- Headless DOM navigation
- Semantic element interaction
- Screenshot and diffing
- No GUI needed

**Setup**:
```bash
# Install npm install -g agent-browser

# Basic usage
agent-browser open http://example.com
agent-browser click @button[1]
agent-browser fill @input[1] "test@example.com"
agent-browser screenshot --output /screenshots/login.png
```

**Integration in Ralph Loops**:
```yaml
hooks:
  post_build:
    action: shell_command
    command: |
      # Start dev server
      npm run dev &
      sleep 5
      
      # Agent verifies
      agent-browser open http://localhost:3000
      agent-browser screenshot --baseline baseline.png
```

**Visual Diffing**:
```bash
# Compare before/after
agent-browser diff screenshot \
  --before /screenshots/before.png \
  --after /screenshots/after.png

# Compare URLs
agent-browser diff url \
  http://localhost:3000/v1/login \
  http://localhost:3000/v2/login
```

### Tool 3: Playwright MCP

**What It Is**: Playwright-based MCP for reliable browser automation.

**Why Use Playwright**:
- Better cross-browser support
- More reliable selectors
- Built-in waiting strategies
- Network interception

**Setup**:
```bash
# Install playwright
npm install -g playwright

# Install browsers
playwright install chromium

# Start MCP server
playwright-mcp-server
```

**Agent Usage**:
```markdown
# Playwright Capabilities

Use Playwright for:
- Multi-browser testing (Chrome, Firefox, Safari)
- Mobile emulation
- Network request/response monitoring
- File upload/download
- PDF generation

Example:
page.goto('http://localhost:3000')
page.click('button[type="submit"]')
page.screenshot({ path: 'submit.png' })
```

**Ralph Loop Integration**:
```yaml
# Pre-commit hook
pre_commit_check:
  trigger: pre_commit
  action: agent_prompt
  instructions: |
    Run headless tests using Playwright:
    
    1. Start dev server in background
    2. Open http://localhost:3000
    3. Click all main navigation buttons
    4. Take screenshot of each page
    5. Compare to /screenshots/baseline/
    
    Screenshots must match baseline within 5% tolerance
    or commit will be rejected with specific diff shown.
```

---

## Agent Inbox Pattern

### What It Is

The Agent Inbox is an asynchronous communication pattern. Instead of real-time chat, agents drop messages into directory queues that humans process when available.

### Why This Matters

**Problem**: Traditional chat is synchronous and doesn't scale
- Lines are buried in history
- Can't handle 100 parallel agents
- Human must watch in real-time

**Solution**: File-based queues
- Agents write to `.inbox/` directories
- Humans review at their own pace
- Context preserved in files

### Architecture

```
.inbox/
├── pending/
│   ├── agent-001/
│   │   └── task.json  # What agent needs
│   ├── agent-002/
│   │   └── task.json
│
├── responses/
│   ├── agent-001/
│   │   └── result.json  # Human decision
│   └── agent-002/
│       └── result.json
│
└── processed/
    ├── agent-001/
    └── agent-002/
```

### How It Works

**Step 1: Agent Requests Decision**
```json
// .inbox/pending/agent-001/task.json
{
  "agent_id": "agent-001",
  "request_type": "approval",
  "title": "Destructive operation: Drop database",
  "context": {
    "operation": "DROP TABLE users",
    "reason": "Migration requires clean slate",
    "risk": "HIGH - Data loss"
  },
  "suggested_action": "approve",
  "timestamp": "2026-02-24T10:30:00Z"
}
```

**Step 2: Human Reviews**
```json
// Human creates .inbox/responses/agent-001/result.json
{
  "decision": "reject",
  "reason": "Too risky. Create backup table first",
  "alternative": "Run migration with CREATE TABLE users_backup AS SELECT * FROM users",
  "timestamp": "2026-02-24T10:35:00Z"
}
```

**Step 3: Agent Continues**
```bash
# In next iteration, agent reads result
cat .inbox/responses/agent-001/result.json

# Decision: reject
# Proceed with: DROP TABLE users_backup

# Execute alternative approach
```

### Integration in Ralph Loops

**Triggering Inbox**:
```yaml
# In PROMPT.md
When encountering critical decisions:
1. Create task.json in .inbox/pending/
2. Include full context
3. Continue with other tasks
4. Check for resolution on next iteration
```

**Agent Checks**:
```markdown
# Inbox Check Protocol

At start of each iteration:
1. Check .inbox/pending/ for your agent_id
2. If task.json exists, read it
3. Check .inbox/responses/ for your agent_id
4. If result.json present:
   - Apply the human decision
   - Move processed files to .inbox/processed/
   - Continue with next task
5. If no response yet:
   - Continue with other non-blocking tasks
   - Return to check on next iteration
```

**Multi-Agent Coordination**:
```yaml
# Example workflow
agents:
  planner:
    can_block: false
    inbox_responses_delayed: true
    
  builder:
    can_block: false
    waits_for: planner
    
  verifier:
    can_block: true
    requires_approval: true
    
# Planner doesn't wait for human
# Builder continues when planner done
# Verifier pauses for approval if needed
```

### Implementation Patterns

**Pattern A: Non-Blocking Async**
```yaml
agent_behavior:
  on_pending_request: continue
  check_interval: 5  # Check every 5 iterations
  
# Use for: Informational requests, optional approvals
```

**Pattern B: Blocking Sync**
```yaml
agent_behavior:
  on_pending_request: wait
  timeout: 3600  # Wait max 1 hour
  
# Use for: Critical decisions, destructive operations
```

**Pattern C: Parallel Agents Sharing Inbox**
```
agent-001: [Writing code] → Requires API key decision
agent-002: [Writing tests] → Continues (non-blocking)
agent-003: [Writing docs] → Continues (non-blocking)

All three write to same .inbox/ directory structure
Each checks only its own ID
```

### File Format Examples

**Human Interface (Markdown Summary)**:
```markdown
# .inbox/pending/agent-001/summary.md

Agent: agent-001
Request Type: approval
Created: 2026-02-24T10:30:00Z

## Task
Agent wants to drop the `users` table.

## Context
- Risk: HIGH data loss
- Reason: Database migration
- Suggested: Approve immediately

## Options
1. [x] Approve as suggested
2. [ ] Reject with explanation
3. [ ] Request more info

## Your Decision
Create result.json with your decision.
```

**Agent-Friendly (JSON)**:
```json
{
  "decision": "approve",
  "notes": "Proceed but monitor for 1 hour"
}
```

### Best Practices

1. **Use Unique Agent IDs**
   - Don't use "agent-1, agent-2" - use descriptive names
   - Example: "auth-builder", "frontend-optimizer"

2. **Set Timeouts**
   - Don't wait forever
   - Default: 1 hour for approvals
   - Configurable in PROMPT.md

3. **Provide Context**
   - Always include risk level
   - Explain why action is needed
   - Offer alternatives

4. **Clean Up Processed**
   - Move to `.inbox/processed/`
   - Don't let folders grow indefinitely

5. **Use JSON Not Markdown**
   - Agents parse JSON easily
   - No risk of formatting corruption
   - Structured data for decisions

---

## Integration Patterns

### Pattern 1: Search-Then-Build

```yaml
# Agent uses searxng MCP
workflow:
  - name: search_documentation
    tool: searxng_mcp
    query_pattern: "{library} {concept} best practices"
    
  - name: read_search_results
    tool: file_read
    path: /tmp/search-results.json
    
  - name: implement_code
    agent: builder
    context: search_results
    
# Agent flow:
# 1. Search "React useState hook best practices"
# 2. Read JSON results
# 3. Write code using patterns found
```

### Pattern 2: Automated Visual Testing

```yaml
# Agent uses Chrome DevTools MCP
hooks:
  post_build:
    - start_dev_server
    - open_page http://localhost:3000
    - wait_for_load
    - screenshot baseline.png
    
  visual_compare:
    - screenshot after.png
    - compare baseline.png after.png
    - report_diff
    
  on_diff_found:
    - write to .inbox/pending/
    - wait for human approval
    - fix if approve
```

### Pattern 3: Parallel Async Development

```
Time: 0min ┌─────────────────┐
         │ Agent 1 (Front) │
         └─────────────────┘
         
         │                 │
         ▼                 ▼
    Approvals needed?     No block
         │                 │
         │                 │
Time: 5min  ┌───────────┐  ┌───────────┐
         │ Write to    │  │ Write code│
         │ agent-1     │  │ Continue  │
         │ .inbox/     │  └───────────┘
         └───────────┘
         
         │
         ▼
Time: 10min ┌─────────┐
           │  Agent 1 │
           │ waiting? │
           └─────────┘
             ▲
             │
Time: 20min  ┌─────────┐
           │ Check    │
           │ inbox    │
           └─────────┘
             │
             ▼
       Decision received?
             │
             ├─ No → Continue checking
             │
             └─ Yes → Apply and move on
```

### Pattern 4: Multi-Agent with Shared Inbox

```
.inbox/
├── pending/
│   └── frontend-builder/
│       └── task.json
│
responses/
└── frontend-builder/
    └── result.json

Agent 1 (Frontend):
writes → .inbox/pending/frontend-builder/task.json
waits ← reads result.json when appears

Agent 2 (Backend):
writes → .inbox/pending/backend-builder/task.json  
waits ← reads result.json when appears

Human Dashboard:
  Shows all pending requests
  Approves or rejects each
  Writes response.json files

Result: Both agents can work independently
        Human approves when convenient
        No need to wait for each other
```

---

## Tool Selection Guide

| Task | Primary Tool | Alternative | Why |
|------|---------------|------------|-----|
| Web search | mcp-searxng | Google API | Privacy, self-hosted, JSON output |
| Real browser auth | mcpbrowser | - | Handles SSO, CAPTCHAs, anti-bot |
| Cross-browser testing | @playwright/mcp | - | Official support, multi-browser |
| Quick DOM access | chrome-devtools-mcp | - | Direct Chrome DevTools Protocol |

**When to use each**:
- **mcp-searxng**: Always for web search (documentation, best practices)
- **mcpbrowser**: When need real browser with auth, SSO, CAPTCHA support
- **@playwright/mcp**: Multi-browser testing, network monitoring, official Playwright support
- **chrome-devtools-mcp**: Quick page checks and JS execution via CDP

---

## MCP Server Configuration Examples

### OpenCode Server Integration

```yaml
# opencode.jsonc
{
  "$schema": "https://opencode.ai/config.json",

  "mcp_servers": {
    "search": {
      "command": "npx",
      "args": ["mcp-searxng", "http://localhost:8080"],
      "description": "Web search via searxng"
    },

    "browser": {
      "command": "mcpbrowser",
      "args": [],
      "description": "Browser automation with auth support"
    },

    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp"],
      "description": "Playwright browser automation"
    },

    "chrome-tools": {
      "command": "chrome-devtools-mcp",
      "args": ["--port", "9222"],
      "description": "Chrome DevTools Protocol"
    }
  }
}
```

### Environment Setup

```bash
# Start searxng
docker run -d -p 8080:8080 searxng/searxng

# Start Chrome with remote debugging (for Chrome DevTools MCP)
google-chrome --remote-debugging-port=9222

# Install browser binaries for MCPBrowser
# (mcpbrowser auto-downloads on first use)

# Install Playwright browsers
npx playwright install

# Now OpenCode can attach to all MCPs
```

### Docker Compose (Recommended)

```yaml
# docker-compose.yml
version: '3.8'

services:
  searxng-mcp:
    image: searxng/searxng
    ports:
      - "8080:8080"
    volumes:
      - searxng-data:/etc/searxng
    restart: unless-stopped

  chrome:
    image: ubuntu:latest
    command: >
      bash -c 'apt-get update && apt-get install -y chromium-browser &&
      chromium-browser --remote-debugging-port=9222 --no-sandbox'
    ports:
      - "9222:9222"

  playwright:
    build:
      context: .
      dockerfile: Dockerfile.playwright
    ports:
      - "3000:3000"

volumes:
  searxng-data:
```

```bash
# Start everything
docker-compose up -d

# Verify searxng
curl http://localhost:8080/search?format=json&language=en&q=test
```

---

## Summary

**For Ralph loops, having these MCP tools is essential**:

1. **searxng MCP** - Agents can research documentation
2. **Chrome DevTools MCP** - Quick visual checks and JS execution
3. **Playwright** - Reliable browser automation
4. **Agent Browser CLI** - Command-line workflow friendly
5. **Agent Inbox** - Async communication, scales to many agents

**Setup recommendations**:
- Use Docker for searxng (easy deployment)
- Chrome with remote debugging on port 9222
- Agent Browser CLI for screenshots
- Playwright for complex testing
- File-based .inbox/ for async decisions

**Key point about searxng**: JSON flag MUST be enabled - this is what allows agents to parse search results programmatically.

These tools turn Ralph loops from "text-only agents" to agents that can:
- Browse the web for answers
- Visually verify code behavior
- Communicate with humans asynchronously
- Scale to parallel multi-agent workflows
