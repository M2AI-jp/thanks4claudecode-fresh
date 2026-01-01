# playbook-test-tdd-flow.md

> **TDD フローの動作確認用 playbook**

---

## meta

```yaml
project: test-tdd-flow
branch: feat/facade-audit-v2
created: 2026-01-01
issue: null
reviewed: true
roles:
  orchestrator: claudecode
  worker: codex
toolstack: C
priority: low
```

---

## context

This is a minimal playbook to verify the TDD flow (INIT → LOOP → CRITIQUE → POST_LOOP) works correctly.

---

## goal

```yaml
summary: Verify TDD flow works by creating and running a simple test
done_when:
  - A new test file exists at tests/tdd-flow-test.sh
  - The test passes when executed
  - The playbook is archived after completion
```

---

## phases

### p1: Create and run test

**goal**: Create a simple test file and verify it passes

#### subtasks

- [x] **p1.1**: Create a simple test file
  - executor: codex
  - validations:
    - technical: "tests/tdd-flow-test.sh exists" (verified)
    - consistency: "file contains at least one test function" (verified)
    - completeness: "bash tests/tdd-flow-test.sh exits with 0" (verified)

**status**: completed
**max_iterations**: 3
**depends_on**: []

---

## final_tasks

- [ ] **ft1**: Archive this playbook
  - command: `mv plan/playbook-test-tdd-flow.md archived/`
  - status: pending
