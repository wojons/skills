---
name: testing-expected-results
description: Verify command behavior and side effects against expected outcomes, not just exit codes - catch the "exit 0 but actually broken" cases
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: testing
---

# Testing Expected Results

Run real commands and verify they produce the ACTUAL side effects and outputs you expect - not just "exit code 0." Catches the dangerous cases where commands "succeed" but don't do what they claim.

## When to use me

Use this skill when:
- A command returns 0 but you're not sure it actually worked
- You need to verify side effects (files created, data changed, services running)
- Exit code checking gives false confidence
- "It ran without error" isn't enough proof
- Commands have complex side effects across multiple systems
- You're debugging "why did the deploy succeed but the app is down?"

## What I do

### 1. Capture Pre-State
Before running the command, capture:
- Filesystem state (files, directories, permissions)
- Database state (records, schema)
- Process state (running services)
- Network state (ports, connections)
- Environment variables

### 2. Run the Command
Execute the actual command with:
- Timeout protection
- Resource limits
- Security sandboxing
- Output capture (stdout, stderr)
- Exit code capture

### 3. Capture Post-State
After the command completes, capture the same state.

### 4. Smart Comparison
Compare actual vs expected with intelligence:
- **Exact match** - For deterministic output
- **Pattern match** - For variable content (timestamps, UUIDs)
- **Range match** - For numeric values (response time, file size)
- **Structure match** - For JSON/XML (ignore key order)
- **Semantic match** - For content meaning (not just bytes)
- **Existence check** - For "should exist" / "should not exist"
- **Delta check** - For "should have changed by X"

### 5. Side Effect Verification
Verify specific side effects:
- **Filesystem** - File created/modified/deleted, permissions changed
- **Database** - Records inserted/updated, schema migrated
- **Processes** - Service started/stopped/restarted
- **Network** - Port bound, connection made, API called
- **External** - Cloud resources created, messages queued

### 6. Async/Delayed Effect Handling
For commands with eventual consistency:
- Poll with configurable intervals
- Wait for specific conditions
- Timeout handling
- Retry logic

## Examples

```bash
# Verify a backup actually created a valid backup
bash scripts/verify.sh \
  --command "./backup.sh --source=/data --dest=/backups" \
  --expected 'file_exists:/backups/backup-$(date +%Y%m%d).tar.gz' \
  --expected 'file_size:>100MB' \
  --expected 'file_integrity:sha256' \
  --negative 'file_modified:/data' \
  --timeout 300

# Verify a deployment actually started the service
bash scripts/verify.sh \
  --command "./deploy.sh --version=v2.0.0" \
  --expected 'process_running:my-service' \
  --expected 'port_listening:8080' \
  --expected 'http_healthy:http://localhost:8080/health' \
  --poll-interval 5 --timeout 120

# Verify a database migration actually changed the schema
bash scripts/verify.sh \
  --command "./migrate.sh up" \
  --expected 'db_table_exists:new_table' \
  --expected 'db_column_exists:new_table.new_column' \
  --expected 'db_constraint:unique_on_email' \
  --db-connection "postgresql://localhost/mydb"

# Verify an export actually produced correct data
bash scripts/verify.sh \
  --command "./export.sh --format=csv --output=/exports/users.csv" \
  --expected 'file_exists:/exports/users.csv' \
  --expected 'file_contains:"user_id,email,name"' \
  --expected 'line_count:>1000' \
  --expected 'csv_valid:yes' \
  --negative 'file_contains:ERROR'

# Verify negative side effects (what shouldn't happen)
bash scripts/verify.sh \
  --command "./cleanup.sh --days=30" \
  --expected 'file_deleted:/tmp/old_stuff' \
  --negative 'file_exists:/important/data' \
  --negative 'file_deleted:/critical/config'
```

## Verification Types

### Filesystem Effects
```yaml
file_exists:
  path: /path/to/file
  optional:
    - min_size: 100MB       # File must be at least this big
    - max_size: 1GB        # File must be at most this big
    - permissions: 644     # Specific permissions
    - owner: appuser       # Specific owner
    - modified_after: now # Modified after command started
    - content_type: text  # MIME type or magic number

file_contains:
  path: /path/to/file
  pattern: "string or regex"
  optional:
    - count: 1             # Must appear exactly N times
    - line_number: 5       # Must be on specific line

file_hash:
  path: /path/to/file
  algorithm: sha256        # sha256, md5, sha512
  expected: abc123...      # Hash value (optional - just check hash exists)

directory_structure:
  path: /path/to/dir
  expected: |
    dir/
    dir/file1.txt
    dir/subdir/
    dir/subdir/file2.txt
```

### Database Effects
```yaml
db_table_exists:
  name: users
  connection: ${DB_URL}

db_column_exists:
  table: users
  column: email
  type: varchar(255)
  nullable: false

db_row_count:
  table: users
  where: "created_at > NOW() - INTERVAL '1 day'"
  expected: 100
  tolerance: +/- 10        # Allow 90-110

db_query_result:
  query: "SELECT COUNT(*) FROM users WHERE active = true"
  expected: "> 1000"
```

### Process Effects
```yaml
process_running:
  name: my-service
  optional:
    - user: appuser
    - cpu_percent: < 50
    - memory_mb: < 1024
    - uptime_seconds: > 60

port_listening:
  port: 8080
  protocol: tcp           # tcp, udp
  optional:
    - interface: 0.0.0.0   # Specific bind address
    - process_name: app   # Must be owned by this process
```

### Network Effects
```yaml
http_request:
  url: http://localhost:8080/health
  method: GET
  expected_status: 200
  optional:
    - timeout: 5
    - expected_body: '{"status": "healthy"}'
    - expected_headers: 'Content-Type: application/json'
    - retry: 3

tcp_connect:
  host: localhost
  port: 5432
  timeout: 5
```

### Content Verification
```yaml
csv_valid:
  file: /path/to/file.csv
  expected_columns: id,name,email
  row_count: "> 100"

json_valid:
  file: /path/to/file.json
  schema: /path/to/schema.json  # JSON Schema validation
  required_paths:
    - $.status
    - $.data.users[0].name
```

## Comparison Strategies

### Handling Non-Determinism

**Timestamps:**
```bash
# Match any ISO8601 timestamp
--expected 'file_contains:{{TIMESTAMP}}'

# Match timestamp within range
--expected 'file_contains:{{TIMESTAMP_RANGE:2024-01-01,2024-12-31}}'
```

**UUIDs:**
```bash
# Match any UUID
--expected 'file_contains:{{UUID}}'

# Match UUID pattern but validate it
--expected 'file_contains:{{UUID_FORMAT}}'
```

**Order-Independent:**
```bash
# For JSON arrays, sets, etc.
--expected 'json_path:$.data.items contains [1,2,3] (any order)'
```

### Partial Matching

```bash
# File must contain ALL these patterns
--expected 'file_contains_all:["success", "completed", "exit 0"]'

# File must contain AT LEAST ONE of these
--expected 'file_contains_any:["success", "done", "finished"]'

# File must contain pattern EXACTLY N times
--expected 'file_contains:"ERROR" count:0'  # No errors
```

## Security

**Sandboxing:**
```bash
# Run in container
bash scripts/verify.sh --sandbox container ...

# Run with limited permissions
bash scripts/verify.sh --sandbox chroot --chroot-dir /tmp/sandbox ...

# Resource limits
bash scripts/verify.sh --max-memory 1GB --max-cpu 50% --timeout 300 ...
```

**Secret Masking:**
```bash
# Automatically mask common secret patterns in output
bash scripts/verify.sh --mask-secrets ...
```

## Output Format

```yaml
Verification Report
===================
Command: ./backup.sh --source=/data --dest=/backups
Exit Code: 0
Duration: 45.2s

Pre-State Captured:
  Files: 1,247
  Database tables: 23
  Processes: 12

Post-State Captured:
  Files: 1,248 (+1)
  Database tables: 23 (unchanged)
  Processes: 12 (unchanged)

Expected Results Verification:
  ✅ file_exists:/backups/backup-20240308.tar.gz
     - Path exists: yes
     - Size: 1.2GB (expected: >100MB) ✅
     - Permissions: 644 ✅
     - Created: 2024-03-08T10:30:15Z (after command start) ✅
     - Hash (sha256): abc123... ✅

  ❌ file_integrity (custom check)
     - Can extract archive: yes
     - Can restore from backup: FAILED
     - Error: "table users has wrong schema version"
     
Negative Assertions:
  ✅ file_modified:/data - No changes detected
  ✅ file_deleted:/important - No deletions detected

Async Effects:
  ✅ service_health (after 30s polling)
     - Service responsive: yes
     - Health check passed: yes

Result: FAILED

Discrepancy Analysis:
  The backup file was created with correct size and permissions,
  but integrity check reveals it cannot be restored. The schema
  version mismatch suggests the backup captured incompatible data.

Recommendations:
  1. Run schema migration before backup
  2. Add schema version check to backup script
  3. Include test restore in backup verification

Commands Run:
  Pre-state capture: 0.5s
  Command execution: 42.1s
  Post-state capture: 0.4s
  Verification: 2.2s
  Total: 45.2s
```

## Limitations

**What we CAN'T verify:**
- In-memory state changes (caches, variables)
- Browser/client-side state
- Side effects in systems we can't access
- Changes that happen after verification timeout
- Non-deterministic behavior that changes between runs
- Effects in distributed systems with eventual consistency (we can poll but may miss)

**Known Issues:**
- Time-of-check-time-of-use (TOCTOU) race conditions
- State changes between capture and verification
- Verification is only as good as the expected results definition

## Trust But Verify

This skill implements "trust but verify" - we trust the command ran, but we verify it did what it claimed. Always remember:

- Exit code 0 doesn't mean success
- Success doesn't mean correctness
- Correctness doesn't mean safety
- Safety doesn't mean completeness

Use multiple verification layers for critical operations.

## Notes

- Verification adds overhead. Use selectively for critical commands.
- Define expected results exhaustively - partial verification gives false confidence.
- Include negative assertions (what shouldn't happen) alongside positive ones.
- For long-running commands, use async verification with polling.
- Always include timeout to prevent hanging on failed commands.
- Use semantic matchers (structure, pattern) over exact string comparison when possible.
- Document in your expected results WHY each check matters - future you will thank you.
