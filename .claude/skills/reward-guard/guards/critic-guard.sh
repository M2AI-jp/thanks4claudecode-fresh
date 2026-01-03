#!/bin/bash
# ==============================================================================
# critic-guard.sh - status: done への変更を構造的にブロック
# ==============================================================================
# トリガー: PreToolUse(Edit)
# 目的: critic PASS なしで status: done に変更することを防止
#
# 動作:
#   1. 編集対象が state.md かチェック
#   2. new_string に "status: done" が含まれるかチェック
#   3. self_complete: true がファイルに存在しなければブロック
#
# 根拠: CLAUDE.md「自己報酬詐欺」対策（報酬詐欺防止）
# ==============================================================================

set -uo pipefail
# Note: -e を外す（heredoc 出力時の問題回避）

STATE_FILE="${STATE_FILE:-state.md}"
SESSION_STATE_DIR="${SESSION_STATE_DIR:-.claude/session-state}"
LAST_FAIL_REASON_FILE="$SESSION_STATE_DIR/last-fail-reason"
ITERATION_COUNT_FILE="$SESSION_STATE_DIR/iteration-count"

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はブロック（Fail-closed）
if ! command -v jq &> /dev/null; then
    cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ jq 未インストール - セキュリティチェック不可
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
jq はセキュリティガードに必須です。
Install: brew install jq
EOF
    exit 2
fi

# tool_input から情報を取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
# Edit の場合は new_string、Write の場合は content
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""')

# state.md 以外は対象外
if [[ "$FILE_PATH" != *"state.md" ]]; then
    exit 0
fi

# "status: done" を含まない編集は対象外
# YAML 形式を考慮: goal.status: done または status: done
# Note: state.md の構造では goal.status フィールドを使用
if ! echo "$NEW_STRING" | grep -qE "status:[[:space:]]*done"; then
    exit 0
fi

# ------------------------------------------------------------------
# 重要: status: done への変更を検出
# ------------------------------------------------------------------

# self_complete: true が現在のファイルに存在するかチェック
if [ -f "$STATE_FILE" ]; then
    SELF_COMPLETE=$(grep -E "self_complete:[[:space:]]*true" "$STATE_FILE" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$SELF_COMPLETE" -gt 0 ]; then
        # critic PASS 済み - 編集を許可
        exit 0
    fi
fi

# ------------------------------------------------------------------
# ブロック: critic PASS なしで status: done に変更しようとしている
# ------------------------------------------------------------------

# FAIL 情報を session-state に保存（自動リトライ機構用）
save_fail_reason() {
    mkdir -p "$SESSION_STATE_DIR"

    # state.md から現在の Phase を取得
    local phase_id="unknown"
    if [ -f "$STATE_FILE" ]; then
        phase_id=$(grep -A5 "^## goal" "$STATE_FILE" 2>/dev/null | grep "^phase:" | sed 's/phase: *//' | tr -d ' ' || echo "unknown")
    fi

    # タイムスタンプ
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # FAIL 理由を YAML 形式で保存
    cat > "$LAST_FAIL_REASON_FILE" << FAIL_EOF
phase_id: $phase_id
reason: "critic 未実行 - self_complete: true がありません。/crit を実行してください。"
timestamp: $timestamp
FAIL_EOF
}

# FAIL 情報を保存
save_fail_reason

cat >&2 << 'EOF'

========================================
  ⛔ critic 未実行 - 編集をブロック
========================================

  status: done への変更には critic PASS が必要です。

  対処法（順番に実行）:

    1. done_criteria の全項目に証拠を示す

    2. critic Skill を呼び出す:
       Skill(skill='crit')
       または /crit

    3. critic が PASS を返したら:
       state.md の self_complete: true を確認

    4. 再度 status: done に変更

  ┌─────────────────────────────────────────┐
  │ 証拠なしの done は自己報酬詐欺です。    │
  │ 「完了した気がする」は証拠ではありません。│
  └─────────────────────────────────────────┘

  ※ FAIL 情報は .claude/session-state/last-fail-reason に保存されました

========================================

EOF

exit 2
