#!/bin/bash
# ==============================================================================
# phase-status-guard.sh - Phase status 変更時の全 subtask 完了検証
# ==============================================================================
# 目的: Phase を done に変更する前に全 subtask の完了を検証
# トリガー: PreToolUse(Edit) - playbook ファイルへの編集時
#
# 【単一責任原則 (SRP)】
# このスクリプトは「Phase status 変更検証」のみを担当
# subtask 個別の検証は subtask-guard.sh が担当
#
# 検証項目:
#   1. 該当 Phase の全 subtask が `- [x]` であること
#   2. 未完了 subtask (`- [ ]`) が存在しないこと
#
# 旧 M088 ロジックを subtask-guard.sh から分離
# ==============================================================================

set -euo pipefail

# 入力 JSON を読み取り
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

# playbook ファイルへの編集のみチェック
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
if [[ "$FILE_PATH" != *"playbook-"* ]]; then
    exit 0
fi

# old_string / new_string を取得
OLD_STRING=$(echo "$TOOL_INPUT" | jq -r '.old_string // empty')
NEW_STRING=$(echo "$TOOL_INPUT" | jq -r '.new_string // empty')

# ==============================================================================
# Phase status 変更検出
# ==============================================================================
# パターン: **status**: pending/in_progress → **status**: done/completed
# Markdown の bold 形式に対応
# ==============================================================================
PHASE_STATUS_CHANGE=false

# パターン 1: **status**: pending → **status**: done
if [[ "$OLD_STRING" == *"**status**: pending"* ]]; then
    if [[ "$NEW_STRING" == *"**status**: done"* || "$NEW_STRING" == *"**status**: completed"* ]]; then
        PHASE_STATUS_CHANGE=true
    fi
fi

# パターン 2: **status**: in_progress → **status**: done
if [[ "$OLD_STRING" == *"**status**: in_progress"* ]]; then
    if [[ "$NEW_STRING" == *"**status**: done"* || "$NEW_STRING" == *"**status**: completed"* ]]; then
        PHASE_STATUS_CHANGE=true
    fi
fi

# Phase status 変更でなければスキップ
if [[ "$PHASE_STATUS_CHANGE" == "false" ]]; then
    exit 0
fi

# ==============================================================================
# Phase 特定と subtask 完了状態チェック
# ==============================================================================
if [[ ! -f "$FILE_PATH" ]]; then
    echo "[phase-status-guard] ⚠️ WARNING: ファイルが存在しません: $FILE_PATH" >&2
    exit 0
fi

# 変更対象の Phase を特定
# OLD_STRING に含まれる Phase ID を抽出（### p{N}: の形式）
TARGET_PHASE=""

# ファイル内で **status**: pending/in_progress を持つ Phase を検索
# 行頭の **status**: のみをマッチさせる（説明文内のパターンを除外）
TARGET_PHASE=$(awk '
    /^### p[0-9_a-z]*:/ {
        phase = $0
        gsub(/^### /, "", phase)
        gsub(/:.*/, "", phase)
    }
    /^\*\*status\*\*: (pending|in_progress)$/ {
        print phase
        exit
    }
' "$FILE_PATH" 2>/dev/null)

if [[ -z "$TARGET_PHASE" ]]; then
    # Phase が特定できない場合は警告のみ
    echo "[phase-status-guard] ⚠️ WARNING: 変更対象の Phase を特定できませんでした" >&2
    exit 0
fi

# ==============================================================================
# 該当 Phase の subtask セクションを抽出
# ==============================================================================
# Phase セクション: ### p{N}: から次の --- まで
PHASE_SECTION=$(awk "/^### ${TARGET_PHASE}:/,/^---\$/" "$FILE_PATH" 2>/dev/null)

# ==============================================================================
# 未完了 subtask チェック
# ==============================================================================
INCOMPLETE_COUNT=$(echo "$PHASE_SECTION" | grep -c '\- \[ \]' 2>/dev/null || echo "0")
INCOMPLETE_COUNT=$(echo "$INCOMPLETE_COUNT" | tr -d '[:space:]')

if [[ "$INCOMPLETE_COUNT" -gt 0 ]]; then
    # 未完了 subtask があればブロック
    INCOMPLETE_LIST=$(echo "$PHASE_SECTION" | grep '\- \[ \]' | head -5 || true)

    cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ BLOCKED: Phase ${TARGET_PHASE} を done にできません
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  未完了の subtask が ${INCOMPLETE_COUNT} 個あります。

  Phase を done にする前に、全ての subtask を完了してください:

  【未完了 subtask（最大5件表示）】
${INCOMPLETE_LIST}

  【完了手順】
  1. criterion を満たす作業を実施
  2. Skill(skill='crit') / /crit で検証を実行
  3. validations (3点検証) を記入
  4. チェックボックスを [x] に変更
  5. validated タイムスタンプを追加

  参照: plan/template/playbook-format.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 2
fi

# ==============================================================================
# validated タイムスタンプチェック（警告のみ）
# ==============================================================================
COMPLETED_COUNT=$(echo "$PHASE_SECTION" | grep -c '\- \[x\]' 2>/dev/null || echo "0")
COMPLETED_COUNT=$(echo "$COMPLETED_COUNT" | tr -d '[:space:]')

VALIDATED_COUNT=$(echo "$PHASE_SECTION" | grep -c 'validated:' 2>/dev/null || echo "0")
VALIDATED_COUNT=$(echo "$VALIDATED_COUNT" | tr -d '[:space:]')

if [[ "$COMPLETED_COUNT" -gt 0 && "$VALIDATED_COUNT" -lt "$COMPLETED_COUNT" ]]; then
    cat << EOF
{
  "continue": true,
  "decision": "allow",
  "reason": "Phase ${TARGET_PHASE} の全 subtask が完了しています",
  "hookSpecificOutput": {
    "action": "warning",
    "phase": "${TARGET_PHASE}",
    "completed_subtasks": ${COMPLETED_COUNT},
    "validated_subtasks": ${VALIDATED_COUNT}
  },
  "systemMessage": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n  ⚠️ Phase ${TARGET_PHASE} の validated タイムスタンプ不足\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n  完了 subtask: ${COMPLETED_COUNT} 個\\n  validated あり: ${VALIDATED_COUNT} 個\\n\\n  推奨: 各完了 subtask に validated: $(date -u +%Y-%m-%dT%H:%M:%S) を追加\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
EOF
    exit 0
fi

# ==============================================================================
# 全 subtask 完了 → Phase status 変更を許可
# ==============================================================================
cat << EOF
{
  "continue": true,
  "decision": "allow",
  "reason": "Phase ${TARGET_PHASE} の全 ${COMPLETED_COUNT} subtask が完了しています",
  "hookSpecificOutput": {
    "action": "phase_completion_approved",
    "phase": "${TARGET_PHASE}",
    "completed_subtasks": ${COMPLETED_COUNT}
  },
  "systemMessage": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n  ✅ Phase ${TARGET_PHASE} の完了を承認\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n  全 ${COMPLETED_COUNT} subtask の完了を確認しました。\\n  Phase status を done に変更できます。\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
EOF

exit 0
