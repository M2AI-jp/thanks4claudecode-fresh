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
# M088: Phase レベルの status 変更を検出（報酬詐欺防止強化）
# ==============================================================================
# パターン 4: **status**: pending/in_progress → **status**: done (Phase レベル)
# Phase を done にする前に、全 subtask が完了していることを確認
# ==============================================================================
PHASE_STATUS_CHANGE=false

if [[ "$OLD_STRING" == *"**status**: pending"* || "$OLD_STRING" == *"**status**: in_progress"* ]]; then
    # done または completed を完了として扱う
    if [[ "$NEW_STRING" == *"**status**: done"* || "$NEW_STRING" == *"**status**: completed"* ]]; then
        PHASE_STATUS_CHANGE=true
    fi
fi

# Phase status 変更の場合、該当 Phase の subtask 完了状態をチェック
if [[ "$PHASE_STATUS_CHANGE" == "true" ]]; then
    if [[ -f "$FILE_PATH" ]]; then
        # 変更対象の Phase を特定（**status**: pending/in_progress を含む Phase を検索）
        # ファイル内で OLD_STRING の位置を見つけ、その直前の ### p{N}: を取得
        TARGET_PHASE=$(awk '
            /^### p[0-9_a-z]*:/ { phase = $0; gsub(/^### /, "", phase); gsub(/:.*/, "", phase) }
            /\*\*status\*\*: (pending|in_progress)/ { print phase; exit }
        ' "$FILE_PATH" 2>/dev/null)

        if [[ -n "$TARGET_PHASE" ]]; then
            # その Phase の subtask セクションを抽出
            PHASE_SECTION=$(awk "/^### ${TARGET_PHASE}:/,/^### p[0-9_]|^## final_tasks/" "$FILE_PATH" 2>/dev/null)

            # 未完了 subtask (- [ ]) があるかチェック
            INCOMPLETE_SUBTASKS=$(echo "$PHASE_SECTION" | grep -c '\- \[ \]' 2>/dev/null | tr -d '\n' || echo "0")

            if [[ "$INCOMPLETE_SUBTASKS" -gt 0 ]]; then
                echo "[subtask-guard] ❌ BLOCKED: Phase ${TARGET_PHASE} を done にする前に全 subtask を完了してください。"
                echo ""
                echo "未完了の subtask が ${INCOMPLETE_SUBTASKS} 個あります。"
                echo ""
                echo "各 subtask を完了するには:"
                echo "  1. criterion を満たす作業を実施"
                echo "  2. validations (3点検証) を記入"
                echo "  3. チェックボックスを [x] に変更"
                echo "  4. validated タイムスタンプを追加"
                echo ""
                echo "参照: plan/template/playbook-format.md"
                exit 2
            fi

            # validated タイムスタンプの存在をチェック
            COMPLETED_SUBTASKS=$(echo "$PHASE_SECTION" | grep -c '\- \[x\]' 2>/dev/null | tr -d '\n' || echo "0")
            VALIDATED_COUNT=$(echo "$PHASE_SECTION" | grep -c 'validated:' 2>/dev/null | tr -d '\n' || echo "0")

            if [[ "$COMPLETED_SUBTASKS" -gt 0 && "$VALIDATED_COUNT" -lt "$COMPLETED_SUBTASKS" ]]; then
                echo "[subtask-guard] ⚠️ WARNING: Phase ${TARGET_PHASE} の一部の完了 subtask に validated タイムスタンプがありません。"
                echo ""
                echo "完了 subtask: ${COMPLETED_SUBTASKS} 個"
                echo "validated あり: ${VALIDATED_COUNT} 個"
                echo ""
                echo "推奨: 各完了 subtask に validated: $(date -u +%Y-%m-%dT%H:%M:%S) を追加してください。"
            fi
        fi
    fi

    # Phase status 変更自体は許可（subtask チェックが通った場合）
    exit 0
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

# validations がある場合は許可（公式 Hook 仕様: exit 0 のみで十分）
# M085: 不要な JSON 出力を削除（公式仕様では stdout への JSON は意味を持たない）
exit 0
