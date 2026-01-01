#!/usr/bin/env bash
# ==============================================================================
# tests/guards/test-executor-guard.sh - executor-guard の包括的テスト
# ==============================================================================
# テスト対象:
#   - executor-guard.sh (Edit/Write)
#   - task-executor-guard.sh (Task)
#   - bash-executor-guard.sh (Bash)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARDS_DIR="$ROOT_DIR/.claude/skills/playbook-gate/guards"

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

# ==============================================================================
# テスト準備: playbook セットアップ
# ==============================================================================
setup_playbook() {
    local executor="$1"
    mkdir -p "$TMP_DIR/plan"
    cat > "$TMP_DIR/state.md" << EOF
## playbook
\`\`\`yaml
active: plan/playbook-test.md
\`\`\`

## config
\`\`\`yaml
toolstack: C
\`\`\`
EOF
    cat > "$TMP_DIR/plan/playbook-test.md" << EOF
# Playbook Test
## context
testing
## phases
### p1: Test Phase
- [ ] **p1.1**: Test task
  - executor: $executor
**status**: in_progress
EOF
}

# ==============================================================================
# Edit/Write ガードテスト
# ==============================================================================
echo ""
echo "=== executor-guard.sh (Edit/Write) テスト ==="
echo ""

# Test 1: executor: claudecode でコード編集を許可
test_edit_claudecode_allow() {
    setup_playbook "claudecode"
    local input='{"tool_input":{"file_path":"'"$TMP_DIR"'/src/app.ts","old_string":"old","new_string":"new"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: claudecode でコード編集を許可 (exit 0)"
    else
        fail "executor: claudecode で予期しない exit code: $exit_code"
    fi
}

# Test 2: executor: codex でコード編集をブロック
test_edit_codex_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"file_path":"'"$TMP_DIR"'/src/app.ts","old_string":"old","new_string":"new"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex でコード編集をブロック (exit 2)"
    else
        fail "executor: codex で予期しない exit code: $exit_code (expected 2)"
    fi
}

# Test 3: executor: codex で非コードファイル編集を許可
test_edit_codex_noncode_allow() {
    setup_playbook "codex"
    local input='{"tool_input":{"file_path":"'"$TMP_DIR"'/docs/readme.md","old_string":"old","new_string":"new"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: codex で非コードファイル編集を許可 (exit 0)"
    else
        fail "executor: codex で非コードファイル編集が予期しない exit code: $exit_code"
    fi
}

# Test 4: executor: coderabbit でコード編集をブロック
test_edit_coderabbit_block() {
    setup_playbook "coderabbit"
    local input='{"tool_input":{"file_path":"'"$TMP_DIR"'/src/app.ts","old_string":"old","new_string":"new"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: coderabbit でコード編集をブロック (exit 2)"
    else
        fail "executor: coderabbit で予期しない exit code: $exit_code (expected 2)"
    fi
}

# Test 5: executor: user でコード編集をブロック
test_edit_user_block() {
    setup_playbook "user"
    local input='{"tool_input":{"file_path":"'"$TMP_DIR"'/src/app.ts","old_string":"old","new_string":"new"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: user でコード編集をブロック (exit 2)"
    else
        fail "executor: user で予期しない exit code: $exit_code (expected 2)"
    fi
}

test_edit_claudecode_allow
test_edit_codex_block
test_edit_codex_noncode_allow
test_edit_coderabbit_block
test_edit_user_block

# ==============================================================================
# Task ガードテスト
# ==============================================================================
echo ""
echo "=== task-executor-guard.sh (Task) テスト ==="
echo ""

# Test 6: executor: claudecode で任意の SubAgent を許可
test_task_claudecode_any_allow() {
    setup_playbook "claudecode"
    local input='{"tool_input":{"subagent_type":"pm","prompt":"test"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: claudecode で任意の SubAgent を許可 (exit 0)"
    else
        fail "executor: claudecode で予期しない exit code: $exit_code"
    fi
}

# Test 7: executor: codex で codex-delegate を許可
test_task_codex_delegate_allow() {
    setup_playbook "codex"
    local input='{"tool_input":{"subagent_type":"codex-delegate","prompt":"test"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: codex で codex-delegate を許可 (exit 0)"
    else
        fail "executor: codex で codex-delegate が予期しない exit code: $exit_code"
    fi
}

# Test 8: executor: codex で pm をブロック
test_task_codex_pm_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"subagent_type":"pm","prompt":"test"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex で pm をブロック (exit 2)"
    else
        fail "executor: codex で pm が予期しない exit code: $exit_code (expected 2)"
    fi
}

# Test 9: executor: codex で Explore を許可（調査系例外）
test_task_codex_explore_allow() {
    setup_playbook "codex"
    local input='{"tool_input":{"subagent_type":"Explore","prompt":"test"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: codex で Explore を許可（調査系例外）(exit 0)"
    else
        fail "executor: codex で Explore が予期しない exit code: $exit_code"
    fi
}

# Test 10: executor: coderabbit で reviewer を許可
test_task_coderabbit_reviewer_allow() {
    setup_playbook "coderabbit"
    local input='{"tool_input":{"subagent_type":"reviewer","prompt":"test"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: coderabbit で reviewer を許可 (exit 0)"
    else
        fail "executor: coderabbit で reviewer が予期しない exit code: $exit_code"
    fi
}

# Test 11: executor: coderabbit で pm をブロック
test_task_coderabbit_pm_block() {
    setup_playbook "coderabbit"
    local input='{"tool_input":{"subagent_type":"pm","prompt":"test"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: coderabbit で pm をブロック (exit 2)"
    else
        fail "executor: coderabbit で pm が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_task_claudecode_any_allow
test_task_codex_delegate_allow
test_task_codex_pm_block
test_task_codex_explore_allow
test_task_coderabbit_reviewer_allow
test_task_coderabbit_pm_block

# ==============================================================================
# Bash ガードテスト
# ==============================================================================
echo ""
echo "=== bash-executor-guard.sh (Bash) テスト ==="
echo ""

# Test 12: executor: claudecode で任意のコマンドを許可
test_bash_claudecode_any_allow() {
    setup_playbook "claudecode"
    local input='{"tool_input":{"command":"git add ."}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: claudecode で任意のコマンドを許可 (exit 0)"
    else
        fail "executor: claudecode で予期しない exit code: $exit_code"
    fi
}

# Test 13: executor: codex で読み取り系コマンドを許可
test_bash_codex_readonly_allow() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"cat src/app.ts"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: codex で読み取り系コマンド (cat) を許可 (exit 0)"
    else
        fail "executor: codex で cat が予期しない exit code: $exit_code"
    fi
}

# Test 14: executor: codex で git status を許可
test_bash_codex_git_status_allow() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"git status"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: codex で git status を許可 (exit 0)"
    else
        fail "executor: codex で git status が予期しない exit code: $exit_code"
    fi
}

# Test 15: executor: codex で git add をブロック
test_bash_codex_git_add_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"git add ."}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex で git add をブロック (exit 2)"
    else
        fail "executor: codex で git add が予期しない exit code: $exit_code (expected 2)"
    fi
}

# Test 16: executor: codex で npm install をブロック
test_bash_codex_npm_install_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"npm install express"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex で npm install をブロック (exit 2)"
    else
        fail "executor: codex で npm install が予期しない exit code: $exit_code (expected 2)"
    fi
}

# Test 17: executor: codex でリダイレクトをブロック
test_bash_codex_redirect_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"echo test > file.txt"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex でリダイレクト (>) をブロック (exit 2)"
    else
        fail "executor: codex でリダイレクトが予期しない exit code: $exit_code (expected 2)"
    fi
}

# Test 18: executor: codex で codex コマンドを許可
test_bash_codex_codex_cmd_allow() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"codex exec \"echo hello\""}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: codex で codex コマンドを許可 (exit 0)"
    else
        fail "executor: codex で codex コマンドが予期しない exit code: $exit_code"
    fi
}

# Test 19: executor: codex で npm test を許可
test_bash_codex_npm_test_allow() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"npm test"}}'
    cd "$TMP_DIR"
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1
    local exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 0 ]]; then
        pass "executor: codex で npm test を許可 (exit 0)"
    else
        fail "executor: codex で npm test が予期しない exit code: $exit_code"
    fi
}

# Test 20: executor: codex で rm をブロック
test_bash_codex_rm_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"rm -rf node_modules"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex で rm をブロック (exit 2)"
    else
        fail "executor: codex で rm が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_bash_codex_chain_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"cat README.md; rm -rf node_modules"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex でコマンドチェーンをブロック (exit 2)"
    else
        fail "executor: codex でコマンドチェーンが予期しない exit code: $exit_code (expected 2)"
    fi
}

test_bash_codex_wrapper_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"command rm -rf node_modules"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex で command ラッパーをブロック (exit 2)"
    else
        fail "executor: codex で command ラッパーが予期しない exit code: $exit_code (expected 2)"
    fi
}

test_bash_codex_redirect_nospace_block() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"echo test>file.txt"}}'
    cd "$TMP_DIR"
    local exit_code=0
    echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" > /dev/null 2>&1 || exit_code=$?
    cd "$ROOT_DIR"
    if [[ "$exit_code" -eq 2 ]]; then
        pass "executor: codex でリダイレクト（スペースなし）をブロック (exit 2)"
    else
        fail "executor: codex でリダイレクト（スペースなし）が予期しない exit code: $exit_code (expected 2)"
    fi
}

test_bash_claudecode_any_allow
test_bash_codex_readonly_allow
test_bash_codex_git_status_allow
test_bash_codex_git_add_block
test_bash_codex_npm_install_block
test_bash_codex_redirect_block
test_bash_codex_codex_cmd_allow
test_bash_codex_npm_test_allow
test_bash_codex_rm_block
test_bash_codex_chain_block
test_bash_codex_wrapper_block
test_bash_codex_redirect_nospace_block

# ==============================================================================
# 結果サマリー
# ==============================================================================
echo ""
echo "=============================================="
echo "  executor-guard テスト結果"
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
