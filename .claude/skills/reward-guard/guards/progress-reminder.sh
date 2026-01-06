#!/bin/bash
# ==============================================================================
# progress-reminder.sh - PostToolUse Hook でリマインダーを注入
# ==============================================================================
# 目的: Claude が作業完了後に progress.json を更新するよう促す
#       subtask-guard は受動的（編集時のみ発火）なので、能動的リマインダーが必要
#
# 設計思想:
#   - subtask-guard をバイパスする問題への対策
#   - 「progress.json を編集しない」という抜け道を塞ぐ
#   - systemMessage で Claude に更新を促す
#
# トリガー: PostToolUse(Edit/Write) - progress.json 以外のファイル編集時
# ==============================================================================

set -euo pipefail

INPUT=$(cat)

# jq チェック
if ! command -v jq &> /dev/null; then
    exit 0
fi

# ファイルパスを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# progress.json 自体の編集は除外（無限ループ防止）
case "$FILE_PATH" in
    */progress.json) exit 0 ;;
esac

# state.md から playbook.active を取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
STATE_FILE="$ROOT_DIR/state.md"

if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# playbook.active を抽出（yaml コードブロック内から）
PLAYBOOK_ACTIVE=$(grep "^active:" "$STATE_FILE" 2>/dev/null | \
    head -1 | \
    sed 's/^active: *//' | \
    tr -d ' ' || echo "")

# null または空なら何もしない
if [[ -z "$PLAYBOOK_ACTIVE" ]] || [[ "$PLAYBOOK_ACTIVE" == "null" ]]; then
    exit 0
fi

# progress.json のパスを構築
PROGRESS_FILE="$ROOT_DIR/${PLAYBOOK_ACTIVE%/*}/progress.json"

if [[ ! -f "$PROGRESS_FILE" ]]; then
    exit 0
fi

# アクティブな subtask を取得
ACTIVE_SUBTASK=$(jq -r '.active.subtask // empty' "$PROGRESS_FILE" 2>/dev/null)
ACTIVE_PHASE=$(jq -r '.active.phase // empty' "$PROGRESS_FILE" 2>/dev/null)

if [[ -z "$ACTIVE_SUBTASK" ]]; then
    exit 0
fi

# criterion を plan.json から取得
PLAN_FILE="$ROOT_DIR/$PLAYBOOK_ACTIVE"
CRITERION=""
if [[ -f "$PLAN_FILE" ]]; then
    CRITERION=$(jq -r --arg id "$ACTIVE_SUBTASK" \
        '.phases[].subtasks[] | select(.id == $id) | .criterion // empty' \
        "$PLAN_FILE" 2>/dev/null | head -1)
fi

# systemMessage としてリマインダーを出力
cat << EOF
{
  "systemMessage": "[Progress Reminder] ファイル編集が完了しました。\\n\\n現在の subtask: $ACTIVE_SUBTASK\\nCriterion: $CRITERION\\n\\n✅ 作業が完了したら progress.json を更新してください:\\n   - status: in_progress → done（critic 検証後）\\n   - validations の更新\\n   - validated_by: critic の設定\\n\\n⚠️ progress.json を更新せずに完了宣言すると、Stop Hook でブロックされます。"
}
EOF

exit 0
