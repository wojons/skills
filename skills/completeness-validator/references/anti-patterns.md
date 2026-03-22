# Completion Anti-Patterns

Common traps that make work appear complete when it's not actually done.

## The "99% Complete" Trap

### Description
Work appears nearly finished but lacks critical final connections that make it functional.

### Symptoms
- "Just needs to be wired up"
- "Ready to integrate"
- "Code is written but not tested"
- "Works in isolation"
- "Just needs deployment"

### Why It Happens
1. **Last-mile problem**: The final 1% requires the most effort (integration, testing, deployment)
2. **Comfort zone**: Developers prefer writing new code over debugging integration issues
3. **False progress**: Code volume is mistaken for completion
4. **Integration fear**: Avoiding the hard work of making components talk to each other

### Detection
```bash
# Check for unwired components
grep -r "TODO.*connect\|FIXME.*integrate\|XXX.*wire" --include="*.js" --include="*.ts" --include="*.py" .

# Check for unimplemented functions
grep -r "pass\|NotImplementedError\|todo\|unimplemented" --include="*.py" .
grep -r "// TODO\|// FIXME\|/* TODO" --include="*.js" --include="*.ts" .
```

### Prevention
- Require integration before marking complete
- Test with real dependencies, not mocks
- Deploy to staging before claiming "done"
- Use "Definition of Done" that includes integration

## The Mock Data Mirage

### Description
Everything "works" beautifully with fake data, but fails with real data sources.

### Symptoms
- "Works perfectly in dev"
- "Just need to swap out the mock"
- "Database connection not configured yet"
- "Using sample data for now"
- "API integration coming soon"

### Why It Happens
1. **Path of least resistance**: Mocks are easier than real integrations
2. **External dependency**: Waiting for API keys, database access, etc.
3. **Demo pressure**: Showing progress with mocks satisfies stakeholders
4. **Integration complexity**: Real systems have auth, rate limits, errors

### Detection
```bash
# Check for mock patterns
grep -ri "mock\|fake\|stub\|dummy\|placeholder\|sample.*data" \
  --include="*.js" --include="*.ts" --include="*.py" --include="*.go" .

# Check for hardcoded data
find . -name "*.json" -o -name "*.csv" | xargs grep -l "test\|sample\|dummy" 2>/dev/null

# Check for in-memory databases
find . -name "*.js" -o -name "*.ts" -o -name "*.py" | xargs grep -l "memory\|sqlite.*:memory:" 2>/dev/null
```

### Prevention
- Never accept mocks as "done"
- Require real data source connection
- Test with production-like data volumes
- Validate error handling with real systems

## The Integration Illusion

### Description
Components exist in isolation but don't actually communicate with each other.

### Symptoms
- "Frontend is done, backend is done"
- "Services are ready to talk to each other"
- "API is implemented but not called"
- "Database schema is ready"
- "Just need to hook them up"

### Why It Happens
1. **Siloed development**: Teams work independently
2. **Interface assumptions**: Assuming integration will "just work"
3. **Late integration**: Leaving integration to the end
4. **Contract drift**: Frontend and backend evolve separately

### Detection
```bash
# Check for API calls
find . -name "*.js" -o -name "*.ts" | xargs grep -l "fetch\|axios\|http" 2>/dev/null

# Check if endpoints are actually called
grep -r "api\|endpoint" --include="*.js" --include="*.ts" frontend/ | wc -l

# Check for database queries in backend
grep -r "SELECT\|INSERT\|UPDATE\|DELETE" --include="*.py" --include="*.js" backend/ | wc -l
```

### Prevention
- Integrate early and often
- Test end-to-end from day one
- Use contract testing
- Require working integration before "done"

## The Spec Gap

### Description
Code is written but doesn't actually implement the requirements.

### Symptoms
- "I interpreted the requirement differently"
- "This is a creative solution"
- "The spec wasn't clear"
- "I added some extra features"
- "This is better than what was asked"

### Why It Happens
1. **Ambiguity**: Requirements are unclear or incomplete
2. **Creativity**: Developer thinks they know better
3. **Scope creep**: Adding unrequested features
4. **Misunderstanding**: Different interpretation of requirements

### Detection
```bash
# Compare implementation to spec
# (Manual process - requires spec review)

# Check for feature flags that hide incomplete work
grep -r "feature.*flag\|toggle\|enable.*feature" --include="*.js" --include="*.ts" --include="*.py" .

# Check for partial implementations
find . -name "*.js" -o -name "*.ts" -o -name "*.py" | xargs grep -l "partial\|incomplete\|wip" 2>/dev/null
```

### Prevention
- Write acceptance criteria before coding
- Demo to stakeholders frequently
- Use behavior-driven development
- Require spec sign-off before starting

## The Test Theater

### Description
Tests exist and pass, but don't actually validate real functionality.

### Symptoms
- "Tests are passing"
- "100% code coverage"
- "All green"
- But: bugs still exist in production

### Why It Happens
1. **Mock testing**: Tests use mocks instead of real dependencies
2. **Happy path only**: Tests don't cover edge cases
3. **Assertion weakness**: Tests assert trivial truths
4. **Coverage obsession**: Chasing coverage over quality

### Detection
```bash
# Check for mock-heavy tests
grep -r "mock\|jest.mock\|sinon\|stub" --include="*.test.js" --include="*.spec.js" . | wc -l

# Check test assertions
grep -r "expect.*toBe\|assert.*equal" --include="*.test.js" --include="*.spec.js" . | head -20

# Check for integration tests
find . -name "*.test.js" -o -name "*.spec.js" | xargs grep -l "integration\|e2e\|end.*to.*end" 2>/dev/null | wc -l
```

### Prevention
- Require integration tests, not just unit tests
- Test with real data sources
- Include negative test cases
- Test actual user workflows

## The Documentation Mirage

### Description
Documentation exists but is incomplete, outdated, or unclear.

### Symptoms
- "Documentation is done"
- "README exists"
- But: new developers can't set up the project
- But: deployment process is unclear
- But: API usage is not documented

### Why It Happens
1. **Afterthought**: Documentation written after coding
2. **Knowledge gap**: Author assumes reader knowledge
3. **Outdated**: Code changed, docs didn't
4. **Minimalism**: Doing the minimum to check the box

### Detection
```bash
# Check README completeness
wc -l README.md

# Check for setup instructions
grep -i "setup\|install\|getting started" README.md

# Check for API documentation
find . -name "*.md" | xargs grep -l "api\|endpoint" 2>/dev/null | wc -l

# Check for environment documentation
ls -la .env* 2>/dev/null | wc -l
```

### Prevention
- Write docs before code (documentation-driven development)
- Have new developers test the setup
- Include documentation in Definition of Done
- Review docs in code review

## The Configuration Gap

### Description
Code works on developer's machine but won't work anywhere else.

### Symptoms
- "Works on my machine"
- "You need to set up the environment"
- "Did you install X?"
- "Oh, you need the .env file"
- "It's in the wiki somewhere"

### Why It Happens
1. **Local state**: Dependencies on local configuration
2. **Undocumented setup**: Steps exist only in developer's head
3. **Secret sprawl**: Credentials scattered across systems
4. **Environment drift**: Dev, staging, production differ

### Detection
```bash
# Check for environment dependencies
grep -r "process.env\|os.environ\|ENV\[" --include="*.js" --include="*.ts" --include="*.py" . | wc -l

# Check for hardcoded paths
grep -r "/Users/\|/home/\|C:\\" --include="*.js" --include="*.ts" --include="*.py" .

# Check for missing config files
ls -la docker-compose.yml Dockerfile .env.example 2>/dev/null
```

### Prevention
- Containerize the application
- Document all environment variables
- Use infrastructure as code
- Test in clean environment

## The Error Handling Omission

### Description
Happy path works, but error cases are unhandled.

### Symptoms
- "It works when everything goes right"
- "We can add error handling later"
- "That's an edge case"
- "Users won't do that"
- "The API never returns errors"

### Why It Happens
1. **Optimism**: Assuming everything will work
2. **Time pressure**: Error handling is "extra"
3. **Complexity**: Error handling is hard
4. **Unknown unknowns**: Not knowing what can fail

### Detection
```bash
# Check for try-catch blocks
find . -name "*.js" -o -name "*.ts" -o -name "*.py" | xargs grep -l "try\|catch\|except" 2>/dev/null | wc -l

# Check for error returns
grep -r "return.*error\|throw\|raise" --include="*.js" --include="*.ts" --include="*.py" . | wc -l

# Check for validation
grep -r "validate\|sanitize\|check" --include="*.js" --include="*.ts" --include="*.py" . | wc -l
```

### Prevention
- Require error handling in Definition of Done
- Test failure scenarios
- Use chaos engineering
- Review error handling in code review

## The Performance Lie

### Description
Code works with small data but fails at scale.

### Symptoms
- "It works with test data"
- "Performance optimization is phase 2"
- "We'll optimize if needed"
- "It's fast enough"
- "Users won't have that much data"

### Why It Happens
1. **Small data testing**: Never tested with production volumes
2. **Premature optimization fear**: Avoiding performance work
3. **Unknown constraints**: Not knowing production requirements
4. **Technical debt**: Quick implementation over scalable one

### Detection
```bash
# Check for obvious performance issues
grep -r "for.*in.*for\|while.*while\|N\+1" --include="*.js" --include="*.ts" --include="*.py" .

# Check for pagination
grep -r "limit\|offset\|page\|cursor" --include="*.js" --include="*.ts" --include="*.py" . | wc -l

# Check for caching
grep -r "cache\|redis\|memoize" --include="*.js" --include="*.ts" --include="*.py" . | wc -l
```

### Prevention
- Test with production-like data
- Set performance benchmarks
- Load test before release
- Monitor performance in production

## The Security Afterthought

### Description
Functionality works but security is not implemented.

### Symptoms
- "Security is not in scope"
- "We'll add auth later"
- "This is just an MVP"
- "It's internal only"
- "We'll audit later"

### Why It Happens
1. **Speed pressure**: Security slows down development
2. **Complexity**: Security is hard to get right
3. **False confidence**: "We're not a target"
4. **Late consideration**: Security added at the end

### Detection
```bash
# Check for auth
grep -r "auth\|login\|password\|token" --include="*.js" --include="*.ts" --include="*.py" . | wc -l

# Check for input validation
grep -r "sanitize\|escape\|validate" --include="*.js" --include="*.ts" --include="*.py" . | wc -l

# Check for HTTPS
grep -r "http://" --include="*.js" --include="*.ts" --include="*.py" . | grep -v "localhost" | wc -l
```

### Prevention
- Security review in Definition of Done
- Use security scanning tools
- Penetration testing
- Security by design

## Summary: The True Definition of Done

Work is not complete until:

1. ✅ **Code is written** - And compiles without errors
2. ✅ **Tests pass** - Unit, integration, and E2E
3. ✅ **Integration works** - All components communicate
4. ✅ **Real data flows** - No mocks in production path
5. ✅ **Error handling** - All failure cases covered
6. ✅ **Documentation** - Setup, usage, and deployment
7. ✅ **Configuration** - Works in any environment
8. ✅ **Performance** - Meets benchmarks
9. ✅ **Security** - Reviewed and approved
10. ✅ **Deployed** - Running in production

**Remember**: "99% complete" means **not complete**.