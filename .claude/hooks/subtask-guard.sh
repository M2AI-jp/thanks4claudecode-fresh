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
if [[ "$NEW_STRING" != *"validations:"* ]]; then
    # validations がない場合はブロック
    echo "[subtask-guard] ❌ BLOCKED: subtask 完了には validations が必須です。"
    echo ""
    echo "V15 形式（チェックボックス）で以下の 3 検証を追加してください:"
    echo ""
    echo "- [x] **p1.1**: criterion が満たされている ✓"
    echo "  - executor: claudecode"
    echo "  - validations:"
    echo "    - technical: \"PASS - 技術的に正しい\""
    echo "    - consistency: \"PASS - 整合性がある\""
    echo "    - completeness: \"PASS - 完全に実装\""
    echo "  - validated: $(date -u +%Y-%m-%dT%H:%M:%S)"
    echo ""
    echo "参照: plan/template/playbook-format.md"
    exit 2
fi

# validations がある場合は許可（公式 Hook 仕様: exit 0 のみで十分）
# M085: 不要な JSON 出力を削除（公式仕様では stdout への JSON は意味を持たない）
exit 0
