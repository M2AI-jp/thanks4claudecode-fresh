#!/bin/bash
# chain.sh - event unit: user-prompt-submit
# Current: moved logic from .claude/hooks/prompt.sh (state injection + analyzer guidance).

set +e

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || EVENT_DIR="."
REPO_ROOT="$(cd "$EVENT_DIR/../../.." 2>/dev/null && pwd)" || REPO_ROOT="."
MARKER_FILE="$REPO_ROOT/.claude/session-state/prompt-analyzer-called"

# New prompt resets analyzer marker
rm -f "$MARKER_FILE" 2>/dev/null

# state.md から情報を取得
get_state_info() {
    local state_file="$REPO_ROOT/state.md"

    if [[ ! -f "$state_file" ]]; then
        echo "playbook_active=null"
        echo "phase=unknown"
        return
    fi

    # playbook.active を取得
    local playbook_active
    playbook_active=$(grep -A5 "^## playbook" "$state_file" 2>/dev/null | grep "active:" | sed 's/.*active: *//' | tr -d '\r' || echo "null")
    playbook_active=${playbook_active:-null}

    # phase を取得
    local phase
    phase=$(grep -A5 "^## goal" "$state_file" 2>/dev/null | grep "phase:" | sed 's/.*phase: *//' | tr -d '\r' || echo "unknown")
    phase=${phase:-unknown}

    echo "playbook_active=$playbook_active"
    echo "phase=$phase"
}

# playbook の subtask 進捗を取得
get_subtask_progress() {
    local playbook_path="$1"
    local phase="$2"

    if [[ ! -f "$playbook_path" ]] || [[ -z "$phase" ]] || [[ "$phase" == "unknown" ]] || [[ "$phase" == "null" ]]; then
        return
    fi

    # 現在 Phase のセクションを抽出
    local phase_section
    phase_section=$(awk "/^### ${phase}:/,/^---\$/" "$playbook_path" 2>/dev/null)

    if [[ -z "$phase_section" ]]; then
        return
    fi

    # 完了/未完了をカウント
    local completed incomplete total
    completed=$(echo "$phase_section" | grep -c '\\- \\[x\\]' 2>/dev/null || echo "0")
    completed=${completed:-0}
    incomplete=$(echo "$phase_section" | grep -c '\\- \\[ \\]' 2>/dev/null || echo "0")
    incomplete=${incomplete:-0}
    total=$((completed + incomplete))

    if [[ "$total" -gt 0 ]]; then
        echo "Phase $phase: $completed/$total subtask done ($incomplete remaining)"
    fi
}

# メイン出力を生成
generate_output() {
    # state 情報を取得
    eval "$(get_state_info)"

    echo "=== State Injection ==="
    echo ""
    echo "playbook.active = $playbook_active"
    echo "phase = $phase"

    # 全プロンプトで prompt-analyzer を呼び出す指示
    echo ""
    echo "--- Prompt Analysis Required ---"
    echo ""
    echo "1. prompt-analyzer を呼び出せ:"
    echo "   Task(subagent_type='prompt-analyzer', prompt='ユーザープロンプト原文')"
    echo ""
    echo "2. prompt-analyzer の出力をそのままチャットに貼り付けろ（変換禁止）"
    echo ""
    echo "3. prompt-analyzer の next_action に従って分岐:"
    echo "   playbook-init     -> Skill(skill='playbook-init')"
    echo "   direct-answer     -> 直接回答"
    echo "   integrate-context -> 現在のタスクに統合"
    echo ""

    if [[ "$playbook_active" == "null" ]] || [[ -z "$playbook_active" ]]; then
        # playbook がない場合
        echo "--- Current State ---"
        echo "playbook: なし"
        echo "重要: Edit/Write は playbook がないとブロックされます（タスク依頼の場合）"
    else
        # playbook がある場合
        local playbook_path="$REPO_ROOT/$playbook_active"
        local progress
        progress=$(get_subtask_progress "$playbook_path" "$phase")

        if [[ -n "$progress" ]]; then
            echo ""
            echo "--- Progress ---"
            echo "$progress"
            echo ""
            echo "subtask 完了時: playbook を更新し、critic で検証してください"
        fi
    fi
}

generate_output

exit 0
