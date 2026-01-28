# Reward Guard Inventory

**Purpose**: Document all reward fraud prevention mechanisms in the repository.

## Guard Scripts

| Guard | Path | Purpose | BLOCK Condition |
|-------|------|---------|-----------------|
| critic-guard.sh | .claude/skills/reward-guard/guards/critic-guard.sh | Requires critic validation before done claims | done status without validated_by: critic |
| subtask-guard.sh | .claude/skills/reward-guard/guards/subtask-guard.sh | Requires evidence for all validation fields | status: done without validation evidence |
| phase-status-guard.sh | .claude/skills/reward-guard/guards/phase-status-guard.sh | Prevents skipping phase dependencies | Phase marked done before dependencies |
| scope-guard.sh | .claude/skills/reward-guard/guards/scope-guard.sh | Prevents scope creep beyond playbook | Changes outside playbook scope |
| completion-check.sh | .claude/skills/reward-guard/guards/completion-check.sh | Verifies all criteria before completion | Incomplete done_criteria |
| progress-reminder.sh | .claude/skills/reward-guard/guards/progress-reminder.sh | Reminds about progress tracking | Stale progress.json |
| coherence.sh | .claude/skills/reward-guard/guards/coherence.sh | Checks state consistency | state.md inconsistency |

## Fraud Prevention Mechanisms

### 1. Critic Validation Required
- **File**: critic-guard.sh
- **Trigger**: PreToolUse:Edit on progress.json
- **Protection**: Claude cannot self-certify done status
- **BLOCK**: If validated_by is not 'critic'

### 2. Evidence Requirement
- **File**: subtask-guard.sh
- **Trigger**: PreToolUse:Write on progress.json
- **Protection**: All validation fields must have evidence
- **BLOCK**: If technical/consistency/completeness PASS without evidence

### 3. Phase Dependencies
- **File**: phase-status-guard.sh
- **Trigger**: PreToolUse:Edit on progress.json
- **Protection**: Phases must complete in order
- **BLOCK**: If dependent phases not done

### 4. Scope Control
- **File**: scope-guard.sh
- **Trigger**: PreToolUse:Edit
- **Protection**: Changes must be within playbook scope
- **BLOCK**: If file outside scope.includes

### 5. Completion Verification
- **File**: completion-check.sh
- **Trigger**: PostToolUse:Edit on progress.json
- **Protection**: All done_when criteria must pass
- **BLOCK**: If any criterion fails

### 6. Progress Tracking
- **File**: progress-reminder.sh
- **Trigger**: Periodic
- **Protection**: Prevents forgetting to update progress
- **BLOCK**: N/A (reminder only)

### 7. State Coherence
- **File**: coherence.sh
- **Trigger**: PreToolUse:Edit
- **Protection**: state.md must be consistent with playbook
- **BLOCK**: If state.md contradicts playbook status

## Summary

| Metric | Value |
|--------|-------|
| Total Guards | 7 |
| BLOCK Guards | 5 |
| Reminder Guards | 2 |
| Coverage | critic, subtask, phase, scope, completion, coherence |
