#!/bin/bash
# ==============================================================================
# test-workflow-state-transition.sh - ワークフロー状態遷移テスト
# ==============================================================================
#
# 目的: playbook 作成 → 作業 → 完了 → archive の全フローを検証
#
# テストシナリオ:
#   1. INIT: playbook=null → 変更系操作がブロック
#   2. PLAYBOOK_CREATED: playbook 作成 → 変更系操作が許可
#   3. WORK_IN_PROGRESS: phase 作業中 → executor 制約が動作
#   4. PHASE_DONE: phase 完了 → critic 必須チェック
#   5. PLAYBOOK_COMPLETE: 全 phase 完了 → archive 提案
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_ROOT/.claude/hooks"

# テンポラリディレクトリ
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

git init -q "$TEMP_DIR" 2>/dev/null

# カラー
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    PASS=$((PASS + 1))
}

fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    FAIL=$((FAIL + 1))
}

section() {
    echo -e "\n${BLUE}━━━ $1 ━━━${NC}"
}

# Hook を TEMP_DIR で実行
run_hook() {
    local hook="$1"
    local input="$2"
    local state_file="$3"

    local tmp_out="$TEMP_DIR/.hook_output"
    local tmp_err="$TEMP_DIR/.hook_stderr"

    (
        cd "$TEMP_DIR"
        echo "$input" | STATE_FILE="$state_file" CLAUDE_PROJECT_DIR="$TEMP_DIR" bash "$hook" >"$tmp_out" 2>"$tmp_err"
    )
    HOOK_EXIT=$?

    HOOK_OUTPUT=$(cat "$tmp_out" 2>/dev/null || echo "")
    HOOK_STDERR=$(cat "$tmp_err" 2>/dev/null || echo "")
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ワークフロー状態遷移テスト"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ==============================================================================
# シナリオ 1: INIT (playbook=null)
# ==============================================================================
section "シナリオ 1: INIT (playbook=null)"

# 状態: playbook が存在しない
cat > "$TEMP_DIR/state.md" << 'EOF'
# state.md

## focus

```yaml
current: product
```

## playbook

```yaml
active: null
```

## config

```yaml
security: strict
```
EOF

echo "状態: playbook=null"

# 1-1: Edit がブロックされる
run_hook "$HOOKS_DIR/playbook-guard.sh" \
    '{"tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 2 ]; then
    pass "Edit がブロックされる (exit=2)"
else
    fail "Edit がブロックされるべき (got exit=$HOOK_EXIT)"
fi

# 1-2: state.md の編集は許可
run_hook "$HOOKS_DIR/playbook-guard.sh" \
    '{"tool_input": {"file_path": "state.md"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 0 ]; then
    pass "state.md は編集可能 (exit=0)"
else
    fail "state.md は編集可能であるべき (got exit=$HOOK_EXIT)"
fi

# 1-3: playbook ファイルの作成は許可（ブートストラップ例外）
run_hook "$HOOKS_DIR/playbook-guard.sh" \
    '{"tool_input": {"file_path": "plan/playbook-new.md"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 0 ]; then
    pass "playbook 作成は許可 (ブートストラップ例外)"
else
    fail "playbook 作成は許可されるべき (got exit=$HOOK_EXIT)"
fi

# ==============================================================================
# シナリオ 2: PLAYBOOK_CREATED (playbook 作成後)
# ==============================================================================
section "シナリオ 2: PLAYBOOK_CREATED"

# playbook を作成
cat > "$TEMP_DIR/playbook-test.md" << 'EOF'
# playbook-test.md

## meta

```yaml
reviewed: true
```

## phases

### p1

- executor: claudecode
  status: in_progress

### p2

- executor: claudecode
  status: pending
EOF

# state.md を更新（注: grep -A3 で両方取得できるよう順序に注意）
cat > "$TEMP_DIR/state.md" << EOF
# state.md

## focus

\`\`\`yaml
current: product
\`\`\`

## playbook

\`\`\`yaml
active: $TEMP_DIR/playbook-test.md
\`\`\`

## config
security: strict
toolstack: B
EOF

echo "状態: playbook=$TEMP_DIR/playbook-test.md"

# 2-1: Edit が許可される
run_hook "$HOOKS_DIR/playbook-guard.sh" \
    '{"tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 0 ]; then
    pass "Edit が許可される (exit=0)"
else
    fail "Edit が許可されるべき (got exit=$HOOK_EXIT)"
fi

# 2-2: executor=claudecode なのでコード編集も許可
run_hook "$HOOKS_DIR/executor-guard.sh" \
    '{"tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 0 ]; then
    pass "executor=claudecode でコード編集許可"
else
    fail "executor=claudecode でコード編集許可されるべき (got exit=$HOOK_EXIT)"
fi

# ==============================================================================
# シナリオ 3: WORK_IN_PROGRESS (executor 制約)
# ==============================================================================
section "シナリオ 3: WORK_IN_PROGRESS (executor 制約)"

# playbook を executor=codex に変更
cat > "$TEMP_DIR/playbook-test.md" << 'EOF'
# playbook-test.md

## meta

```yaml
reviewed: true
```

## phases

### p1

- executor: codex
  status: in_progress
EOF

echo "状態: executor=codex, status=in_progress"

# 3-1: executor=codex でコード編集がブロック
run_hook "$HOOKS_DIR/executor-guard.sh" \
    '{"tool_input": {"file_path": "src/main.ts"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 2 ]; then
    pass "executor=codex でコード編集ブロック (exit=2)"
else
    fail "executor=codex でコード編集ブロックされるべき (got exit=$HOOK_EXIT)"
fi

# 3-2: executor=codex でもドキュメント編集は許可
run_hook "$HOOKS_DIR/executor-guard.sh" \
    '{"tool_input": {"file_path": "docs/README.md"}}' \
    "$TEMP_DIR/state.md"

if [ "$HOOK_EXIT" -eq 0 ]; then
    pass "executor=codex でもドキュメント編集は許可"
else
    fail "ドキュメント編集は許可されるべき (got exit=$HOOK_EXIT)"
fi

# ==============================================================================
# シナリオ 4: PHASE_DONE_ATTEMPT (critic 必須チェック)
# ==============================================================================
section "シナリオ 4: PHASE_DONE_ATTEMPT (critic チェック)"

# critic-guard.sh が存在する場合のみテスト
if [ -f "$HOOKS_DIR/critic-guard.sh" ]; then
    # status を done に変更しようとする
    run_hook "$HOOKS_DIR/critic-guard.sh" \
        '{"tool_input": {"file_path": "'"$TEMP_DIR/playbook-test.md"'", "old_string": "status: in_progress", "new_string": "status: done"}}' \
        "$TEMP_DIR/state.md"

    # critic-guard は WARN または BLOCK で動作
    if [ "$HOOK_EXIT" -eq 0 ] || [ "$HOOK_EXIT" -eq 2 ]; then
        pass "critic-guard.sh が動作 (exit=$HOOK_EXIT)"
    else
        fail "critic-guard.sh が予期しない exit code (got exit=$HOOK_EXIT)"
    fi
else
    echo "  [SKIP] critic-guard.sh not found"
fi

# ==============================================================================
# シナリオ 5: PLAYBOOK_COMPLETE (全 phase done)
# ==============================================================================
section "シナリオ 5: PLAYBOOK_COMPLETE (全 phase done)"

# playbook を全 phase done に設定
cat > "$TEMP_DIR/playbook-test.md" << 'EOF'
# playbook-test.md

## meta

```yaml
reviewed: true
```

## phases

### p1

- executor: claudecode
  status: done

### p2

- executor: claudecode
  status: done

### p_final

- executor: orchestrator
  status: done
EOF

echo "状態: 全 phase done"

# archive-playbook.sh が存在する場合のみテスト
if [ -f "$HOOKS_DIR/archive-playbook.sh" ]; then
    # archive-playbook.sh を実行（PostToolUse フック）
    run_hook "$HOOKS_DIR/archive-playbook.sh" \
        '{}' \
        "$TEMP_DIR/state.md"

    # archive-playbook は完了を検出してメッセージを出力
    if [ "$HOOK_EXIT" -eq 0 ]; then
        pass "archive-playbook.sh 実行成功 (exit=0)"
        if echo "$HOOK_OUTPUT$HOOK_STDERR" | grep -qi "archive\|アーカイブ\|完了"; then
            pass "アーカイブ提案メッセージを出力"
        else
            echo "  [INFO] アーカイブ提案なし（条件未満の可能性）"
        fi
    else
        fail "archive-playbook.sh が失敗 (got exit=$HOOK_EXIT)"
    fi
else
    echo "  [SKIP] archive-playbook.sh not found"
fi

# ==============================================================================
# シナリオ 6: 状態遷移の整合性
# ==============================================================================
section "シナリオ 6: 状態遷移の整合性"

# playbook=null → playbook=active への遷移後、Edit が許可されることを確認
# これは「状態が正しく伝播している」ことの検証

# 1. playbook=null で Edit ブロック
cat > "$TEMP_DIR/state.md" << 'EOF'
# state.md

## focus

```yaml
current: product
```

## playbook

```yaml
active: null
```

## config

```yaml
security: strict
```
EOF

run_hook "$HOOKS_DIR/playbook-guard.sh" \
    '{"tool_input": {"file_path": "src/app.ts"}}' \
    "$TEMP_DIR/state.md"

BEFORE_EXIT=$HOOK_EXIT

# 2. playbook を作成して state.md を更新
cat > "$TEMP_DIR/playbook-test.md" << 'EOF'
# playbook-test.md

## meta

```yaml
reviewed: true
```

## phases

### p1

- executor: claudecode
  status: in_progress
EOF

cat > "$TEMP_DIR/state.md" << EOF
# state.md

## focus

\`\`\`yaml
current: product
\`\`\`

## playbook

\`\`\`yaml
active: $TEMP_DIR/playbook-test.md
\`\`\`

## config

\`\`\`yaml
security: strict
\`\`\`
EOF

run_hook "$HOOKS_DIR/playbook-guard.sh" \
    '{"tool_input": {"file_path": "src/app.ts"}}' \
    "$TEMP_DIR/state.md"

AFTER_EXIT=$HOOK_EXIT

# 3. 遷移前後の比較
if [ "$BEFORE_EXIT" -eq 2 ] && [ "$AFTER_EXIT" -eq 0 ]; then
    pass "状態遷移: playbook=null(block) → playbook=active(allow)"
else
    fail "状態遷移が正しくない (before=$BEFORE_EXIT, after=$AFTER_EXIT)"
fi

# ==============================================================================
# サマリー
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  テスト結果"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "  ${GREEN}PASS${NC}: $PASS"
echo -e "  ${RED}FAIL${NC}: $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}FAILED${NC} - $FAIL 件のテストが失敗しました"
    exit 1
else
    echo -e "${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
