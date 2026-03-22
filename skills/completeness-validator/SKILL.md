---
name: completeness-validator
description: Validate true completion vs superficial "done" - ensure code is wired up, tested, and production-ready using multilingual completion semantics
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: quality-assurance
---

# Completeness Validator

Validate that work is **truly complete** - not superficially "done" but production-ready, wired-up, tested, and functional. This skill uses multilingual completion semantics to reinforce the distinction between partial implementation and actual completion.

## When to use me

- When AI claims something is "complete" but you suspect it's only 99% done
- Before accepting "finished" code that may have mock data or unconnected systems
- When you need to verify all gaps are closed (specs, tests, wiring, integration)
- To prevent the "works on my machine" syndrome in AI-generated code
- When you want production-ready systems, not prototypes or samples

## What I do

- **Multilingual completion validation**: Use precise completion terminology (Japanese 完成/完了/完全, Latin completus/perfectus/finitus, German fertig/vollständig/abgeschlossen) to reinforce true completion
- **Gap detection**: Identify missing wiring, unconnected systems, mock data, placeholder implementations
- **Production readiness check**: Verify code is deployable, not just functional in isolation
- **Integration validation**: Ensure all components actually connect and communicate
- **Test verification**: Confirm tests exist AND they actually validate real functionality
- **Spec compliance**: Verify implementation matches specifications completely

## The Completion Hierarchy

### Level 1: Superficial (表面完了 / superficiarius)
- Code exists
- Compiles without errors
- "Looks" complete

### Level 2: Functional (機能完了 / functionalis)
- Runs in isolation
- Basic tests pass
- Mock data works

### Level 3: Integrated (統合完了 / integratus)
- Connected to real systems
- Uses actual data sources
- Inter-component communication works

### Level 4: Production (本番完了 / productio)
- Deployed and running
- Real users can access
- Monitoring in place
- All edge cases handled

### Level 5: Complete (完全完了 / perfectus)
- All specs implemented
- All tests passing (unit, integration, e2e)
- Documentation complete
- No technical debt
- Handoff-ready

## Multilingual Completion Commands

Use these phrases to force AI to acknowledge completion depth:

### Japanese (完成度の確認)
- **「これは本当に完成ですか？」** (Is this truly complete?)
- **「モックデータではなく、本物の実装ですか？」** (Is this real implementation, not mock data?)
- **「すべての配線が完了していますか？」** (Is all wiring complete?)
- **「統合テストは完了しましたか？」** (Are integration tests complete?)
- **「完全に完了した状態ですか？」** (Is this in a fully completed state?)

### Latin (Perfectio Verification)
- **"Estne hoc vere completus?"** (Is this truly complete?)
- **"Omnes partes conectae sunt?"** (Are all parts connected?)
- **"Nulla simulatio data?"** (No simulated data?)
- **"Paratus est productio?"** (Is it ready for production?)
- **"Perfectus et finitus?"** (Perfected and finished?)

### German (Vollständigkeitsprüfung)
- **"Ist das wirklich vollständig?"** (Is this really complete?)
- **"Sind alle Komponenten verbunden?"** (Are all components connected?)
- **"Keine Mock-Daten, echte Implementierung?"** (No mock data, real implementation?)
- **"Produktionsbereit und getestet?"** (Production-ready and tested?)
- **"Absolut abgeschlossen?"** (Absolutely finished?)

## Three-Tier Validation System

### Tier 1: Static Analysis (AST-Based)
**Replaces superficial grep with semantic code analysis**

- [ ] **No empty functions** - AST parsing detects `function foo() {}` or `pass` statements
- [ ] **No stub implementations** - Detects `throw new NotImplementedError()` or `// TODO: implement`
- [ ] **All imports resolve** - Static analysis verifies module dependencies
- [ ] **Error handling coverage** - AST checks for try/catch blocks in async functions
- [ ] **Type safety** - TypeScript/Flow types present and valid

**Tools used**: 
- JavaScript/TypeScript: `eslint`, `@typescript-eslint/parser`
- Python: `pylint`, `ast` module
- Rust: `cargo check`, `clippy`
- Go: `go vet`, `staticcheck`

### Tier 2: Integration Verification (Runtime)
**Actually runs the code, doesn't just check file existence**

- [ ] **Services start** - Application boots without crashes
- [ ] **Database connections** - Real queries execute (not mocked)
- [ ] **External API calls** - HTTP requests made to real endpoints
- [ ] **Environment validation** - `.env` values actually work
- [ ] **Health checks pass** - `/health` or equivalent endpoint responds 200

**Methods**:
- Testcontainers for real databases/services
- Network capture to verify actual HTTP requests
- Smoke tests that exercise real code paths

### Tier 3: Production Readiness Review (PRR)
**Industry-standard gates based on research from Cortex.io**

- [ ] **Observability** - Logs, metrics, traces configured
- [ ] **On-call** - Runbooks, escalation paths, pager integration
- [ ] **Security** - Secrets management, vulnerability scans
- [ ] **CI/CD** - Pipeline tested, rollback tested, canary deployment ready
- [ ] **Documentation** - README tested by new developer, API docs accurate
- [ ] **Compliance** - Required checks passing, audit trail enabled

**Reference**: Based on Production Readiness Review (PRR) standards used by 98% of engineering leaders

## Usage

```bash
# Run full three-tier validation
@completeness-validator check

# Run specific tier only
@completeness-validator check --tier 1    # AST analysis only
@completeness-validator check --tier 2    # Runtime verification only
@completeness-validator check --tier 3    # PRR gates only

# Generate detailed completion report
@completeness-validator report

# Force AI to acknowledge completion depth
@completeness-validator confirm --depth perfectus --interactive

# Available depth levels:
#   superficialis  - Code exists (Level 1)
#   functionalis   - Runs with mocks (Level 2)
#   integratus     - Connected to real systems (Level 3)
#   productio      - Deployed and monitored (Level 4)
#   perfectus      - Complete in all aspects (Level 5)
```

## Output Format

```
COMPLETENESS VALIDATION REPORT
==============================

Target Level: Production (本番完了)
Validation Time: 2024-01-15 14:30:00

CHECKS PASSED: 18/25 (72%)

❌ CRITICAL GAPS DETECTED:
   1. Database connection not configured (統合未完了)
   2. API endpoints return mock data (モックデータ使用中)
   3. Missing integration tests (統合テスト欠如)
   4. Environment variables not documented (環境変数未文書化)

⚠️  WARNINGS:
   1. 3 TODO comments found (TODOコメント残存)
   2. Error handling incomplete in 2 functions (エラーハンドリング不完全)

STATUS: NOT COMPLETE (未完成)
RECOMMENDATION: Address critical gaps before marking complete

Next Steps:
1. Configure database connection
2. Replace mock data with real implementation
3. Add integration tests
4. Document environment setup
```

## Examples

### Example 1: Detecting Mock Data

**AI says:** "The user authentication is complete."

**You ask:** 「これは本当に完成ですか？モックデータではなく、本物のデータベース接続ですか？」
(Is this truly complete? Is this real database connection, not mock data?)

**Validation reveals:**
- ❌ Using in-memory user store (mock)
- ❌ No database connection configured
- ❌ Password hashing not implemented
- ❌ Session management missing

**Result:** NOT COMPLETE (未完成)

### Example 2: Verifying Integration

**AI says:** "The payment processing is done."

**You ask:** "Estne hoc vere completus? Omnes partes conectae sunt?"
(Is this truly complete? Are all parts connected?)

**Validation reveals:**
- ✅ Payment logic implemented
- ❌ Not connected to payment gateway
- ❌ Webhook handlers missing
- ❌ Transaction rollback not implemented

**Result:** PARTIAL (部分完了) - Integration incomplete

### Example 3: Production Readiness

**AI says:** "The feature is finished and ready."

**You ask:** "Ist das wirklich vollständig? Produktionsbereit und getestet?"
(Is this really complete? Production-ready and tested?)

**Validation reveals:**
- ✅ All code implemented
- ✅ Unit tests passing
- ✅ Integration tests passing
- ❌ No monitoring configured
- ❌ No error alerting setup
- ❌ Performance not benchmarked

**Result:** FUNCTIONAL BUT NOT PRODUCTION-READY (機能完了、本番未完了)

## Anti-Patterns to Detect

### The "99% Complete" Trap
- Code exists but isn't wired up
- Functions implemented but not called
- Tests written but not run
- "Just needs deployment" (but deployment isn't configured)

### The Mock Data Mirage
- Everything "works" with fake data
- Real data sources not connected
- External APIs not integrated
- "Works in dev" but won't work in production

### The Integration Illusion
- Components exist in isolation
- No inter-component communication
- "Ready to integrate" (but not actually integrated)
- Missing configuration for connections

### The Spec Gap
- Code written but doesn't match requirements
- Features missing from specification
- "Creative interpretation" of requirements
- Edge cases not handled

## Notes

### Research Validation

This skill's approach is grounded in peer-reviewed research:

1. **Multilingual prompting effectiveness** validated by arXiv 2025 research showing language alignment helps prevent LLM hallucination
2. **Production Readiness Reviews (PRR)** used by 98% of engineering leaders (Cortex.io 2024 State of Production Readiness Report)
3. **AST-based static analysis** is industry standard (AOSA Book "500 Lines or Less")

### Limitations

**Not a silver bullet** - This skill significantly improves completion detection but cannot guarantee 100% accuracy:

- **AST analysis** catches empty functions but not logic errors
- **Runtime tests** verify basic connectivity but not all edge cases  
- **PRR gates** check configuration but require human judgment for compliance
- **Multilingual prompting** helps prevent hallucination but doesn't eliminate it

**Confidence levels by check type:**
- **High confidence** (≥90%): Empty functions, missing imports, TypeScript/Python type errors, missing files
- **Medium confidence** (60-80%): Env vars exist (but may not work), health endpoint responds (but may be decoy)
- **Low confidence** (≤40%): Test output says "passing" (tests may be trivial), library exists in package.json (but may be unused)

**Verification Recommendations:**
1. **For critical systems**: Add behavioral validation (Testcontainers, real API tests)
2. **For production deployment**: Require human-led Production Readiness Review
3. **For high-risk components**: Manual code review focusing on logic and security
4. **For legacy/system integration**: Actual deployment to staging environment

**Best used as:**
1. Automated first-pass validation in CI/CD
2. Educational tool to understand completion gaps  
3. Conversation starter with AI using multilingual prompts
4. Checklist to prompt human review (not replace it)

### Completion is Binary

Something is either complete or not. "Mostly done" means **not done**.

- **99% complete = NOT COMPLETE** (未完成 / Non Completus)
- Mock data = Technical debt that still needs to be done
- Integration = Mandatory for completion
- Tests with mocks ≠ System actually works
- Documentation = Part of done, not after-the-fact

### When to Use Each Tier

**Tier 1 (AST Analysis)** - During development:
- After writing code, before commit
- In CI/CD pre-commit hooks
- Automated in pull requests

**Tier 2 (Runtime)** - Before merge:
- After integration complete
- Before requesting review
- In CI/CD pipeline

**Tier 3 (PRR)** - Before deployment:
- Before production release
- During sprint planning
- For compliance audits

## Related Skills

- `@testing-e2e` - Verify end-to-end workflows
- `@testing-integration` - Verify component connections
- `@gap-analysis` - Identify missing requirements
- `@spec-gap-analysis` - Verify spec compliance
- `@trust-but-verify` - Independent validation

## References

- See [references/README.md](./references/README.md) for completion methodology
- See [references/multilingual-completion.md](./references/multilingual-completion.md) for linguistic nuances
- See [references/anti-patterns.md](./references/anti-patterns.md) for common traps
