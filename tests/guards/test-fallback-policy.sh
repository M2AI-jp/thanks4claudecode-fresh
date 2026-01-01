#!/bin/bash
# test-fallback-policy.sh - フォールバックポリシーのテスト
#
# 目的:
#   1. BLOCK メッセージに AskUserQuestion 案内が含まれることを確認
#   2. BLOCK メッセージに docs/executor-fallback-policy.md 参照が含まれることを確認
#   3. 3 パターン（codex/coderabbit/user）全てにフォールバック案内があることを確認

set -uo pipefail

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# カウンター
TOTAL=0
PASSED=0
FAILED=0

# テスト結果表示
pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASSED++))
    ((TOTAL++))
}

fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAILED++))
    ((TOTAL++))
}

# ============================================================
# セットアップ
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARDS_DIR="$SCRIPT_DIR/../../.claude/skills/playbook-gate/guards"
TMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# テスト用 playbook を作成
setup_playbook() {
    local executor="$1"

    # state.md を作成
    cat > "$TMP_DIR/state.md" << 'EOF'
# state.md

## playbook

```yaml
active: playbook-test.md
```

## config

```yaml
toolstack: C
```
EOF

    # playbook を作成
    cat > "$TMP_DIR/playbook-test.md" << EOF
# playbook-test.md

## context

test context

## phases

### p1: Test Phase

- executor: $executor
- **status**: in_progress
EOF
}

# ============================================================
# executor-guard.sh のメッセージテスト
# ============================================================

echo "=== executor-guard.sh フォールバックメッセージテスト ==="
echo ""

# Test 1: codex のメッセージに AskUserQuestion が含まれる
test_codex_message_has_askuserquestion() {
    setup_playbook "codex"
    local input='{"tool_input":{"file_path":"src/test.ts"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "AskUserQuestion"; then
        pass "executor: codex のメッセージに AskUserQuestion が含まれる"
    else
        fail "executor: codex のメッセージに AskUserQuestion が含まれない"
    fi
}

# Test 2: codex のメッセージにドキュメント参照が含まれる
test_codex_message_has_doc_reference() {
    setup_playbook "codex"
    local input='{"tool_input":{"file_path":"src/test.ts"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "executor-fallback-policy.md"; then
        pass "executor: codex のメッセージに docs 参照が含まれる"
    else
        fail "executor: codex のメッセージに docs 参照が含まれない"
    fi
}

# Test 3: codex のメッセージに CLI フォールバックが含まれる
test_codex_message_has_cli_fallback() {
    setup_playbook "codex"
    local input='{"tool_input":{"file_path":"src/test.ts"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "codex exec"; then
        pass "executor: codex のメッセージに CLI フォールバックが含まれる"
    else
        fail "executor: codex のメッセージに CLI フォールバックが含まれない"
    fi
}

# Test 4: coderabbit のメッセージに AskUserQuestion が含まれる
test_coderabbit_message_has_askuserquestion() {
    setup_playbook "coderabbit"
    local input='{"tool_input":{"file_path":"src/test.ts"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "AskUserQuestion"; then
        pass "executor: coderabbit のメッセージに AskUserQuestion が含まれる"
    else
        fail "executor: coderabbit のメッセージに AskUserQuestion が含まれない"
    fi
}

# Test 5: coderabbit のメッセージにドキュメント参照が含まれる
test_coderabbit_message_has_doc_reference() {
    setup_playbook "coderabbit"
    local input='{"tool_input":{"file_path":"src/test.ts"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "executor-fallback-policy.md"; then
        pass "executor: coderabbit のメッセージに docs 参照が含まれる"
    else
        fail "executor: coderabbit のメッセージに docs 参照が含まれない"
    fi
}

# Test 6: user のメッセージに AskUserQuestion が含まれる
test_user_message_has_askuserquestion() {
    setup_playbook "user"
    local input='{"tool_input":{"file_path":"src/test.ts"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "AskUserQuestion"; then
        pass "executor: user のメッセージに AskUserQuestion が含まれる"
    else
        fail "executor: user のメッセージに AskUserQuestion が含まれない"
    fi
}

# Test 7: user のメッセージにドキュメント参照が含まれる
test_user_message_has_doc_reference() {
    setup_playbook "user"
    local input='{"tool_input":{"file_path":"src/test.ts"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "executor-fallback-policy.md"; then
        pass "executor: user のメッセージに docs 参照が含まれる"
    else
        fail "executor: user のメッセージに docs 参照が含まれない"
    fi
}

test_codex_message_has_askuserquestion
test_codex_message_has_doc_reference
test_codex_message_has_cli_fallback
test_coderabbit_message_has_askuserquestion
test_coderabbit_message_has_doc_reference
test_user_message_has_askuserquestion
test_user_message_has_doc_reference

echo ""

# ============================================================
# task-executor-guard.sh のメッセージテスト
# ============================================================

echo "=== task-executor-guard.sh フォールバックメッセージテスト ==="
echo ""

# Test 8: codex の Task ブロックメッセージに AskUserQuestion が含まれる
test_task_codex_message_has_askuserquestion() {
    setup_playbook "codex"
    local input='{"tool_input":{"subagent_type":"pm"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "AskUserQuestion"; then
        pass "Task executor: codex のメッセージに AskUserQuestion が含まれる"
    else
        fail "Task executor: codex のメッセージに AskUserQuestion が含まれない"
    fi
}

# Test 9: codex の Task ブロックメッセージにドキュメント参照が含まれる
test_task_codex_message_has_doc_reference() {
    setup_playbook "codex"
    local input='{"tool_input":{"subagent_type":"pm"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "executor-fallback-policy.md"; then
        pass "Task executor: codex のメッセージに docs 参照が含まれる"
    else
        fail "Task executor: codex のメッセージに docs 参照が含まれない"
    fi
}

# Test 10: coderabbit の Task ブロックメッセージに AskUserQuestion が含まれる
test_task_coderabbit_message_has_askuserquestion() {
    setup_playbook "coderabbit"
    local input='{"tool_input":{"subagent_type":"pm"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "AskUserQuestion"; then
        pass "Task executor: coderabbit のメッセージに AskUserQuestion が含まれる"
    else
        fail "Task executor: coderabbit のメッセージに AskUserQuestion が含まれない"
    fi
}

# Test 11: user の Task 警告メッセージに AskUserQuestion が含まれる
test_task_user_message_has_askuserquestion() {
    setup_playbook "user"
    local input='{"tool_input":{"subagent_type":"pm"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/task-executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "AskUserQuestion"; then
        pass "Task executor: user のメッセージに AskUserQuestion が含まれる"
    else
        fail "Task executor: user のメッセージに AskUserQuestion が含まれない"
    fi
}

test_task_codex_message_has_askuserquestion
test_task_codex_message_has_doc_reference
test_task_coderabbit_message_has_askuserquestion
test_task_user_message_has_askuserquestion

echo ""

# ============================================================
# bash-executor-guard.sh のメッセージテスト
# ============================================================

echo "=== bash-executor-guard.sh フォールバックメッセージテスト ==="
echo ""

# Test 12: codex の Bash ブロックメッセージに AskUserQuestion が含まれる
test_bash_codex_message_has_askuserquestion() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"git add ."}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "AskUserQuestion"; then
        pass "Bash executor: codex のメッセージに AskUserQuestion が含まれる"
    else
        fail "Bash executor: codex のメッセージに AskUserQuestion が含まれない"
    fi
}

# Test 13: codex の Bash ブロックメッセージにドキュメント参照が含まれる
test_bash_codex_message_has_doc_reference() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"git add ."}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "executor-fallback-policy.md"; then
        pass "Bash executor: codex のメッセージに docs 参照が含まれる"
    else
        fail "Bash executor: codex のメッセージに docs 参照が含まれない"
    fi
}

# Test 14: codex の Bash ブロックメッセージに CLI フォールバックが含まれる
test_bash_codex_message_has_cli_fallback() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"git add ."}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "codex exec"; then
        pass "Bash executor: codex のメッセージに CLI フォールバックが含まれる"
    else
        fail "Bash executor: codex のメッセージに CLI フォールバックが含まれない"
    fi
}

# Test 15: リダイレクト (>) ブロックメッセージに AskUserQuestion が含まれる
test_bash_redirect_message_has_askuserquestion() {
    setup_playbook "codex"
    local input='{"tool_input":{"command":"echo test > file.txt"}}'
    cd "$TMP_DIR"
    local output
    output=$(echo "$input" | STATE_FILE="$TMP_DIR/state.md" bash "$GUARDS_DIR/bash-executor-guard.sh" 2>&1 || true)

    if echo "$output" | grep -q "AskUserQuestion"; then
        pass "Bash リダイレクトブロックメッセージに AskUserQuestion が含まれる"
    else
        fail "Bash リダイレクトブロックメッセージに AskUserQuestion が含まれない"
    fi
}

test_bash_codex_message_has_askuserquestion
test_bash_codex_message_has_doc_reference
test_bash_codex_message_has_cli_fallback
test_bash_redirect_message_has_askuserquestion

echo ""

# ============================================================
# 結果表示
# ============================================================

echo "=============================================="
echo "  フォールバックポリシーテスト結果"
echo "=============================================="
echo ""
echo "  Total:  $TOTAL"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "  ${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "  ${RED}✗ Some tests failed${NC}"
    exit 1
fi
