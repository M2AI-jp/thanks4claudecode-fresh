#!/bin/bash
# ==============================================================================
# subtask-validator.sh - subtask 完了時の 3 点検証を強制（ブロック版）
# ==============================================================================
# 目的: subtask 完了時に validations の存在を強制
# トリガー: PreToolUse(Edit)
#
# 設計思想:
#   - subtask 完了には 3 点検証（technical/consistency/completeness）が必須
#   - validations なしでの完了変更をブロック（exit 2）
#   - Phase 完了時は全 subtask の完了を確認
#
# 検出パターン:
#   1. `- [ ]` → `- [x]` の変更
#   2. status: pending/in_progress → status: done
#   3. status: PASS への変更
#   4. **status**: pending/in_progress → **status**: done（Phase レベル）
#
# ブートストラップ例外:
#   - final_tasks セクションの変更は validations 不要
# ==============================================================================

set -euo pipefail

# 入力 JSON を読み取り
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

# Edit ツール以外はパス
if [[ "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# playbook ファイルへの編集のみチェック
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
if [[ "$FILE_PATH" != *"playbook-"* ]]; then
    exit 0
fi

# old_string / new_string を取得
OLD_STRING=$(echo "$TOOL_INPUT" | jq -r '.old_string // empty')
NEW_STRING=$(echo "$TOOL_INPUT" | jq -r '.new_string // empty')

# ==============================================================================
# final_tasks セクションの変更は許可（スキップ）
# ==============================================================================
if [[ "$OLD_STRING" == *"final_tasks"* ]] || [[ "$OLD_STRING" == *"**ft"* ]] || [[ "$OLD_STRING" == *"- id: ft"* ]]; then
    exit 0
fi

# ==============================================================================
# チェックボックス形式 `- [ ]` → `- [x]` の変更を検出
# ==============================================================================
CHECKBOX_CHANGE=false

# パターン 1: `- [ ]` → `- [x]` の変更
if [[ "$OLD_STRING" == *"- [ ]"* ]] && [[ "$NEW_STRING" == *"- [x]"* ]]; then
    CHECKBOX_CHANGE=true
fi

# パターン 2: status: pending/in_progress → status: done
if [[ "$OLD_STRING" == *"status: pending"* || "$OLD_STRING" == *"status: in_progress"* ]]; then
    if [[ "$NEW_STRING" == *"status: done"* ]]; then
        CHECKBOX_CHANGE=true
    fi
fi

# パターン 3: status: PASS への変更
if [[ "$NEW_STRING" == *"status: PASS"* ]]; then
    CHECKBOX_CHANGE=true
fi

# ==============================================================================
# Phase レベルの status 変更を検出（報酬詐欺防止）
# ==============================================================================
PHASE_STATUS_CHANGE=false

if [[ "$OLD_STRING" == *"**status**: pending"* || "$OLD_STRING" == *"**status**: in_progress"* ]]; then
    if [[ "$NEW_STRING" == *"**status**: done"* ]]; then
        PHASE_STATUS_CHANGE=true
    fi
fi

# Phase status 変更の場合、該当 Phase の subtask 完了状態をチェック
if [[ "$PHASE_STATUS_CHANGE" == "true" ]]; then
    if [[ -f "$FILE_PATH" ]]; then
        TARGET_PHASE=$(awk '
            /^### p[0-9_a-z]*:/ { phase = $0; gsub(/^### /, "", phase); gsub(/:.*/, "", phase) }
            /\*\*status\*\*: (pending|in_progress)/ { print phase; exit }
        ' "$FILE_PATH" 2>/dev/null)

        if [[ -n "$TARGET_PHASE" ]]; then
            PHASE_SECTION=$(awk "/^### ${TARGET_PHASE}:/,/^### p[0-9_]|^## final_tasks/" "$FILE_PATH" 2>/dev/null)
            INCOMPLETE_SUBTASKS=$(echo "$PHASE_SECTION" | grep -c '\- \[ \]' 2>/dev/null | tr -d '\n' || echo "0")

            if [[ "$INCOMPLETE_SUBTASKS" -gt 0 ]]; then
                cat >&2 << EOF
========================================
  [subtask-validator] Phase 完了ブロック
========================================

  Phase ${TARGET_PHASE} を done にする前に
  全 subtask を完了してください。

  未完了の subtask: ${INCOMPLETE_SUBTASKS} 個

  各 subtask を完了するには:
    1. criterion を満たす作業を実施
    2. validations (3点検証) を記入
    3. チェックボックスを [x] に変更
    4. validated タイムスタンプを追加

  参照: plan/template/playbook-format.md

========================================
EOF
                exit 2
            fi

            # validated タイムスタンプの存在をチェック
            COMPLETED_SUBTASKS=$(echo "$PHASE_SECTION" | grep -c '\- \[x\]' 2>/dev/null | tr -d '\n' || echo "0")
            VALIDATED_COUNT=$(echo "$PHASE_SECTION" | grep -c 'validated:' 2>/dev/null | tr -d '\n' || echo "0")

            if [[ "$COMPLETED_SUBTASKS" -gt 0 && "$VALIDATED_COUNT" -lt "$COMPLETED_SUBTASKS" ]]; then
                echo "[subtask-validator] WARNING: Phase ${TARGET_PHASE} の一部の完了 subtask に validated タイムスタンプがありません。" >&2
            fi
        fi
    fi

    exit 0
fi

# チェックボックス/status 変更がない場合はパス
if [[ "$CHECKBOX_CHANGE" == "false" ]]; then
    exit 0
fi

# ==============================================================================
# validations チェック（核心ロジック）
# ==============================================================================
if [[ "$NEW_STRING" != *"validations:"* ]]; then
    cat >&2 << 'EOF'
========================================
  [subtask-validator] subtask 完了ブロック
========================================

  subtask 完了には validations（3点検証）が必須です。

  以下の形式で validations を追加してください:

  - [x] **p1.1**: criterion が満たされている
    - executor: claudecode
    - validations:
      - technical: "PASS - 技術的に正しい"
      - consistency: "PASS - 整合性がある"
      - completeness: "PASS - 完全に実装"
    - validated: 2025-12-23T12:00:00

  参照: .claude/skills/subtask-review/frameworks/subtask-validation-rules.md

========================================
EOF
    exit 2
fi

# validations がある場合は許可
exit 0
