#!/bin/bash
# prompt.sh - UserPromptSubmit 導火線
# State Injection を実行

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# State Injection: 現在の状態を context に追加
inject_state() {
    local state_file="$REPO_ROOT/state.md"
    local playbook_active=""
    local phase=""

    if [[ -f "$state_file" ]]; then
        # playbook.active を取得
        playbook_active=$(grep -A5 "^## playbook" "$state_file" | grep "active:" | sed 's/.*active: *//' | tr -d '\r' || echo "null")
        # phase を取得
        phase=$(grep -A5 "^## goal" "$state_file" | grep "phase:" | sed 's/.*phase: *//' | tr -d '\r' || echo "unknown")
    fi

    # playbook が null の場合の警告
    if [[ "$playbook_active" == "null" || -z "$playbook_active" ]]; then
        cat << 'EOF'
{
  "decision": "continue",
  "messages": [
    {
      "role": "user",
      "content": "[State Injection]\n\nplaybook.active = null\n\n⚠️ Core Contract #1: タスク依頼を受けたら Skill(skill='playbook-init') で playbook を作成すること。\n\n直接 Edit/Write してはいけない。"
    }
  ]
}
EOF
    else
        # 通常の State Injection
        cat << EOF
{
  "decision": "continue",
  "messages": [
    {
      "role": "user",
      "content": "[State Injection]\\n\\nplaybook.active = ${playbook_active}\\nphase = ${phase}"
    }
  ]
}
EOF
    fi
}

# メイン処理
inject_state
