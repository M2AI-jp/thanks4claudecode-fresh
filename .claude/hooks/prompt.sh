#!/bin/bash
# prompt.sh - UserPromptSubmit 導火線
# State Injection を実行
# ★ タスク依頼パターン検出時は Skill 強制発動 ★

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# タスク依頼パターンを検出
is_task_request() {
    local prompt="$1"
    # 作って/実装して/修正して/追加して/変更して/直して/作成して/やって/やり直して
    if echo "$prompt" | grep -qE '(作って|実装して|修正して|追加して|変更して|直して|作成して|やって|やり直して|して$|してOK|してね)'; then
        return 0
    fi
    return 1
}

# JSON 文字列をエスケープ
escape_json() {
    local str="$1"
    # 改行、タブ、バックスラッシュ、ダブルクォートをエスケープ
    printf '%s' "$str" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' '
}

# State Injection: 現在の状態を context に追加
inject_state() {
    local state_file="$REPO_ROOT/state.md"
    local playbook_active=""
    local phase=""
    local user_prompt="$1"

    if [[ -f "$state_file" ]]; then
        # playbook.active を取得
        playbook_active=$(grep -A5 "^## playbook" "$state_file" | grep "active:" | sed 's/.*active: *//' | tr -d '\r' || echo "null")
        # phase を取得
        phase=$(grep -A5 "^## goal" "$state_file" | grep "phase:" | sed 's/.*phase: *//' | tr -d '\r' || echo "unknown")
    fi

    # タスク依頼パターン検出 + playbook=null の場合
    if [[ ("$playbook_active" == "null" || -z "$playbook_active") ]] && is_task_request "$user_prompt"; then
        # ★★★ Skill 強制発動モード ★★★
        local escaped_prompt
        escaped_prompt=$(escape_json "$user_prompt")

        cat << EOF
{
  "decision": "continue",
  "messages": [
    {
      "role": "user",
      "content": "🚨 [TASK_REQUEST_DETECTED] タスク依頼パターンを検出しました。\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n⚠️ 強制指示: 以下の手順を厳守せよ\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n1. Skill(skill='playbook-init') を即座に呼び出せ\\n2. ユーザープロンプトを解釈するな（原文をそのまま渡せ）\\n3. prompt-analyzer が解釈を担当する\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n📝 ユーザープロンプト（原文・解釈禁止）:\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n${escaped_prompt}\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n🔴 禁止事項:\\n- 上記プロンプトを「つまり〜」と解釈すること\\n- 「未達成」「達成済み」などを勝手に判断すること\\n- Skill を呼ぶ前に何かを決定すること\\n\\n🟢 必須事項:\\n- Skill(skill='playbook-init', args='${escaped_prompt}') を呼ぶ\\n- args には原文をそのままコピペ"
    }
  ]
}
EOF
        return
    fi

    # 理解確認必須メッセージ（全プロンプト共通）
    local understanding_check_msg="🔍 理解確認必須: タスク依頼を受けたら、必ず理解確認（5W1H分析）を実施すること。understanding-check Skill を参照し、ユーザーの承認を得てから playbook 作成・実装に進む。スキップはユーザーの明示的要求がある場合のみ許可。"

    # playbook が null の場合の警告（タスク依頼パターンなし）
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
# stdin から JSON を読み取り、ユーザープロンプトを抽出
INPUT_JSON=$(cat)
USER_PROMPT=""

if command -v jq &> /dev/null; then
    USER_PROMPT=$(echo "$INPUT_JSON" | jq -r '.prompt // ""' 2>/dev/null || echo "")
fi

inject_state "$USER_PROMPT"
