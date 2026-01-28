#!/bin/bash
# /crit Skill handler - Codex 経由の critic 実行

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
STATE_FILE="$REPO_ROOT/state.md"

# playbook を取得
get_playbook_active() {
    grep -A5 "^## playbook" "$STATE_FILE" 2>/dev/null | \
        grep "^active:" | head -1 | sed 's/active: *//' | tr -d ' '
}

PLAYBOOK=$(get_playbook_active)

if [[ -z "$PLAYBOOK" || "$PLAYBOOK" == "null" ]]; then
    echo "ERROR: playbook が設定されていません" >&2
    exit 1
fi

PLAN_FILE="$REPO_ROOT/$PLAYBOOK"
if [[ ! -f "$PLAN_FILE" ]]; then
    echo "ERROR: plan.json が見つかりません: $PLAN_FILE" >&2
    exit 1
fi

# done_when を抽出
DONE_WHEN=$(jq -c '.goal.done_when' "$PLAN_FILE")

echo "=== /crit: Codex 経由の独立検証 ==="
echo ""
echo "playbook: $PLAYBOOK"
echo "done_when: $DONE_WHEN"
echo ""
echo "codex-delegate に委譲します..."

# 環境変数を設定して codex-delegate を呼び出すよう指示
cat <<EOF
CODEX_DELEGATE_INSTRUCTION:
  playbook: $PLAYBOOK
  done_when: $DONE_WHEN
  action: critic 評価を実行し、結果を progress.json に記録してください
EOF
