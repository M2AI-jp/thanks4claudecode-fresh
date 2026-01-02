#!/bin/bash
# ==============================================================================
# subtask-guard.sh - subtask の 3 検証を強制（V12: チェックボックス形式対応）
# ==============================================================================
# 目的: subtask の完了変更時に 3 つの検証を実行
# トリガー: PreToolUse(Edit)
#
# 【単一責任原則 (SRP)】
# このスクリプトは「subtask 検証」のみを担当
#
# 3 つの検証:
#   1. technical: 技術的に正しく動作するか
#   2. consistency: 他のコンポーネントと整合性があるか
#   3. completeness: 必要な変更が全て完了しているか
#
# V12 対応:
#   - `- [ ]` → `- [x]` の変更を検出
#   - final_tasks のチェックボックス変更はスキップ
#
# M056: final_tasks の変更は許可（スキップ）
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
# M056: final_tasks セクションの変更は許可（スキップ）
# ==============================================================================
# final_tasks は subtasks とは異なり、単純なチェックリストなので
# validations は不要。変更を許可する。
# 判定: old_string に "final_tasks" または "**ft" が含まれていれば final_tasks
# ==============================================================================
if [[ "$OLD_STRING" == *"final_tasks"* ]] || [[ "$OLD_STRING" == *"**ft"* ]] || [[ "$OLD_STRING" == *"- id: ft"* ]]; then
    # final_tasks の変更 → 許可（bypass）
    exit 0
fi

# ==============================================================================
# V12: チェックボックス形式 `- [ ]` → `- [x]` の変更を検出
# ==============================================================================
CHECKBOX_CHANGE=false

# パターン 1: `- [ ]` → `- [x]` の変更
if [[ "$OLD_STRING" == *"- [ ]"* ]] && [[ "$NEW_STRING" == *"- [x]"* ]]; then
    CHECKBOX_CHANGE=true
fi

# パターン 2: V11 形式（旧）status: pending/in_progress → status: done
if [[ "$OLD_STRING" == *"status: pending"* || "$OLD_STRING" == *"status: in_progress"* ]]; then
    if [[ "$NEW_STRING" == *"status: done"* ]]; then
        CHECKBOX_CHANGE=true
    fi
fi

# パターン 3: status: PASS への変更（旧形式の互換性）
if [[ "$NEW_STRING" == *"status: PASS"* ]]; then
    CHECKBOX_CHANGE=true
fi

# ==============================================================================
# Phase status 変更の検出とスキップ
# ==============================================================================
# Phase status 変更 (**status**: pending/in_progress → done) は
# phase-status-guard.sh が担当するため、このスクリプトではスキップ
# 参照: .claude/skills/reward-guard/guards/phase-status-guard.sh
# ==============================================================================
if [[ "$OLD_STRING" == *"**status**: pending"* || "$OLD_STRING" == *"**status**: in_progress"* ]]; then
    if [[ "$NEW_STRING" == *"**status**: done"* || "$NEW_STRING" == *"**status**: completed"* ]]; then
        # Phase status 変更は phase-status-guard.sh に委譲
        exit 0
    fi
fi

# チェックボックス/status 変更がない場合はパス
if [[ "$CHECKBOX_CHANGE" == "false" ]]; then
    exit 0
fi

# ==============================================================================
# validations チェック
# ==============================================================================
# V12 形式: - [x] の後に validations ブロックがあるか
# V11 形式: status: done の後に validations があるか
# ==============================================================================
# validations の存在と内容をチェック
# - validations: がない → ブロック
# - validations: はあるが technical/consistency/completeness が null → ブロック
# ==============================================================================
if [[ "$NEW_STRING" != *"validations:"* ]]; then
    # validations がない場合はブロック
    cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ subtask 完了には validations が必須です
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  以下の 3 検証を追加してください:

  - [x] **p1.1**: criterion が満たされている ✓
    - validations:
      - technical: "PASS - 技術的に正しい"
      - consistency: "PASS - 整合性がある"
      - completeness: "PASS - 完全に実装"
    - validated: 2025-12-24T00:00:00

  または Skill(skill='crit') / /crit を呼び出して検証を実行

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 2
fi

# validations があっても値が null の場合はブロック
if [[ "$NEW_STRING" == *"technical: null"* ]] || \
   [[ "$NEW_STRING" == *"consistency: null"* ]] || \
   [[ "$NEW_STRING" == *"completeness: null"* ]]; then
    cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ validations の値が null です
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  3 つの検証すべてに具体的な値を入力してください:

  - validations:
    - technical: "PASS - (技術的な検証結果)"
    - consistency: "PASS - (整合性の検証結果)"
    - completeness: "PASS - (完全性の検証結果)"

  または Skill(skill='crit') / /crit を呼び出して検証を実行

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 2
fi

# ==============================================================================
# critic 呼び出しの構造的強制（報酬詐欺防止）
# ==============================================================================
# subtask 完了時に critic SubAgent 呼び出しを必須として指示
# validations がある場合でも、Phase 完了前に critic 検証を要求
# ==============================================================================

# subtask ID を抽出
SUBTASK_ID=$(echo "$NEW_STRING" | grep -oE 'p[0-9]+\.[0-9]+|p_[a-z_]+\.[0-9]+' | head -1 || echo "unknown")

# Phase ID を抽出
PHASE_ID=$(echo "$SUBTASK_ID" | sed 's/\.[0-9]*$//')

# 残り subtask 数を計算（該当 Phase 内）
REMAINING_SUBTASKS=0
if [[ -f "$FILE_PATH" && -n "$PHASE_ID" ]]; then
    PHASE_SECTION=$(awk "/^### ${PHASE_ID}:/,/^---\$/" "$FILE_PATH" 2>/dev/null)
    REMAINING_SUBTASKS=$(echo "$PHASE_SECTION" | grep -c '\- \[ \]' 2>/dev/null || echo "0")
    REMAINING_SUBTASKS=$((REMAINING_SUBTASKS - 1))  # 現在完了中の分を引く
    if [[ "$REMAINING_SUBTASKS" -lt 0 ]]; then
        REMAINING_SUBTASKS=0
    fi
fi

# 最後の subtask かどうかで警告レベルを変更
if [[ "$REMAINING_SUBTASKS" -eq 0 ]]; then
    # 最後の subtask → critic 必須を強調
    CRITIC_MESSAGE="  ⚠️ これが Phase ${PHASE_ID} の最後の subtask です\\n\\n  【critic 呼び出し必須】\\n  Phase を done にする前に必ず以下を実行してください:\\n\\n    Skill(skill='crit') または /crit\\n\\n  critic SubAgent が done_criteria を検証します。\\n  critic なしで Phase を done にすると報酬詐欺となります。"
else
    # まだ subtask が残っている
    CRITIC_MESSAGE="  【critic 呼び出しについて】\\n  Phase 完了前に必ず以下を実行してください:\\n\\n    Skill(skill='crit') または /crit\\n\\n  残り subtask: ${REMAINING_SUBTASKS} 個"
fi

# validations がある場合は許可しつつ、critic 発動を指示
cat << EOF
{
  "continue": true,
  "decision": "allow",
  "reason": "subtask $SUBTASK_ID の validations が記入されています",
  "hookSpecificOutput": {
    "action": "require_critic",
    "subtask_id": "$SUBTASK_ID",
    "phase_id": "$PHASE_ID",
    "remaining_subtasks": $REMAINING_SUBTASKS,
    "message": "Phase 完了前に critic 呼び出しが必須です"
  },
  "systemMessage": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n  ✅ subtask $SUBTASK_ID の validations を確認\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n$CRITIC_MESSAGE\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
EOF

exit 0
