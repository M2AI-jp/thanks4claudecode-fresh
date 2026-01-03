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

    # 理解確認必須メッセージ（全プロンプト共通）
    local understanding_check_msg="🔍 理解確認必須: タスク依頼を受けたら、必ず理解確認（5W1H分析）を実施すること。understanding-check Skill を参照し、ユーザーの承認を得てから playbook 作成・実装に進む。スキップはユーザーの明示的要求がある場合のみ許可。"

    # playbook が null の場合の警告
    if [[ "$playbook_active" == "null" || -z "$playbook_active" ]]; then
        cat << EOF
{
  "decision": "continue",
  "messages": [
    {
      "role": "user",
      "content": "[State Injection]\\n\\nplaybook.active = null\\n\\n⚠️ Core Contract #1: タスク依頼を受けたら Skill(skill='playbook-init') で playbook を作成すること。\\n\\n直接 Edit/Write してはいけない。\\n\\n${understanding_check_msg}"
    }
  ]
}
EOF
    else
        # playbook が存在する場合、現在 Phase の subtask 状況を取得
        local subtask_reminder=""
        local playbook_path="$REPO_ROOT/$playbook_active"

        if [[ -f "$playbook_path" && -n "$phase" && "$phase" != "unknown" ]]; then
            # 現在 Phase の subtask 完了状況を取得
            local phase_section
            phase_section=$(awk "/^### ${phase}:/,/^---\$/" "$playbook_path" 2>/dev/null)

            # pipefail 環境で grep -c が 0 件時に exit 1 を返す問題を回避
            # || true で exit code を 0 にし、空の場合のみデフォルト値を設定
            local completed
            completed=$(echo "$phase_section" | grep -c '\- \[x\]' 2>/dev/null || true)
            completed=${completed:-0}
            local incomplete
            incomplete=$(echo "$phase_section" | grep -c '\- \[ \]' 2>/dev/null || true)
            incomplete=${incomplete:-0}
            local total=$((completed + incomplete))

            if [[ "$incomplete" -gt 0 ]]; then
                subtask_reminder="\\n\\n📋 Phase ${phase} の進捗: ${completed}/${total} subtask 完了（未完了: ${incomplete}）\\n⚠️ 報酬詐欺防止: subtask 完了時は必ず playbook チェックボックスを更新し、critic を呼び出すこと"
            fi
        fi

        # 通常の State Injection（理解確認メッセージ + subtask リマインダー）
        cat << EOF
{
  "decision": "continue",
  "messages": [
    {
      "role": "user",
      "content": "[State Injection]\\n\\nplaybook.active = ${playbook_active}\\nphase = ${phase}${subtask_reminder}\\n\\n${understanding_check_msg}"
    }
  ]
}
EOF
    fi
}

# メイン処理
inject_state
