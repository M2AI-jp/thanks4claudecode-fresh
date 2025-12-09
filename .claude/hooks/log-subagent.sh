#!/bin/bash
# ==============================================================================
# log-subagent.sh - Subagent 発動ログ記録 + critic 結果処理
# ==============================================================================
# 目的:
#   1. Task ツール使用後に subagent の発動をログに記録
#   2. critic SubAgent の結果を処理し、報酬詐欺を防止（Layer 5）
# トリガー: PostToolUse(Task)
#
# 5層報酬詐欺防御:
#   L1: CLAUDE.md LOOP/CRITIQUE（行動ルール）
#   L2: critic SubAgent（証拠ベース判断）
#   L3: critic-guard.sh（done 更新前に警告）
#   L4: check-coherence.sh（state-playbook 整合性）
#   L5: log-subagent.sh（critic 結果自動処理）← このスクリプト
# ==============================================================================

set -euo pipefail

LOG_DIR=".claude/logs"
LOG_FILE="$LOG_DIR/subagent-dispatch.log"

# ログディレクトリ確保
mkdir -p "$LOG_DIR"

# 入力JSONを読み取り（PostToolUse の tool_result）
INPUT=$(cat)

# tool_input から subagent_type を抽出
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""')

# 結果の有無を確認
TOOL_RESULT=$(echo "$INPUT" | jq -r '.tool_response // ""')
if [ -n "$TOOL_RESULT" ] && [ "$TOOL_RESULT" != "null" ]; then
    RESULT="SUCCESS"
else
    RESULT="COMPLETED"
fi

# ISO8601 形式のタイムスタンプ
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ログエントリを記録
echo "$TIMESTAMP | $SUBAGENT_TYPE | $DESCRIPTION | $RESULT" >> "$LOG_FILE"

# ==============================================================================
# critic 結果処理（Layer 5）
# ==============================================================================
if [ "$SUBAGENT_TYPE" = "critic" ]; then
    # critic の出力から PASS/FAIL を検出
    if echo "$TOOL_RESULT" | grep -iE "総合判定:.*FAIL|judgment:.*FAIL" > /dev/null 2>&1; then
        # critic FAIL を検出
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  [Layer 5] critic FAIL を検出"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  critic が FAIL を返しました。"
        echo ""
        echo "  必須アクション:"
        echo "    1. 不足している証拠を収集"
        echo "    2. 問題を修正"
        echo "    3. 再度 critic を呼び出す"
        echo ""
        echo "  state.md の self_complete は false のままです。"
        echo "  証拠なしの done は自己報酬詐欺です。"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # critic FAIL をログに記録
        echo "$TIMESTAMP | critic | FAIL | $DESCRIPTION" >> "$LOG_DIR/critic-results.log"

    elif echo "$TOOL_RESULT" | grep -iE "総合判定:.*PASS|judgment:.*PASS" > /dev/null 2>&1; then
        # critic PASS を検出
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  [Layer 5] critic PASS を検出"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  critic が PASS を返しました。"
        echo ""
        echo "  次のステップ:"
        echo "    1. state.md の self_complete を true に更新"
        echo "    2. layer.*.state を done に更新"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # critic PASS をログに記録
        echo "$TIMESTAMP | critic | PASS | $DESCRIPTION" >> "$LOG_DIR/critic-results.log"
    fi
fi

# 正常終了（PostToolUse はブロックできないが、exit 0 で成功を示す）
exit 0
