#!/bin/bash
# ==============================================================================
# test-hooks.sh - Hook 機能カタログスペック検証
# ==============================================================================
#
# 目的:
#   - 登録されている Hook が実際に動作するか検証
#   - テスト入力を投入して期待される出力が得られるか確認
#   - 機能のカタログスペックと実動作の乖離を検出
#
# 使用方法:
#   bash .claude/hooks/test-hooks.sh [--verbose]
#
# ==============================================================================

set -e

VERBOSE=false
[ "$1" = "--verbose" ] && VERBOSE=true

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
RESULTS=""

log() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

# ==============================================================================
# 1. テストケース定義
# ==============================================================================

test_hook() {
    local hook_name="$1"
    local hook_file="$2"
    local test_input="$3"
    local expected_pattern="$4"
    local description="$5"

    if [ ! -f "$hook_file" ]; then
        RESULTS="$RESULTS\n  ⏭️ SKIP: $hook_name - ファイルが存在しません"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        return
    fi

    if [ ! -x "$hook_file" ]; then
        RESULTS="$RESULTS\n  ❌ FAIL: $hook_name - 実行権限がありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    log "Testing: $hook_name..."

    # テスト実行
    OUTPUT=$(echo "$test_input" | bash "$hook_file" 2>&1) || true

    # 結果検証
    if echo "$OUTPUT" | grep -q "$expected_pattern" 2>/dev/null; then
        RESULTS="$RESULTS\n  ✅ PASS: $hook_name - $description"
        PASS_COUNT=$((PASS_COUNT + 1))
    elif [ -z "$OUTPUT" ] && [ "$expected_pattern" = "EMPTY" ]; then
        RESULTS="$RESULTS\n  ✅ PASS: $hook_name - $description (出力なし=正常)"
        PASS_COUNT=$((PASS_COUNT + 1))
    elif [ "$expected_pattern" = "EMPTY_OR_JSON" ]; then
        # 出力なし、または JSON 形式の出力なら成功
        if [ -z "$OUTPUT" ] || echo "$OUTPUT" | grep -q "decision" 2>/dev/null; then
            RESULTS="$RESULTS\n  ✅ PASS: $hook_name - $description"
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            RESULTS="$RESULTS\n  ❌ FAIL: $hook_name - $description"
            RESULTS="$RESULTS\n      実際: $(echo "$OUTPUT" | head -1)"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        RESULTS="$RESULTS\n  ❌ FAIL: $hook_name - $description"
        RESULTS="$RESULTS\n      期待: $expected_pattern"
        RESULTS="$RESULTS\n      実際: $(echo "$OUTPUT" | head -1)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ==============================================================================
# 2. 各 Hook のテスト実行
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪 Hook 機能検証テスト"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# session-start.sh - 正常起動テスト
test_hook \
    "session-start" \
    ".claude/hooks/session-start.sh" \
    '{"trigger": "startup"}' \
    "CORE" \
    "セッション開始メッセージ出力"

# session-start.sh - compact トリガーテスト
test_hook \
    "session-start (compact)" \
    ".claude/hooks/session-start.sh" \
    '{"trigger": "compact"}' \
    "Auto-Compact" \
    "compact 復元メッセージ出力"

# pre-compact.sh - スナップショット保存テスト
test_hook \
    "pre-compact" \
    ".claude/hooks/pre-compact.sh" \
    '{"trigger": "auto"}' \
    "additionalContext" \
    "additionalContext JSON 出力"

# playbook-guard.sh - playbook チェックテスト（出力は状態依存）
test_hook \
    "playbook-guard" \
    ".claude/hooks/playbook-guard.sh" \
    '{"tool_input": {"file_path": "test.ts"}}' \
    "EMPTY_OR_JSON" \
    "実行完了（出力は状態依存）"

# init-guard.sh - 初期化チェックテスト（出力は状態依存）
test_hook \
    "init-guard" \
    ".claude/hooks/init-guard.sh" \
    '{"tool_input": {}}' \
    "EMPTY_OR_JSON" \
    "実行完了（出力は状態依存）"

# system-health-check.sh - ヘルスチェックテスト
test_hook \
    "system-health-check" \
    ".claude/hooks/system-health-check.sh" \
    '' \
    "EMPTY" \
    "問題なし時は出力なし"

# doc-freshness-check.sh - 鮮度チェックテスト
test_hook \
    "doc-freshness-check" \
    ".claude/hooks/doc-freshness-check.sh" \
    '{"params": {"file_path": "docs/current-implementation.md"}}' \
    "EMPTY" \
    "鮮度問題なし時は出力なし"

# update-tracker.sh - 更新追跡テスト
test_hook \
    "update-tracker" \
    ".claude/hooks/update-tracker.sh" \
    '{"params": {"file_path": ".claude/hooks/test.sh"}}' \
    "decision" \
    "更新提案 JSON 出力"

# failure-logger.sh - 失敗記録テスト
test_hook \
    "failure-logger" \
    ".claude/hooks/failure-logger.sh" \
    '{"hook": "test", "context": "test", "action": "test"}' \
    "Logged" \
    "失敗記録確認"

# generate-implementation-doc.sh - ドキュメント生成テスト
test_hook \
    "generate-implementation-doc" \
    ".claude/hooks/generate-implementation-doc.sh" \
    '' \
    "Generated" \
    "ドキュメント生成確認"

# ==============================================================================
# 3. 結果サマリー
# ==============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 テスト結果"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "$RESULTS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  合計: $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT)) テスト"
echo "  ✅ PASS: $PASS_COUNT"
echo "  ❌ FAIL: $FAIL_COUNT"
echo "  ⏭️ SKIP: $SKIP_COUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 失敗があれば exit 1
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo ""
    echo "⚠️ $FAIL_COUNT 件のテストが失敗しました。"
    echo "修復コマンド例:"
    echo "  chmod +x .claude/hooks/*.sh"
    exit 1
fi

exit 0
