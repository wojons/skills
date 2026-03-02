# Steering Packets: Agent Orchestration & Routing Control

## Overview

**Steering packets** are structured messages used in multi-agent workflows to orchestrate agent routing, decision-making, and control flow. They encode the "next step" information that determines whether to:
- Route to another agent
- Continue the current task
- Unblock from a stuck state
- Declare completion
- Handle errors

## Core Concepts

### What are Steering Packets?

Steering packets are **formatted control messages** that:
1. Get sent via agent inbox or the last message's text
2. Are sometimes encoded in XML (or other formats)
3. Contain routing instructions and state information
4. Allow agents to communicate "what should happen next"

**Think of them as**: The "brain" of the handshake between agents in a Ralph loop.

### Why They Matter

Without steering packets, agents might:
- Deadlock: Waiting for input that never comes
- Confusion: Not knowing which agent should act next
- Stuck States: Blocking on conditions that can't be resolved
- Inconsistency: Different agents making contradictory decisions

Steering packets solve this by providing **explicit routing instructions**.

---

## Steering Packet Format

### Basic Structure

```xml
<steering>
  <status>complete</status>
  <next_agent>verifier</next_agent>
  <context>
    <previous_agent>builder</previous_agent>
    <task_id>auth-system-001</task_id>
  </context>
</steering>
```

### Full Steering Packet Schema

```xml
<steering>
  <!-- REQUIRED: Status of current agent's work -->
  <status>
    <value>complete | failed | blocked | pending</value>
    
    <!-- If blocked, explanation -->
    <block_reason>Cannot access database</block_reason>
  </status>

  <!-- REQUIRED: What to do next -->
  <routing>
    <action>
      <type>pass | stop | retry | unblock | merge</type>
      
      <!-- Where to pass work -->
      <next_agent>verifier | planner | unblocker | ...</next_agent>
      
      <!-- Special: For unblocker, keywords that triggered it -->
      <unblock_keywords>database_access_timeout | permission_denied</unblock_keywords>
    </action>
  </routing>

  <!-- OPTIONAL: Execution mode -->
  <execution>
    <mode>
      <type>linear | parallel | conditional</type>
      
      <!-- For conditional: what conditions -->
      <conditions>
        <if>
          <field>test_result</field>
          <value>passed</value>
          <then>verifier</then>
        </if>
        <else>
          <field>test_result</field>
          <value>failed</value>
          <then>builder</then>
        </else>
      </conditions>
    </mode>
  </execution>

  <!-- OPTIONAL: Payload data for next agent -->
  <payload>
    <files>
      <file path="src/auth/login.ts">modified</file>
      <file path="src/auth/register.ts">modified</file>
    </files>

    <outputs>
      <item key="endpoint_url">/api/v1/login</item>
      <item key="tests_written">5</item>
    </outputs>

    <context>
      <agent>builder</agent>
      <iteration>3</iteration>
      <errors_encountered>0</errors_encountered>
    </context>
  </payload>

  <!-- OPTIONAL: System-level commands -->
  <system>
    <!-- Is this a completion signal? -->
    <completion>
      <signal>true | false</signal>
      <promise>ALL_TESTS_PASSED</promise>
    </completion>

    <!-- Should we continue or stop? -->
    <fail_behavior>
      <type>open | closed</type>
      <description>Continue retrying or stop?</description>
    </fail_behavior>

    <!-- Any system notifications -->
    <notifications>
      <alert>
        <level>info | warning | error</level>
        <message>Database retries exceeded</message>
      </alert>
    </notifications>
  </system>
</steering>
```

---

## Routing Patterns

### Pattern 1: Linear Pass-Through

Agent A → Agent B → Agent C → Complete

**Scenario**: Sequential workflow

```xml
<!-- Agent: builder -->
<steering>
  <status>complete</status>
  <routing>
    <action type="pass">
      <next_agent>verifier</next_agent>
    </action>
  </routing>
  <payload>
    <files>
      <file path="src/auth/*">modified</file>
    </files>
  </payload>
</steering>
```

**Next agent (verifier) receives**:
- All payload data
- Knows it came from builder
- Can continue work from checkpoint

---

### Pattern 2: Conditional Branching

Agent decides routing based on conditions

**Scenario**: Tests pass or fail?

```xml
<steering>
  <status>complete</status>
  <routing>
    <action type="conditional">
      <conditions>
        <!-- If tests pass, go to deployer -->
        <if>
          <field>test_status</field>
          <value>all_passed</value>
          <then>deployer</then>
        </if>
        
        <!-- Otherwise, go back to builder -->
        <else>
          <field>test_status</field>
          <value>failed</value>
          <then>builder</then>
        </else>
      </conditions>
    </action>
  </routing>
  
  <payload>
    <outputs>
      <item key="test_results">
        <test name="login">passed</test>
        <test name="register">failed</test>
      </item>
    </outputs>
  </payload>
</steering>
```

---

### Pattern 3: Unblocking via Special Agent

Agent gets stuck → Steering packet keywords trigger unblocker → Returns to plan

**Scenario**: Builder blocked by database access

```xml
<!-- Agent: builder -->
<steering>
  <status>blocked</status>
  
  <block_reason>
    Cannot access database. Connection timeout after 30s.
  </block_reason>
  
  <routing>
    <action type="unblock">
      <next_agent>unblocker</next_agent>
      
      <!-- Keywords that unblockers look for -->
      <unblock_keywords>
        <keyword>database_access_timeout</keyword>
        <keyword>connection_refused</keyword>
      </unblock_keywords>
    </action>
  </routing>
  
  <payload>
    <context>
      <attempted_actions>
        <action>db.connect()</action>
        <action>ping_database()</action>
      </attempted_actions>
      
      <environment>
        <var key="DB_HOST">localhost:5432</var>
        <var key="DB_RETRIES">3</var>
      </environment>
    </context>
  </payload>
</steering>
```

**Unblocker Agent** receives this and:
1. Scans for `unblock_keywords`
2. Identifies the blockage (database connection)
3. Takes action:
   - Restart database service
   - Fix connection string
   - Update credentials
4. Sends steering packet back:

```xml
<!-- Agent: unblocker -->
<steering>
  <status>complete</status>
  
  <routing>
    <action type="pass">
      <next_agent>planner</next_agent>
      
      <!-- Message to planner -->
      <message>
        Database unblocked. Continue with task {task_id}
      </message>
    </action>
  </routing>
  
  <payload>
    <resolution>
      <action_taken>restarted_database</action_taken>
      <result>connection_established</result>
    </resolution>
  </payload>
</steering>
```

**Planner** adjusts strategy based on unblock and continues.

---

### Pattern 4: Parallel Execution

Router determines which agents run simultaneously

**Scenario**: Verify frontend, backend, and tests in parallel

```xml
<!-- Agent: planner -->
<steering>
  <status>complete</status>
  
  <routing>
    <action type="parallel">
      <next_agents>
        <agent role="verifier_frontend">frontend</agent>
        <agent role="verifier_backend">backend</agent>
        <agent role="verifier_tests">tests</agent>
      </next_agents>
    </action>
  </routing>
  
  <payload>
    <tasks>
      <task id="frontend-001" agent="verifier_frontend">
        <description>Verify frontend authentication UI</description>
      </task>
      <task id="backend-001" agent="verifier_backend">
        <description>Verify backend auth endpoints</description>
      </task>
    </tasks>
  </payload>
  
  <execution>
    <mode type="parallel"/>
  </execution>
</steering>
```

**All three verifiers** run in parallel. Each produces its own steering packet.

---

## Fail Behavior: Open vs Closed

### Fail Open (Continue Trying)

System keeps trying even after failures

**Use when**:
- Task is important
- Failures are transient (network, database timeouts)
- Can retry safely

**Example**:
```xml
<steering>
  <status>failed</status>
  
  <system>
    <fail_behavior>
      <type>open</type>
      
      <!-- Continue retrying -->
      <continue>
        <max_retries>10</max_retries>
        <backoff>exponential</backoff>
        <wait_seconds>
          <retry_1>5</retry_1>
          <retry_2>10</retry_2>
          <retry_3>20</retry_3>
        </wait_seconds>
      </continue>
    </fail_behavior>
  </system>
</steering>
```

**Behavior**:
- Agent can retry
- Other agents may continue
- System doesn't abort

### Fail Closed (Stop Trying)

System halts on failure to prevent damage

**Use when**:
- Failures cause data corruption
- Security risks
- Critical errors that shouldn't be retried

**Example**:
```xml
<steering>
  <status>failed</status>
  
  <block_reason>
    Access denied: Permission mismatch
  </block_reason>
  
  <system>
    <fail_behavior>
      <type>closed</type>
      
      <!-- Don't retry -->
      <stop>
        <reason>Security permission denied</reason>
        <requires_human_intervention>true</requires_human_intervention>
      </stop>
    </fail_behavior>
  </system>
</steering>
```

**Behavior**:
- Agent stops execution
- System halts related workflows
- Notifies human operator

---

## Implementation Pattern

### Pattern 1: Inbox-Based Steering

Agents send steering packets to designated inboxes

```
agents/
├── builder/
│   └── inbox/
│       └── outbox/  # Where builder writes steering packets
├── verifier/
│   └── inbox/       # Where verifier reads steering packets
└── unblocker/
    └── inbox/       # Where unblocker watches for keywords
```

**Implementation**:
```typescript
// Agent writes steering packet
const steering = {
  status: 'complete',
  routing: {
    action: 'pass',
    next_agent: 'verifier'
  },
  payload: { /* data */ }
}

await fs.writeFileSync(
  '.ralph/agents/builder/outbox/steering.xml',
  formatXml(steering)
)

// Verifier reads and acts
const steering = await readSteeringPacket('.ralph/agents/builder/outbox/')
const nextAgent = steering.routing.next_agent
```

### Pattern 2: Message-Based Steering

Last message text contains steering packet

```markdown
I've completed building the authentication system.

<steering>
  <status>complete</status>
  <routing>
    <action>
      <type>pass</type>
      <next_agent>verifier</next_agent>
    </action>
  </routing>
</steering>

Files modified:
- src/auth/login.ts
- src/auth/register.ts
- src/auth/models.ts
```

**System parses** last message, extracts steering packet, and routes accordingly.

---

## Real-World Examples

### Example 1: Failed Build → Retry

```xml
<!-- Builder failed -->
<steering>
  <status>failed</status>
  <block_reason>Test login_endpoint_auth failed</block_reason>
  
  <routing>
    <action>
      <type>retry</type>
      <next_agent>builder</next_agent>
      <retry_count>3</retry_count>
    </action>
  </routing>
  
  <payload>
    <failures>
      <failure>
        <test>login_endpoint_auth</test>
        <error>JWT validation secret mismatch</error>
      </failure>
    </failures>
  </payload>
  
  <system>
    <fail_behavior>
      <type>open</type>
    </fail_behavior>
  </system>
</steering>
```

**Result**: Builder retries 3 more times

---

### Example 2: Complete Flow with Steering

**Scenario**: Build authentication system

1. **Planner** → Builder
```xml
<steering>
  <status>complete</status>
  <routing>
    <action type="pass"><next_agent>builder</next_agent></action>
  </routing>
  <payload>
    <tasks>
      <task>Create user models</task>
      <task>Build login endpoint</task>
      <task>Build registration endpoint</task>
      <task>Write tests</task>
    </tasks>
  </payload>
</steering>
```

2. **Builder** (iteration 1) → Blocked
```xml
<steering>
  <status>blocked</status>
  <block_reason>Cannot connect to database</block_reason>
  <routing>
    <action>
      <type>unblock</type>
      <next_agent>unblocker</next_agent>
      <unblock_keywords>database_access_timeout</unblock_keywords>
    </action>
  </routing>
</steering>
```

3. **Unblocker** → Planner (unblocked)
```xml
<steering>
  <status>complete</status>
  <routing>
    <action>
      <type>pass</type>
      <next_agent>planner</next_agent>
      <message>Database unblocked. Continue with task 001</message>
    </action>
  </routing>
  <payload>
    <resolution>restarted_database_service</resolution>
  </payload>
</steering>
```

4. **Planner** → Builder (retry)
```xml
<steering>
  <status>complete</status>
  <routing>
    <action>
      <type>pass</type>
      <next_agent>builder</next_agent>
      <message>Retry task 001 with database connection</message>
    </action>
  </routing>
</steering>
```

5. **Builder** (iteration 2) → Complete → Verifier
```xml
<steering>
  <status>complete</status>
  <routing>
    <action type="pass"><next_agent>verifier</next_agent></action>
  </routing>
  <payload>
    <files>
      <file path="src/auth/*">modified</file>
    </files>
  </payload>
</steering>
```

6. **Verifier** → Complete
```xml
<steering>
  <status>complete</status>
  <routing>
    <action type="complete"/>
  </routing>
  <system>
    <completion>
      <signal>true</signal>
      <promise>AUTH_SYSTEM_COMPLETE</promise>
    </completion>
  </system>
</steering>
```

---

## Best Practices

### 1. Always Include Required Fields
```xml
<steering>
  <status>value</status>
  <routing><action>...</action></routing>
</steering>
```

### 2. Be Explicit About Next Steps
Don't leave agents guessing:

```xml
<!-- Good -->
<routing>
  <action type="pass">
    <next_agent>verifier</next_agent>
  </action>
</routing>

<!-- Bad - ambiguous -->
<routing>
  <action type="continue"/>
</routing>
```

### 3. Use Standard Keywords for Unblocking
```xml
<unblock_keywords>
  <keyword>database_access_timeout</keyword>
  <keyword>permission_denied</keyword>
  <keyword>network_unreachable</keyword>
  <keyword>file_not_found</keyword>
  <!-- More standard keywords -->
</unblock_keywords>
```

### 4. Include Context for Debugging
```xml
<context>
  <agent>builder</agent>
  <iteration>3</iteration>
  <errors_encountered>0</errors_encountered>
  <timestamp>2026-02-24T10:23:45Z</timestamp>
</context>
```

### 5. Use Fail Correctly
- **Fail open** for transient issues
- **Fail closed** for security/critical errors

### 6. Keep XML Simple
Don't over-engineer the schema. Focus on required fields:
- Status
- Routing
- (Optional) Payload
- (Optional) System commands

---

## Pattern Comparison

| Routing Type | Steering Packet Uses | Complexity | Best For |
|-------------|---------------------|------------|----------|
| Linear | Simple pass-through agent | Low | Sequential workflows |
| Conditional | Branching based on conditions | Medium | Complex decision trees |
| Parallel | Agent list, simultaneous execution | High | Multi-component tasks |
| Unblocking | Keywords trigger special agents | Medium | Handling stuck states |
| Retry | Retry count and backoff | Low-Medium | Transient failures |

---

## Summary

Steering packets are **the control plane** of Ralph loops. They answer:
1. What's happening now? (status)
2. What should happen next? (routing/agent)
3. What context do they need? (payload)
4. Are we done? (completion signal)

**Without steering packets**: Agents can't coordinate, deadlocks happen, workflows break.

**With steering packets**: Explicit routing, clear communication, reliable orchestration.

This is the "brain" that makes multi-agent Ralph loops work together smoothly.

---

## Related Resources

- **Agent Routing**: See how the broader AI agent community handles routing at [AI Agent Routing: Tutorial & Best Practices](https://www.patronus.ai/ai-agent-development/ai-agent-routing)
- **Pattern Catalog**: `common-patterns.md` for when to use steering packet techniques
- **File State Patterns**: `file-state-patterns.md` for inbox-based steering implementation
