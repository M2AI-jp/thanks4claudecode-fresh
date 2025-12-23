# Playbook Review System

> **Status**: ACTIVE
>
> **Purpose**: Enforce mandatory review of playbooks before subtask execution

---

## Overview

The playbook-review system ensures that all playbooks are reviewed by the `reviewer` SubAgent before implementation work can begin. This implements the "作成者 ≠ 検証者" (Creator ≠ Validator) principle.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Playbook Review Flow                                         │
└─────────────────────────────────────────────────────────────┘

1. pm creates playbook (reviewed: false)
   ↓
2. PreToolUse(Edit/Write) → playbook-review-trigger.sh
   ↓
3. Hook detects reviewed: false → exit 2 (BLOCK)
   ↓
4. Claude calls reviewer SubAgent:
   Task(subagent_type='reviewer',
        prompt='playbook をレビュー。
        .claude/skills/playbook-review/frameworks/playbook-review-criteria.md を参照')
   ↓
5. reviewer validates playbook (3-stage validation)
   ↓
6. PASS → reviewer updates playbook: reviewed: true
   FAIL → reviewer suggests fixes, pm修正, goto step 5
   ↓
7. reviewed: true → work can proceed
```

---

## Components

### 1. Hook: playbook-review-trigger.sh

**Location**: `.claude/skills/playbook-review/hooks/playbook-review-trigger.sh`

**Trigger**: PreToolUse(Edit), PreToolUse(Write)

**Logic**:
```bash
if reviewed: false in active playbook:
  exit 2  # BLOCK operation
  display: "reviewer SubAgent を呼び出してください"
else:
  exit 0  # ALLOW operation
```

**Bootstrap Exceptions** (to avoid deadlock):
- Edits to `state.md` → always allowed
- Edits to playbook files themselves → always allowed (reviewer needs to modify)

**Hook Registration** (`.claude/settings.json`):
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/skills/playbook-review/hooks/playbook-review-trigger.sh",
            "timeout": 3000
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/skills/playbook-review/hooks/playbook-review-trigger.sh",
            "timeout": 3000
          }
        ]
      }
    ]
  }
}
```

### 2. SubAgent: reviewer

**Location**: `.claude/skills/playbook-review/agents/reviewer.md`

**Symlink**: `.claude/agents/reviewer.md` → `.claude/skills/playbook-review/agents/reviewer.md`

**Configuration**:
```yaml
name: reviewer
description: Code and design review agent. Evaluates playbook quality.
tools: Read, Grep, Glob, Bash
model: opus
skills: lint-checker, deploy-checker
```

**Role Assignment** (state.md):
```yaml
config:
  toolstack: B  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
  roles:
    reviewer: claudecode  # In toolstack B, claudecode handles reviews
```

### 3. Review Criteria Framework

**Location**: `.claude/skills/playbook-review/frameworks/playbook-review-criteria.md`

**Validation Stages**:

1. **Structural Validation** (形式検証)
   - Required fields present
   - Format compliance
   - YAML syntax correct

2. **Simulation** (Mental Execution)
   - Execute plan mentally from start to finish
   - Check each phase's inputs/outputs
   - Verify logical chain

3. **Adversarial Thinking** (批判的検討)
   - "What could go wrong?"
   - "What assumptions are hidden?"
   - "Is there a simpler approach?"

**Universal Criteria**:
- Input Clarity: Prerequisites明示
- Output Verifiability: done_criteria が検証可能
- Logical Chain: Phase dependencies correct
- Completeness: All necessary steps included
- Scope Clarity: What to do and NOT do
- Risk Mitigation: Risks identified with countermeasures

**Judgment**:
```yaml
PASS: All criteria met → reviewed: true
FAIL: Any critical issue → reviewed: false + issue list
```

---

## Usage

### For pm SubAgent

After creating a playbook:

```markdown
1. Create playbook with `reviewed: false`
2. Call reviewer:
   Task(subagent_type='reviewer',
        prompt='playbook をレビュー。
        .claude/skills/playbook-review/frameworks/playbook-review-criteria.md を参照')
3. If PASS: reviewer updates reviewed: true
4. If FAIL: fix issues, repeat step 2
```

### For Orchestrator (Claude Code)

When blocked by playbook-review hook:

```
[playbook-review] playbook 未レビュー
→ Call: Task(subagent_type='reviewer', prompt='playbook をレビュー')
→ Wait for PASS
→ Proceed with implementation
```

---

## Testing

### Test 1: Blocking with reviewed: false

```bash
# Create test playbook with reviewed: false
echo 'reviewed: false' > plan/playbook-test.md

# Update state.md to point to test playbook
# active: plan/playbook-test.md

# Try to Edit any file
# Result: exit 2 (BLOCKED)
```

### Test 2: Allowing with reviewed: true

```bash
# Update playbook to reviewed: true
sed -i 's/reviewed: false/reviewed: true/' plan/playbook-test.md

# Try to Edit any file
# Result: exit 0 (ALLOWED)
```

### Test 3: Bootstrap exceptions

```bash
# Even with reviewed: false, these are ALLOWED:
Edit state.md          # exit 0
Edit plan/playbook-*.md  # exit 0 (reviewer needs to modify playbooks)
```

---

## Integration Points

### 1. playbook-guard.sh

`playbook-guard.sh` handles `playbook=null` blocking.
`playbook-review-trigger.sh` handles `reviewed: false` blocking.

They are complementary:
- playbook-guard: "Do you have a plan?"
- playbook-review: "Is your plan reviewed?"

### 2. pm SubAgent

The pm agent is responsible for:
1. Creating playbooks with `reviewed: false`
2. Calling reviewer after creation
3. Handling reviewer feedback

### 3. Hook Execution Order

In `.claude/settings.json`, hooks execute in order:
```
PreToolUse(Edit):
  1. init-guard.sh
  2. check-main-branch.sh
  3. check-protected-edit.sh
  4. playbook-guard.sh        ← "Do you have a playbook?"
  5. playbook-review-trigger.sh ← "Is it reviewed?"
  6. depends-check.sh
  7. critic-guard.sh
  8. ...
```

---

## Troubleshooting

### Issue: reviewer SubAgent not found

**Symptom**: `Task(subagent_type='reviewer', ...)` fails

**Cause**: Symlink missing in `.claude/agents/`

**Fix**:
```bash
ln -sf .claude/skills/playbook-review/agents/reviewer.md \
       .claude/agents/reviewer.md
```

### Issue: Hook doesn't block

**Symptom**: Can edit files even with `reviewed: false`

**Cause**: Hook not registered in settings.json

**Fix**: Add hook to `.claude/settings.json` (see Component #1 above)

### Issue: Deadlock (cannot update reviewed: true)

**Symptom**: Blocked from editing playbook to set `reviewed: true`

**Cause**: Bootstrap exception not working

**Fix**: Check that playbook file path matches exception pattern:
```bash
if [[ "$FILE_PATH" == *"plan/playbook-"*.md ]]; then
  exit 0  # Always allow playbook edits
fi
```

---

## Files

| File | Purpose |
|------|---------|
| `.claude/skills/playbook-review/SKILL.md` | Skill specification |
| `.claude/skills/playbook-review/hooks/playbook-review-trigger.sh` | Enforcement hook |
| `.claude/skills/playbook-review/agents/reviewer.md` | Reviewer SubAgent definition |
| `.claude/skills/playbook-review/frameworks/playbook-review-criteria.md` | Review criteria |
| `.claude/agents/reviewer.md` | Symlink for SubAgent discovery |
| `.claude/settings.json` | Hook registration |
| `state.md` | reviewer role assignment |

---

## Status

- **Hook**: ACTIVE and TESTED
- **SubAgent**: CONFIGURED and DISCOVERABLE
- **Criteria**: DEFINED
- **Integration**: COMPLETE

---

## References

- CLAUDE.md § 11.1: "Golden Path" (pm required for tasks)
- CLAUDE.md § 11.2: "Playbook Gate" (playbook required for Edit/Write)
- CLAUDE.md § 11.3: "Reviewer Gate" (reviewed: true required)
- docs/design-philosophy.md: "Creator ≠ Validator" principle
- plan/template/playbook-format.md: Playbook structure with `reviewed` field

---

**Last Updated**: 2025-12-24
**Validated**: 2025-12-24 (end-to-end testing complete)
