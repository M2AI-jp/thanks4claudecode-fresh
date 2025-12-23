#!/bin/bash
# ==============================================================================
# critic-guard.sh - state: done への変更を構造的にブロック
# ==============================================================================
# トリガー: PreToolUse(Edit)
# 目的: critic PASS なしで state: done に変更することを防止
#
# 動作:
#   1. 編集対象が state.md かチェック
#   2. new_string に "state: done" が含まれるかチェック
#   3. self_complete: true がファイルに存在しなければブロック
#
# 根拠: CONTEXT.md「自己報酬詐欺」対策
# ==============================================================================

set -uo pipefail
# Note: -e を外す（heredoc 出力時の問題回避）

STATE_FILE="${STATE_FILE:-state.md}"

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# tool_input から情報を取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
# Edit の場合は new_string、Write の場合は content
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""')

# state.md 以外は対象外
if [[ "$FILE_PATH" != *"state.md" ]]; then
    exit 0
fi

# "state: done" を含まない編集は対象外
# YAML 形式を考慮: "state: done" または "state:done"
if ! echo "$NEW_STRING" | grep -qE "state:[[:space:]]*done"; then
    exit 0
fi

# ------------------------------------------------------------------
# 重要: state: done への変更を検出
# ------------------------------------------------------------------

# layer セクション内の state: done かを判定
# goal.phase など他の "done" 文字列は許可
# layer 名を検出するためのパターン
if ! echo "$NEW_STRING" | grep -qE "^state:[[:space:]]*done"; then
    # 行頭でない場合（インデントあり）は許可
    # これは YAML コードブロック内の可能性が高い
    # より厳密には old_string も見るべきだが、ここでは簡易チェック
    :
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
  ⛔ critic 未実行 - 編集をブロック
========================================

  state: done への変更には critic PASS が必要です。

  対処法（順番に実行）:

    1. done_criteria の全項目に証拠を示す

    2. critic エージェントを呼び出す:
       Task(subagent_type='critic')
       または /crit

    3. critic が PASS を返したら:
       state.md の self_complete: true を確認

    4. 再度 state: done に変更

  ┌─────────────────────────────────────────┐
  │ 証拠なしの done は自己報酬詐欺です。    │
  │ 「完了した気がする」は証拠ではありません。│
  └─────────────────────────────────────────┘

========================================

EOF

exit 2
