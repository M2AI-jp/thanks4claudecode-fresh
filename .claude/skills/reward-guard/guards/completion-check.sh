#!/bin/bash
# ==============================================================================
# completion-check.sh - Stop Hook で未完了 subtask を検出
# ==============================================================================
# 目的: Claude が会話を終了しようとした時に、未完了の subtask がないか検証
#       progress.json を更新せずに完了宣言するバイパスを防止
#
# 設計思想:
#   - subtask-guard は受動的（編集時のみ発火）
#   - このスクリプトは能動的（終了時に強制チェック）
#   - 未完了 subtask があれば応答をブロック（exit 1）
#   - 報酬詐欺防止のため「強制」が必要
#
# トリガー: Stop Hook
# ==============================================================================

set -euo pipefail

INPUT=$(cat)

# jq チェック
if ! command -v jq &> /dev/null; then
    exit 0
fi

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

# 未完了の subtask を検出
INCOMPLETE_SUBTASKS=$(jq -r '
    .subtasks | to_entries[] |
    select(.value.status != "done") |
    "\(.key): \(.value.status)"
' "$PROGRESS_FILE" 2>/dev/null || echo "")

if [[ -z "$INCOMPLETE_SUBTASKS" ]]; then
    exit 0
fi

# アクティブな phase/subtask を取得
ACTIVE_PHASE=$(jq -r '.active.phase // "unknown"' "$PROGRESS_FILE" 2>/dev/null)
ACTIVE_SUBTASK=$(jq -r '.active.subtask // "unknown"' "$PROGRESS_FILE" 2>/dev/null)

# 未完了数をカウント
INCOMPLETE_COUNT=$(echo "$INCOMPLETE_SUBTASKS" | wc -l | tr -d ' ')

# エラーメッセージを stderr に出力してブロック（exit 1）
cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ 未完了の subtask があります - 応答をブロック
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Playbook: $PLAYBOOK_ACTIVE
Active: $ACTIVE_PHASE / $ACTIVE_SUBTASK
未完了: $INCOMPLETE_COUNT 件

$INCOMPLETE_SUBTASKS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

作業を完了するには:
1. 各 subtask の criterion を達成
2. critic SubAgent で検証
3. progress.json を更新（validated_by: critic）

報酬詐欺防止のため、未完了 subtask がある状態での
応答完了はブロックされます。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

exit 1
