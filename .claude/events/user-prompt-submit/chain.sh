#!/bin/bash
# chain.sh - event unit: user-prompt-submit
# Current: moved logic from .claude/hooks/prompt.sh (state injection + analyzer guidance).

set +e

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || EVENT_DIR="."
REPO_ROOT="$(cd "$EVENT_DIR/../../.." 2>/dev/null && pwd)" || REPO_ROOT="."
SESSION_STATE_DIR="$REPO_ROOT/.claude/session-state"
AUTO_APPROVE_FILE="$SESSION_STATE_DIR/auto-approve.enabled"
LAST_PROMPT_FILE="$SESSION_STATE_DIR/last-user-prompt.txt"
PROMPT_ANALYZER_MARKER="$SESSION_STATE_DIR/prompt-analyzer-called"
PM_MARKER="$SESSION_STATE_DIR/pm-called"

INPUT=$(cat)

mkdir -p "$SESSION_STATE_DIR"

PLAYBOOK_ACTIVE="null"
if [[ -f "$REPO_ROOT/state.md" ]]; then
    PLAYBOOK_ACTIVE=$(grep -A5 "^## playbook" "$REPO_ROOT/state.md" 2>/dev/null | \
        grep "active:" | head -1 | sed 's/.*active: *//' | tr -d '\r ')
    PLAYBOOK_ACTIVE=${PLAYBOOK_ACTIVE:-null}
fi

if [[ -z "$PLAYBOOK_ACTIVE" || "$PLAYBOOK_ACTIVE" == "null" ]]; then
    rm -f "$PROMPT_ANALYZER_MARKER" 2>/dev/null
    rm -f "$PM_MARKER" 2>/dev/null
fi

# ユーザープロンプト抽出（UserPromptSubmit input）
PROMPT=""
if command -v jq &>/dev/null; then
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")
fi

if [[ -n "$PROMPT" ]]; then
    printf "%s" "$PROMPT" > "$LAST_PROMPT_FILE"
fi

# 簡易判定（instruction / question / context）
TASK_PATTERN='(作成|作っ|実装|修正|追加|変更|削除|作りたい|欲しい|ほしい|してほしい|して欲しい|お願い|create|build|implement|fix|add|remove|refactor)'
AUTO_DISABLE_PATTERN='(確認したい|相談したい|質問したい|確認を取りたい|一度相談|確認してから)'

IS_TASK_REQUEST=false
if printf "%s" "$PROMPT" | grep -Eiq "$TASK_PATTERN"; then
    IS_TASK_REQUEST=true
fi

AUTO_APPROVE=false
if [[ "$IS_TASK_REQUEST" == "true" ]]; then
    AUTO_APPROVE=true
    if printf "%s" "$PROMPT" | grep -Eiq "$AUTO_DISABLE_PATTERN"; then
        AUTO_APPROVE=false
    fi
fi

if [[ "$AUTO_APPROVE" == "true" ]]; then
    touch "$AUTO_APPROVE_FILE"
else
    rm -f "$AUTO_APPROVE_FILE" 2>/dev/null
fi

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
    local plan_path="$1"
    local phase="$2"

    if [[ ! -f "$plan_path" ]] || [[ -z "$phase" ]] || [[ "$phase" == "unknown" ]] || [[ "$phase" == "null" ]]; then
        return
    fi

    local progress_path
    progress_path="$(dirname "$plan_path")/progress.json"
    if [[ ! -f "$progress_path" ]]; then
        return
    fi

    local total completed incomplete
    total=$(jq -r --arg phase "$phase" '.phases[] | select(.id==$phase) | .subtasks | length' "$plan_path" 2>/dev/null || echo "0")
    total=${total:-0}

    completed=0
    if [[ "$total" -gt 0 ]]; then
        for subtask in $(jq -r --arg phase "$phase" '.phases[] | select(.id==$phase) | .subtasks[].id' "$plan_path" 2>/dev/null || echo ""); do
            status=$(jq -r --arg id "$subtask" '.subtasks[$id].status // empty' "$progress_path" 2>/dev/null || echo "")
            if [[ "$status" == "done" ]]; then
                completed=$((completed + 1))
            fi
        done
    fi

    incomplete=$((total - completed))

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

    # 自動フロー指示
    echo ""
    echo "--- Auto Flow ---"
    echo ""
    echo "instruction_detected = $IS_TASK_REQUEST"
    echo "auto_approve = $AUTO_APPROVE"
    echo ""
    echo "next_action:"
    if [[ "$playbook_active" == "null" ]] || [[ -z "$playbook_active" ]]; then
        if [[ "$IS_TASK_REQUEST" == "true" ]]; then
            echo "  - Skill(skill='playbook-init') を直ちに実行"
            echo "  - playbook-init 内で prompt-analyzer を自動実行すること"
            if [[ "$AUTO_APPROVE" == "true" ]]; then
                echo "  - understanding-check は自動承認（AskUserQuestion をスキップ）"
            else
                echo "  - understanding-check は AskUserQuestion で確認"
            fi
        else
            echo "  - 直接回答（question）または文脈統合（context）"
        fi
    else
        echo "  - 既存 playbook に統合（integrate-context）"
    fi
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
            echo "subtask 完了時: progress.json を更新し、critic で検証してください"
        fi
    fi
}

generate_output

exit 0
