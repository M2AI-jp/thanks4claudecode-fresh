#!/bin/bash
# ==============================================================================
# subtask-guard.sh - subtask の 3 検証を強制
# ==============================================================================
# 目的: subtask.status = done 変更時に 3 つの検証を実行
# トリガー: PreToolUse(Edit)
#
# 【単一責任原則 (SRP)】
# このスクリプトは「subtask 検証」のみを担当
#
# 3 つの検証:
#   1. technical: 技術的に正しく動作するか
#   2. consistency: 他のコンポーネントと整合性があるか
#   3. completeness: 必要な変更が全て完了しているか
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

# status: done への変更をチェック
OLD_STRING=$(echo "$TOOL_INPUT" | jq -r '.old_string // empty')
NEW_STRING=$(echo "$TOOL_INPUT" | jq -r '.new_string // empty')

# status が変更されていない場合はパス
if [[ "$OLD_STRING" == *"status: pending"* || "$OLD_STRING" == *"status: in_progress"* ]]; then
    if [[ "$NEW_STRING" == *"status: done"* ]]; then
        # status: done への変更を検出
        # 現在のセッションでは警告のみ（将来的には検証を強制）
        echo "{\"decision\": \"allow\", \"systemMessage\": \"[subtask-guard] ⚠️ Phase を done にする前に、以下の 3 検証を確認してください:\\n\\n1. technical: test_command が PASS を返すか\\n2. consistency: 関連ファイルとの整合性があるか\\n3. completeness: 必要な変更が全て完了しているか\\n\\n critic SubAgent による検証を推奨します。\"}"
        exit 0
    fi
fi

# その他の変更はパス
exit 0
