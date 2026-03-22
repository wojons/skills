# Detection Guide: Finding Incomplete Code

This guide provides practical methods for detecting incomplete implementations using both static and dynamic analysis.

## Tier 1: AST-Based Static Analysis

### Detecting Empty Functions

**Why grep fails:**
```bash
# This misses many cases:
grep -r "pass" --include="*.py" .

# Missed: function foo() {}
# Missed: const bar = () => {}
# Missed: async function baz() { /* TODO */ }
```

**Use AST analysis instead:**

#### JavaScript/TypeScript
Using ESLint with AST rules:
```bash
# Check for empty functions
npx eslint . --rule 'no-empty-function:error'

# Check for empty blocks
npx eslint . --rule 'no-empty:error'
```

Or use the AST directly:
```javascript
const espree = require('espree');
const fs = require('fs');

const code = fs.readFileSync('file.js', 'utf8');
const ast = espree.parse(code, {
  ecmaVersion: 2022,
  sourceType: 'module'
});

// Traverse AST to find empty functions
function findEmptyFunctions(node) {
  if (node.type === 'FunctionDeclaration' || node.type === 'FunctionExpression') {
    if (node.body.body.length === 0) {
      console.log(`Empty function: ${node.id?.name || 'anonymous'}`);
    }
  }
}
```

#### Python
Using the `ast` module:
```python
import ast

with open('file.py') as f:
    tree = ast.parse(f.read())

for node in ast.walk(tree):
    if isinstance(node, ast.FunctionDef):
        if len(node.body) == 1 and isinstance(node.body[0], ast.Pass):
            print(f"Empty function: {node.name}")
```

### Detecting Stub Implementations

**What to look for:**
- Functions that only raise `NotImplementedError`
- Functions that return hardcoded values
- Functions with only pass/... statements

**JavaScript AST detection:**
```javascript
// Detect functions that just throw
function isStubFunction(node) {
  if (node.body.body.length === 1) {
    const statement = node.body.body[0];
    if (statement.type === 'ThrowStatement') {
      return true;
    }
  }
  return false;
}
```

**Python detection:**
```python
def is_stub_function(node):
    """Detect if a function only raises NotImplementedError"""
    if len(node.body) == 1:
        stmt = node.body[0]
        if isinstance(stmt, ast.Raise):
            if isinstance(stmt.exc, ast.Call):
                if stmt.exc.func.id == 'NotImplementedError':
                    return True
    return False
```

### Detecting Mock Usage

**AST-based approach (better than grep):**

```javascript
// Detect jest.mock() calls
function findMockCalls(ast) {
  const mocks = [];
  traverse(ast, {
    CallExpression(node) {
      if (node.callee?.name === 'mock' || 
          node.callee?.object?.name === 'jest' && node.callee.property?.name === 'mock') {
        mocks.push(node);
      }
    }
  });
  return mocks;
}
```

**Calculate mock ratio:**
```bash
# Count test files
TEST_FILES=$(find . -name "*.test.js" -o -name "*.spec.js" | wc -l)

# Count files with mocks
MOCK_FILES=$(grep -rl "jest.mock\|vi.mock" --include="*.test.js" . | wc -l)

# Calculate ratio
if [ "$TEST_FILES" -gt 0 ]; then
  MOCK_RATIO=$((MOCK_FILES * 100 / TEST_FILES))
  echo "Mock usage: ${MOCK_RATIO}% of test files"
  
  if [ "$MOCK_RATIO" -gt 80 ]; then
    echo "WARNING: Heavy mock usage - verify real integration"
  fi
fi
```

## Tier 2: Runtime Verification

### Verifying Database Connections

**Don't just check if env vars exist:**
```bash
# BAD: Just checks file existence
cat .env | grep DATABASE_URL

# GOOD: Actually connects
node -e "
const { Client } = require('pg');
const client = new Client({ connectionString: process.env.DATABASE_URL });
client.connect()
  .then(() => console.log('Database connected'))
  .catch(e => console.error('Connection failed:', e))
  .finally(() => client.end());
"
```

**Python version:**
```python
import os
import psycopg2

try:
    conn = psycopg2.connect(os.getenv('DATABASE_URL'))
    cursor = conn.cursor()
    cursor.execute('SELECT 1')
    print("Database connection verified")
except Exception as e:
    print(f"Database connection failed: {e}")
finally:
    if conn:
        conn.close()
```

### Verifying External API Calls

**Capture actual network traffic:**
```javascript
// Using mitm or proxy to verify real calls
const http = require('http');
const proxy = http.createServer((req, res) => {
  console.log(`Actual request to: ${req.url}`);
  // Forward to real destination
});

// Start your app
// Make requests
// Check proxy logs for actual calls (not mocked)
```

**Check for network activity in tests:**
```bash
# Monitor network during test run
nettop -P -k state,tx_bytes,rx_bytes | grep -E "your-process|test" > network.log &
npm test
pkill nettop

# Check if any external calls were made
if grep -q "api\|http" network.log; then
  echo "Real network calls detected"
else
  echo "WARNING: No external calls - may be using mocks"
fi
```

### Smoke Testing

**Verify the application actually runs:**
```bash
#!/bin/bash
# smoke-test.sh

# Start app in background
npm start &
APP_PID=$!

# Wait for startup
sleep 5

# Check if process is running
if ! ps -p $APP_PID > /dev/null; then
  echo "FAIL: Application failed to start"
  exit 1
fi

# Check health endpoint
if curl -s http://localhost:3000/health > /dev/null; then
  echo "PASS: Health check responded"
else
  echo "FAIL: Health check failed"
  kill $APP_PID
  exit 1
fi

# Test actual functionality
curl -s http://localhost:3000/api/users | jq . > /dev/null
if [ $? -eq 0 ]; then
  echo "PASS: API returning valid JSON"
else
  echo "FAIL: API not returning valid JSON"
  kill $APP_PID
  exit 1
fi

# Cleanup
kill $APP_PID
echo "All smoke tests passed!"
```

## Tier 3: Production Readiness Detection

### Detecting Observability Gaps

**Check for structured logging:**
```bash
# Check package.json for logging libraries
grep -E "winston|pino|bunyan|@sentry" package.json

# Check if logging is actually used
grep -r "logger\." --include="*.js" --include="*.ts" . | wc -l
```

**Verify metrics collection:**
```bash
# Check for metrics libraries
grep -E "prom-client|statsd|datadog" package.json

# Check for metrics endpoints
curl -s http://localhost:3000/metrics > /dev/null && echo "Metrics endpoint exists"
```

### Security Detection

**Check for security middleware:**
```bash
# In code
grep -r "helmet\|csurf\|express-rate-limit" --include="*.js" --include="*.ts" .

# Check for input validation
grep -r "\.validate\|joi\|zod\|yup" --include="*.js" --include="*.ts" .
```

**Detect secrets in code:**
```bash
# Check for hardcoded secrets
grep -ri "password.*=\|api_key.*=\|secret.*=" --include="*.js" --include="*.ts" --include="*.py" . | grep -v "node_modules"

# Check for .env.example
if [ ! -f ".env.example" ]; then
  echo "WARNING: No .env.example - secrets may not be documented"
fi
```

### CI/CD Validation

**Verify pipeline actually works:**
```bash
# Don't just check if file exists
if [ -f ".github/workflows/ci.yml" ]; then
  # Actually run the workflow locally
  act -j test  # Using nektos/act
fi
```

**Check for deployment automation:**
```bash
# Look for deployment scripts
grep -r "deploy\|kubectl\|docker push" --include="*.yml" --include="*.yaml" .github/workflows/ | wc -l

# Check for rollback capability
grep -r "rollback\|revert" --include="*.yml" --include="*.yaml" .github/workflows/
```

## Advanced Techniques

### Dependency Injection Analysis

**Verify real implementations are used:**
```javascript
// Analyze imports vs usage
const imports = getImports(file);
const realServices = imports.filter(imp => 
  !imp.includes('Mock') && 
  !imp.includes('Stub') &&
  !imp.includes('Fake')
);

const mockServices = imports.filter(imp => 
  imp.includes('Mock') || 
  imp.includes('Stub') ||
  imp.includes('Fake')
);

const mockRatio = mockServices.length / (realServices.length + mockServices.length);
if (mockRatio > 0.5) {
  console.log("WARNING: High mock ratio in production code");
}
```

### Test Quality Analysis

**Check assertion complexity:**
```javascript
// Simple assertions that don't test behavior
const trivialPatterns = [
  /expect\(true\)/,
  /expect\(1\)/,
  /expect\(null\)/,
  /toBeDefined\(\)/,
  /toBeTruthy\(\)/
];

function analyzeTestQuality(testFile) {
  const content = fs.readFileSync(testFile, 'utf8');
  const assertions = content.match(/expect\([^)]+\)/g) || [];
  
  const trivialCount = assertions.filter(assertion => 
    trivialPatterns.some(pattern => pattern.test(assertion))
  ).length;
  
  const trivialRatio = trivialCount / assertions.length;
  
  if (trivialRatio > 0.5) {
    console.log(`WARNING: ${testFile} has ${trivialRatio*100}% trivial assertions`);
  }
}
```

## Detection Summary

### What Grep Can Detect (Surface Level)
- ✓ TODO/FIXME comments
- ✓ Presence of mock keywords
- ✓ File existence
- ✓ Basic string patterns

### What AST Analysis Detects (Semantic Level)
- ✓ Empty functions
- ✓ Stub implementations
- ✓ Unreachable code
- ✓ Import resolution
- ✓ Type safety
- ✓ Mock call patterns

### What Runtime Analysis Detects (Behavioral Level)
- ✓ Actual application startup
- ✓ Real database connections
- ✓ External API calls
- ✓ Test execution with real data
- ✓ Network activity

### What PRR Gates Detect (Production Level)
- ✓ Observability configuration
- ✓ Security hardening
- ✓ CI/CD pipeline functionality
- ✓ Documentation accuracy
- ✓ Infrastructure readiness

## Recommended Toolchain

### JavaScript/TypeScript
- **ESLint** - AST-based static analysis
- **TypeScript Compiler** - Type checking
- **Jest** - Test execution
- **Supertest** - HTTP endpoint testing
- **Testcontainers** - Real database testing

### Python
- **Pylint** / **Ruff** - AST-based static analysis
- **mypy** - Type checking
- **pytest** - Test execution
- **requests** - HTTP testing
- **testcontainers-python** - Real service testing

### Universal
- **AST Explorer** - Visualize AST structure
- **jq** - JSON analysis
- **curl** / **httpie** - HTTP testing
- **docker** / **testcontainers** - Real service testing

## References

- [AST-based Static Analysis (AOSA Book)](https://aosabook.org/en/500L/static-analysis.html)
- [ESLint Developer Guide](https://eslint.org/docs/developer-guide/working-with-rules)
- [Python AST Module](https://docs.python.org/3/library/ast.html)
- [Testcontainers](https://www.testcontainers.org/)
- [Production Readiness Standards (Cortex.io)](https://www.cortex.io/post/how-to-create-a-great-production-readiness-checklist)