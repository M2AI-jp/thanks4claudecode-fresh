#!/bin/bash
# ==============================================================================
# critic-enforcer.sh - state: done への変更を構造的にブロック（強化版）
# ==============================================================================
# 目的: critic PASS なしで state: done に変更することを防止
# トリガー: PreToolUse(Edit)
#
# 設計思想:
#   - 自己報酬詐欺（証拠なしでの完了申告）を構造的に防止
#   - critic SubAgent による評価を強制
#   - self_complete: true フラグで PASS を記録
#
# 動作:
#   1. 編集対象が state.md かチェック
#   2. new_string に "state: done" が含まれるかチェック
#   3. self_complete: true がファイルに存在しなければブロック（exit 2）
#
# 根拠: CONTEXT.md「自己報酬詐欺」対策
# ==============================================================================

set -uo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# tool_input から情報を取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""')

# state.md 以外は対象外
if [[ "$FILE_PATH" != *"state.md" ]]; then
    exit 0
fi

# "state: done" を含まない編集は対象外
if ! echo "$NEW_STRING" | grep -qE "state:[[:space:]]*done"; then
    exit 0
fi

# self_complete: true が現在のファイルに存在するかチェック
if [ -f "$STATE_FILE" ]; then
    SELF_COMPLETE=$(grep -E "self_complete:[[:space:]]*true" "$STATE_FILE" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$SELF_COMPLETE" -gt 0 ]; then
        # critic PASS 済み - 編集を許可
        exit 0
    fi
fi

# ------------------------------------------------------------------
# ブロック: critic PASS なしで state: done に変更しようとしている
# ------------------------------------------------------------------

cat >&2 << 'EOF'
========================================
  [critic-enforcer] state: done ブロック
========================================

  state: done への変更には critic PASS が必要です。

  対処法（順番に実行）:

    1. done_criteria の全項目に証拠を示す

    2. critic SubAgent を呼び出す:
       Task(subagent_type='critic',
            prompt='Phase の done_criteria を評価。
            .claude/skills/phase-critique/frameworks/done-criteria-validation.md を参照')
       または /crit

    3. critic が PASS を返したら:
       state.md に self_complete: true を設定

    4. 再度 state: done に変更

  評価基準:
    1. 根拠の有無
    2. 検証可能性
    3. 計画との整合性
    4. 報酬詐欺の検出
    5. 証拠の品質

  参照: .claude/skills/phase-critique/frameworks/done-criteria-validation.md

========================================
EOF

exit 2
