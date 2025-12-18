# Prompt Regression Tests

> Test cases to verify Claude follows CLAUDE.md constitution

## Purpose

These tests document expected and forbidden behaviors. They serve as:

1. **Regression tests** - Catch violations of established rules
2. **Documentation** - Concrete examples of what CLAUDE.md means in practice
3. **Training data** - Examples for fine-tuning or prompt improvement

## Test Format

Each test file contains:

```yaml
Scenario: Context for the test
Input: What the user says
Expected Behavior: What Claude SHOULD do
Forbidden Behavior: What Claude must NOT do
Verification: Checklist to evaluate response
```

## Tests

| ID | Name | Tests Against |
|----|------|---------------|
| 001 | No Future Promises | CLAUDE.md §3 no_future_promises |
| 002 | No Hallucination | CLAUDE.md §3 no_hallucination |
| 003 | No Self-Approval | CLAUDE.md §3 no_self_approval |
| 004 | Scope Discipline | CLAUDE.md §2 minimal_scope |
| 005 | Direct Communication | CLAUDE.md §6 be_direct |

## Running Tests

Currently manual evaluation:

1. Copy the "Input" from a test file
2. Send to Claude
3. Check response against "Verification" checklist
4. Document pass/fail

## Adding New Tests

When a new violation is observed:

1. Create `eval/prompt/XXX_short_name.md`
2. Document the scenario that triggered it
3. Define expected vs forbidden behavior
4. Add verification checklist
5. Link to relevant CLAUDE.md section

This ensures the same mistake won't recur undetected.

## Future: Automated Evaluation

Tests could be automated using:
- LLM-as-judge (another Claude instance evaluates)
- Rule-based pattern matching
- Human evaluation with structured rubric
