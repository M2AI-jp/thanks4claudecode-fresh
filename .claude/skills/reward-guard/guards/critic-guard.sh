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

# Evidence format rules
GOOD_EVIDENCE_EXAMPLES=(
    "PASS - specific details about what was verified"
    "PASS - command output shows X"
    "PASS - file contains Y"
)

BAD_EVIDENCE_EXAMPLES=(
    "done"
    "completed"
    "PASS"
    "PASS - "
)

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

# tool_input から情報を取得（互換性のため top-level もサポート）
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // ""')
# Edit の場合は new_string、Write の場合は content
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // .new_string // .content // ""')

trim_value() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

strip_quotes() {
    local value="$1"
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
    printf '%s' "$value"
}

is_valid_evidence() {
    local raw_value="$1"
    local trimmed
    trimmed=$(trim_value "$raw_value")

    if [[ -z "$trimmed" ]]; then
        return 1
    fi

    local lower_value
    lower_value=$(echo "$trimmed" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower_value" == "done" || "$lower_value" == "completed" || "$trimmed" == "PASS" ]]; then
        return 1
    fi

    if [[ "$trimmed" != PASS\ -\ * ]]; then
        return 1
    fi

    local details
    details=$(trim_value "${trimmed#PASS - }")
    if [[ -z "$details" ]]; then
        return 1
    fi

    local details_lower
    details_lower=$(echo "$details" | tr '[:upper:]' '[:lower:]')
    if [[ "$details_lower" == "done" || "$details_lower" == "completed" ]]; then
        return 1
    fi

    return 0
}

check_playbook_validation_evidence() {
    local content="$1"
    local invalid_lines=""
    local line value

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-?[[:space:]]*(technical|consistency|completeness): ]]; then
            value=$(echo "$line" | sed -E 's/^[[:space:]]*-?[[:space:]]*(technical|consistency|completeness):[[:space:]]*//')
            value=$(strip_quotes "$value")
            value=$(trim_value "$value")
            if ! is_valid_evidence "$value"; then
                invalid_lines+=$'\n'"  - $line"
            fi
        fi
    done <<< "$content"

    if [[ -n "$invalid_lines" ]]; then
        cat >&2 << EOF
========================================
  ⛔ validations の証拠形式が不正です
========================================

  validations は "PASS - " に続く具体的な証拠が必須です。

  良い例:
    - ${GOOD_EVIDENCE_EXAMPLES[0]}
    - ${GOOD_EVIDENCE_EXAMPLES[1]}
    - ${GOOD_EVIDENCE_EXAMPLES[2]}

  悪い例:
    - ${BAD_EVIDENCE_EXAMPLES[0]}
    - ${BAD_EVIDENCE_EXAMPLES[1]}
    - ${BAD_EVIDENCE_EXAMPLES[2]}
    - ${BAD_EVIDENCE_EXAMPLES[3]}

  不正な validations:
$invalid_lines

========================================
EOF
        return 2
    fi

    return 0
}

# playbook 形式の validations 証拠チェック
IS_PLAYBOOK=false
if [[ "$FILE_PATH" == */plan/playbook-*.md ]] || [[ "$FILE_PATH" == plan/playbook-*.md ]]; then
    IS_PLAYBOOK=true
fi

if [[ "$IS_PLAYBOOK" == "true" ]]; then
    check_playbook_validation_evidence "$NEW_STRING" || exit 2
fi

# state.md 以外で playbook でもなければ対象外
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

    2. critic Skill を呼び出す:
       Skill(skill='crit')
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
