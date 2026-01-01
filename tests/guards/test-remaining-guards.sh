#!/usr/bin/env bash
# ==============================================================================
# tests/guards/test-remaining-guards.sh - remaining guard scripts tests
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

BASH_CHECK_GUARD="$ROOT_DIR/.claude/skills/access-control/guards/bash-check.sh"
PROTECTED_EDIT_GUARD="$ROOT_DIR/.claude/skills/access-control/guards/protected-edit.sh"
DEPENDS_GUARD="$ROOT_DIR/.claude/skills/playbook-gate/guards/depends-check.sh"
PENDING_GUARD="$ROOT_DIR/.claude/skills/post-loop/guards/pending-guard.sh"
COHERENCE_GUARD="$ROOT_DIR/.claude/skills/reward-guard/guards/coherence.sh"
SCOPE_GUARD="$ROOT_DIR/.claude/skills/reward-guard/guards/scope-guard.sh"
SUBTASK_GUARD="$ROOT_DIR/.claude/skills/reward-guard/guards/subtask-guard.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

TOTAL=0
PASSED=0
FAILED=0

pass() {
    echo "  ✓ $1"
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
}

fail() {
    echo "  ✗ $1"
    TOTAL=$((TOTAL + 1))
    FAILED=$((FAILED + 1))
}

setup_state() {
    local dir="$1"
    local active_playbook="$2"
    local phase="${3:-p1}"
    local security="${4:-strict}"
    mkdir -p "$dir"
    cat > "$dir/state.md" << EOF
## playbook
\`\`\`yaml
active: $active_playbook
branch: null
\`\`\`

## goal
\`\`\`yaml
phase: $phase
\`\`\`

## config
\`\`\`yaml
security: $security
\`\`\`
EOF
}

setup_depends_playbook() {
    local dir="$1"
    local dep_status="$2"
    mkdir -p "$dir/plan"
    cat > "$dir/plan/playbook-test.md" << EOF
# Playbook Test
## phases
### p0: Setup
- status: $dep_status
---
### p1: Work
- depends_on: [p0]
- status: in_progress
---
EOF
}

setup_pending_file() {
    local dir="$1"
    local status="$2"
    mkdir -p "$dir/.claude/session-state"
    cat > "$dir/.claude/session-state/post-loop-pending" << EOF
{"status":"$status","playbook":"plan/playbook-test.md"}
EOF
}

setup_coherence_env() {
    local dir="$1"
    mkdir -p "$dir/.claude/schema"
    cp "$ROOT_DIR/.claude/schema/state-schema.sh" "$dir/.claude/schema/state-schema.sh"
}

# ==============================================================================
# bash-check.sh テスト
# ==============================================================================
echo ""
echo "=== bash-check.sh テスト ==="
echo ""

test_bash_check_allow() {
    local test_dir="$TMP_DIR/bash-check-allow"
    setup_state "$test_dir" "plan/playbook-test.md"
    local input='{"tool_input":{"command":"git status"}}'
    local exit_code=0
    (cd "$test_dir" && echo "$input" | bash "$BASH_CHECK_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 0 ]]; then
        pass "playbook active + git status は許可 (exit 0)"
    else
        fail "playbook active + git status が予期しない exit code: $exit_code"
    fi
}

test_bash_check_block() {
    local test_dir="$TMP_DIR/bash-check-block"
    setup_state "$test_dir" "null"
    local input='{"tool_input":{"command":"mkdir tmpdir"}}'
    local exit_code=0
    (cd "$test_dir" && echo "$input" | bash "$BASH_CHECK_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 2 ]]; then
        pass "playbook null + mkdir はブロック (exit 2)"
    else
        fail "playbook null + mkdir が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_bash_check_allow
test_bash_check_block

# ==============================================================================
# protected-edit.sh テスト
# ==============================================================================
echo ""
echo "=== protected-edit.sh テスト ==="
echo ""

test_protected_edit_allow() {
    local input='{"tool_input":{"file_path":"'"$ROOT_DIR"'/README.md"}}'
    local exit_code=0
    (cd "$ROOT_DIR" && echo "$input" | bash "$PROTECTED_EDIT_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 0 ]]; then
        pass "保護対象外ファイルは許可 (exit 0)"
    else
        fail "保護対象外ファイルが予期しない exit code: $exit_code"
    fi
}

test_protected_edit_block() {
    local input='{"tool_input":{"file_path":"'"$ROOT_DIR"'/CLAUDE.md"}}'
    local exit_code=0
    (cd "$ROOT_DIR" && echo "$input" | bash "$PROTECTED_EDIT_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 2 ]]; then
        pass "HARD_BLOCK 対象はブロック (exit 2)"
    else
        fail "HARD_BLOCK 対象が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_protected_edit_allow
test_protected_edit_block

# ==============================================================================
# depends-check.sh テスト
# ==============================================================================
echo ""
echo "=== depends-check.sh テスト ==="
echo ""

test_depends_allow() {
    local test_dir="$TMP_DIR/depends-allow"
    setup_state "$test_dir" "plan/playbook-test.md" "p1"
    setup_depends_playbook "$test_dir" "done"
    local exit_code=0
    (cd "$test_dir" && bash "$DEPENDS_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 0 ]]; then
        pass "depends_on 完了済みなら許可 (exit 0)"
    else
        fail "depends_on 完了済みが予期しない exit code: $exit_code"
    fi
}

test_depends_warn() {
    local test_dir="$TMP_DIR/depends-warn"
    setup_state "$test_dir" "plan/playbook-test.md" "p1"
    setup_depends_playbook "$test_dir" "in_progress"
    local output
    local exit_code=0
    output=$(cd "$test_dir" && bash "$DEPENDS_GUARD" 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 0 && "$output" == *"[ERROR]"* ]]; then
        pass "depends_on 未完了を警告 (exit 0, warn output)"
    else
        fail "depends_on 未完了の警告が不正 (exit $exit_code)"
    fi
}

test_depends_allow
test_depends_warn

# ==============================================================================
# pending-guard.sh テスト
# ==============================================================================
echo ""
echo "=== pending-guard.sh テスト ==="
echo ""

test_pending_allow() {
    local test_dir="$TMP_DIR/pending-allow"
    setup_pending_file "$test_dir" "success"
    local input='{"tool_name":"Edit","tool_input":{"file_path":"'"$test_dir"'/state.md"}}'
    local exit_code=0
    (cd "$test_dir" && echo "$input" | bash "$PENDING_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 0 ]]; then
        pass "pending 中でも state.md は許可 (exit 0)"
    else
        fail "pending 中の state.md が予期しない exit code: $exit_code"
    fi
}

test_pending_block() {
    local test_dir="$TMP_DIR/pending-block"
    setup_pending_file "$test_dir" "success"
    local input='{"tool_name":"Edit","tool_input":{"file_path":"'"$test_dir"'/src/app.ts"}}'
    local exit_code=0
    (cd "$test_dir" && echo "$input" | bash "$PENDING_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 2 ]]; then
        pass "pending 中の Edit はブロック (exit 2)"
    else
        fail "pending 中の Edit が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_pending_allow
test_pending_block

# ==============================================================================
# coherence.sh テスト
# ==============================================================================
echo ""
echo "=== coherence.sh テスト ==="
echo ""

test_coherence_allow() {
    local test_dir="$TMP_DIR/coherence-allow"
    setup_coherence_env "$test_dir"
    cat > "$test_dir/state.md" << 'EOF'
## playbook
```yaml
active: null
branch: null
```

## goal
```yaml
phase: null
```

## config
```yaml
security: strict
```
EOF
    local exit_code=0
    (cd "$test_dir" && bash "$COHERENCE_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 0 ]]; then
        pass "state.md ありなら許可 (exit 0)"
    else
        fail "state.md ありで予期しない exit code: $exit_code"
    fi
}

test_coherence_block() {
    local test_dir="$TMP_DIR/coherence-block"
    setup_coherence_env "$test_dir"
    local exit_code=0
    (cd "$test_dir" && bash "$COHERENCE_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 2 ]]; then
        pass "state.md 不在はブロック (exit 2)"
    else
        fail "state.md 不在が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_coherence_allow
test_coherence_block

# ==============================================================================
# scope-guard.sh テスト
# ==============================================================================
echo ""
echo "=== scope-guard.sh テスト ==="
echo ""

test_scope_allow() {
    local input='{"tool_input":{"file_path":"'"$TMP_DIR"'/plan/playbook-test.md","old_string":"- [ ] **p1.1**: Task","new_string":"- [x] **p1.1**: Task"}}'
    local exit_code=0
    (cd "$ROOT_DIR" && echo "$input" | bash "$SCOPE_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 0 ]]; then
        pass "スコープ変更なしは許可 (exit 0)"
    else
        fail "スコープ変更なしで予期しない exit code: $exit_code"
    fi
}

test_scope_block() {
    local input='{"tool_input":{"file_path":"'"$TMP_DIR"'/plan/playbook-test.md","old_string":"done_criteria:\n  - item","new_string":"done_criteria:\n  - item\n  - extra"}}'
    local exit_code=0
    (cd "$ROOT_DIR" && echo "$input" | STRICT_MODE=true bash "$SCOPE_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 2 ]]; then
        pass "STRICT_MODE の done_criteria 変更はブロック (exit 2)"
    else
        fail "STRICT_MODE の done_criteria 変更が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_scope_allow
test_scope_block

# ==============================================================================
# subtask-guard.sh テスト
# ==============================================================================
echo ""
echo "=== subtask-guard.sh テスト ==="
echo ""

test_subtask_allow() {
    local input='{"tool_name":"Edit","tool_input":{"file_path":"'"$TMP_DIR"'/plan/playbook-test.md","old_string":"- [ ] **p1.1**: Task","new_string":"- [x] **p1.1**: Task\n  - validations:\n    - technical: \"PASS\"\n    - consistency: \"PASS\"\n    - completeness: \"PASS\"\n  - validated: 2025-12-24T00:00:00"}}'
    local exit_code=0
    (cd "$ROOT_DIR" && echo "$input" | bash "$SUBTASK_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 0 ]]; then
        pass "validations 付き subtask 完了は許可 (exit 0)"
    else
        fail "validations 付き subtask 完了が予期しない exit code: $exit_code"
    fi
}

test_subtask_block() {
    local input='{"tool_name":"Edit","tool_input":{"file_path":"'"$TMP_DIR"'/plan/playbook-test.md","old_string":"- [ ] **p1.1**: Task","new_string":"- [x] **p1.1**: Task"}}'
    local exit_code=0
    (cd "$ROOT_DIR" && echo "$input" | bash "$SUBTASK_GUARD" > /dev/null 2>&1) || exit_code=$?
    if [[ "$exit_code" -eq 2 ]]; then
        pass "validations なし subtask 完了はブロック (exit 2)"
    else
        fail "validations なし subtask 完了が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_subtask_allow
test_subtask_block

# ==============================================================================
# 結果サマリー
# ==============================================================================
echo ""
echo "=============================================="
echo "  remaining-guards テスト結果"
echo "=============================================="
echo ""
echo "  Total:  $TOTAL"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo ""

if [[ "$FAILED" -eq 0 ]]; then
    echo "  ✓ All tests passed!"
    exit 0
else
    echo "  ✗ Some tests failed"
    exit 1
fi
