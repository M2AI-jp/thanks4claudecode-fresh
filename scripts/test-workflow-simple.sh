#!/bin/bash
# ==============================================================================
# test-workflow-simple.sh - 簡易版ワークフローテスト
# ==============================================================================
#
# 重要: このスクリプトは scripts/ ディレクトリから実行すること
# failure-logger.sh のハング問題を回避するため、TEMP_DIR で実行する
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_ROOT/.claude/hooks"

# テンポラリディレクトリ
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# git リポジトリを初期化（main ブランチで）
git init -q --initial-branch=main "$TEMP_DIR" 2>/dev/null
(cd "$TEMP_DIR" && git commit --allow-empty -m "init" 2>/dev/null)

# カラー
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS=$((PASS + 1))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL=$((FAIL + 1))
}

# Hook を TEMP_DIR で実行するラッパー
# 戻り値: 出力は HOOK_OUTPUT に、終了コードは HOOK_EXIT に設定
run_hook_in_temp() {
    local hook="$1"
    local input="$2"
    local state_file="$3"

    local tmp_out="$TEMP_DIR/.hook_output"
    local tmp_err="$TEMP_DIR/.hook_stderr"

    # サブシェルで実行、エラーも捕捉
    (
        cd "$TEMP_DIR" || { echo "cd failed" >&2; exit 99; }
        echo "$input" | STATE_FILE="$state_file" CLAUDE_PROJECT_DIR="$TEMP_DIR" bash "$hook" >"$tmp_out" 2>"$tmp_err"
        exit $?
    )
    HOOK_EXIT=$?

    # サブシェルのエラーをチェック
    if [ "$HOOK_EXIT" -eq 99 ]; then
        echo "  [ERROR] cd to TEMP_DIR failed"
    fi

    HOOK_OUTPUT=$(cat "$tmp_out" 2>/dev/null || echo "")
    HOOK_STDERR=$(cat "$tmp_err" 2>/dev/null || echo "")

    # デバッグ出力
    if [ -n "$HOOK_STDERR" ]; then
        echo "  [DEBUG] stderr: $(echo "$HOOK_STDERR" | head -3)"
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Workflow Simple Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: playbook-guard.sh - playbook=null でブロック
# ==============================================================================
echo "Test 1: playbook-guard.sh (playbook=null)"

cat > "$TEMP_DIR/state.md" << 'EOF'
# state.md

## playbook

```yaml
active: null
```

## config

```yaml
security: strict
```
EOF

run_hook_in_temp "$HOOKS_DIR/playbook-guard.sh" \
    '{"tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 2 ]; then
    pass "playbook=null でブロック (exit=2)"
else
    fail "Expected exit=2, got exit=$HOOK_EXIT"
    echo "  Output: $HOOK_OUTPUT"
fi

# ==============================================================================
# Test 2: playbook-guard.sh - playbook=active で許可
# ==============================================================================
echo "Test 2: playbook-guard.sh (playbook=active)"

cat > "$TEMP_DIR/playbook-test.md" << 'EOF'
# playbook-test.md

## meta

```yaml
reviewed: true
```

## phases

### p1

- executor: claudecode

**status**: in_progress
EOF

cat > "$TEMP_DIR/state.md" << EOF
# state.md

## playbook

\`\`\`yaml
active: $TEMP_DIR/playbook-test.md
\`\`\`

## config

\`\`\`yaml
security: strict
\`\`\`
EOF

run_hook_in_temp "$HOOKS_DIR/playbook-guard.sh" \
    '{"tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 0 ]; then
    pass "playbook=active で許可 (exit=0)"
else
    fail "Expected exit=0, got exit=$HOOK_EXIT"
    echo "  Output: $HOOK_OUTPUT"
fi

# ==============================================================================
# Test 3: executor-guard.sh - executor=claudecode で許可
# ==============================================================================
echo "Test 3: executor-guard.sh (executor=claudecode)"

cat > "$TEMP_DIR/state.md" << EOF
# state.md

## playbook

\`\`\`yaml
active: $TEMP_DIR/playbook-test.md
\`\`\`

## config

\`\`\`yaml
toolstack: B
\`\`\`
EOF

run_hook_in_temp "$HOOKS_DIR/executor-guard.sh" \
    '{"tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 0 ]; then
    pass "executor=claudecode で許可 (exit=0)"
else
    fail "Expected exit=0, got exit=$HOOK_EXIT"
    echo "  Output: $HOOK_OUTPUT"
fi

# ==============================================================================
# Test 4: executor-guard.sh - executor=codex でブロック
# ==============================================================================
echo "Test 4: executor-guard.sh (executor=codex)"

cat > "$TEMP_DIR/playbook-test.md" << 'EOF'
# playbook-test.md

## phases

### p1

- executor: codex
  status: in_progress
EOF

run_hook_in_temp "$HOOKS_DIR/executor-guard.sh" \
    '{"tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 2 ]; then
    pass "executor=codex でブロック (exit=2)"
else
    fail "Expected exit=2, got exit=$HOOK_EXIT"
    echo "  Output: $HOOK_OUTPUT"
    echo "  Playbook content:"
    cat "$TEMP_DIR/playbook-test.md"
fi

# ==============================================================================
# Test 5: contract.sh - playbook=null でブロック
# ==============================================================================
echo "Test 5: contract.sh (playbook=null)"

if [ -f "$SCRIPT_DIR/contract.sh" ]; then
    cat > "$TEMP_DIR/state.md" << 'EOF'
# state.md

## playbook

```yaml
active: null
```

## config

```yaml
security: strict
```
EOF

    source "$SCRIPT_DIR/contract.sh"

    if ! STATE_FILE="$TEMP_DIR/state.md" contract_check_edit "src/main.ts" 2>/dev/null; then
        pass "contract_check_edit: playbook=null でブロック"
    else
        fail "contract_check_edit should block with playbook=null"
    fi
else
    echo "[SKIP] contract.sh not found"
fi

# ==============================================================================
# Test 6: pending-guard.sh - pending あり + 非 main ブランチでブロック
# ==============================================================================
echo "Test 6: pending-guard.sh (pending file exists, non-main branch)"

# pending ファイル作成
mkdir -p "$TEMP_DIR/.claude/session-state"
cat > "$TEMP_DIR/.claude/session-state/post-loop-pending" << 'EOF'
{
  "playbook": "playbook-test.md",
  "status": "success"
}
EOF

# 非 main ブランチを作成
(cd "$TEMP_DIR" && git checkout -b feat/test 2>/dev/null)

PENDING_GUARD="$REPO_ROOT/.claude/skills/post-loop/guards/pending-guard.sh"
run_hook_in_temp "$PENDING_GUARD" \
    '{"tool_name": "Edit", "tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 2 ]; then
    pass "pending あり + 非 main ブランチでブロック (exit=2)"
else
    fail "Expected exit=2, got exit=$HOOK_EXIT"
fi

# ==============================================================================
# Test 7: pending-guard.sh - pending あり + main ブランチで許可
# ==============================================================================
echo "Test 7: pending-guard.sh (pending file exists, main branch)"

# main ブランチに戻る
(cd "$TEMP_DIR" && git checkout main 2>/dev/null)

run_hook_in_temp "$PENDING_GUARD" \
    '{"tool_name": "Edit", "tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 0 ]; then
    pass "pending あり + main ブランチで許可 (exit=0)"
else
    fail "Expected exit=0, got exit=$HOOK_EXIT"
fi

# ==============================================================================
# Test 8: SessionStart Hook chain - pending ファイルを自動削除
# ==============================================================================
echo "Test 8: SessionStart Hook chain (auto cleanup pending file)"

# pending ファイルを再作成
cat > "$TEMP_DIR/.claude/session-state/post-loop-pending" << 'EOF'
{
  "playbook": "playbook-test.md",
  "status": "success"
}
EOF

# 必要なファイルを TEMP_DIR に作成
mkdir -p "$TEMP_DIR/.claude/schema"
cp "$REPO_ROOT/.claude/schema/state-schema.sh" "$TEMP_DIR/.claude/schema/" 2>/dev/null || true

# 最小限の state.md を作成
cat > "$TEMP_DIR/state.md" << 'EOF'
# state.md

## playbook

```yaml
active: null
```

## session

```yaml
last_start: null
last_end: null
```
EOF

# 実際の Hook チェーンを実行: session.sh -> start.sh
# session.sh は session-manager/handlers/start.sh を呼び出す
START_SH="$REPO_ROOT/.claude/skills/session-manager/handlers/start.sh"
(
    cd "$TEMP_DIR"
    # start.sh を直接実行（session.sh の invoke_skill と同等）
    echo '{"trigger": "startup"}' | bash "$START_SH" >/dev/null 2>&1 || true
)

if [ ! -f "$TEMP_DIR/.claude/session-state/post-loop-pending" ]; then
    pass "SessionStart Hook chain で pending ファイルを自動削除"
else
    fail "pending file still exists after SessionStart"
fi

# ==============================================================================
# サマリー
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PASS: $PASS / FAIL: $FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
