#!/bin/bash
# ==============================================================================
# common.sh - Hook 共通ライブラリ
# ==============================================================================
# 全 Hook で共通して使用する関数と定数を定義
# 使用方法: source "$(dirname "$0")/lib/common.sh"
# ==============================================================================

# ------------------------------------------------------------------------------
# 色定義
# ------------------------------------------------------------------------------
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# パス定義
# ------------------------------------------------------------------------------
get_workspace_root() {
    # このスクリプトが .claude/hooks/lib/ にあることを前提
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "$script_dir/../../.." && pwd)"
}

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(get_workspace_root)}"
STATE_MD="$WORKSPACE_ROOT/state.md"
CONTEXT_MD="$WORKSPACE_ROOT/CONTEXT.md"
CLAUDE_MD="$WORKSPACE_ROOT/CLAUDE.md"
SPEC_YAML="$WORKSPACE_ROOT/spec.yaml"
ROADMAP_MD="$WORKSPACE_ROOT/plan/roadmap.md"
FILE_DEPS="$WORKSPACE_ROOT/.claude/file-dependencies.yaml"

# ------------------------------------------------------------------------------
# state.md からの値取得関数
# ------------------------------------------------------------------------------

# session タイプを取得（TASK | CHAT | QUESTION | META）
# prompt-validator.sh が自動更新する
get_session() {
    if [ -f "$STATE_MD" ]; then
        grep -A5 "^## focus" "$STATE_MD" | grep "session:" | head -1 | sed 's/.*session:[[:space:]]*//' | sed 's/[[:space:]]*#.*//'
    else
        echo "QUESTION"  # デフォルト
    fi
}

# focus.current を取得（plan-template | workspace | setup | product）
get_focus() {
    if [ -f "$STATE_MD" ]; then
        grep -A5 "^## focus" "$STATE_MD" | grep "current:" | head -1 | sed 's/.*current:[[:space:]]*//' | sed 's/[[:space:]]*#.*//'
    else
        echo "workspace"
    fi
}

# security.mode を取得（strict | trusted | developer | admin）
get_security_mode() {
    if [ -f "$STATE_MD" ]; then
        grep -A3 "^## security" "$STATE_MD" | grep "mode:" | head -1 | sed 's/.*mode:[[:space:]]*//' | sed 's/[[:space:]]*#.*//'
    else
        echo "strict"
    fi
}

# active_playbooks から現在の focus に対応する playbook を取得
get_playbook() {
    local focus="${1:-$(get_focus)}"
    if [ -f "$STATE_MD" ]; then
        grep -A10 "^## active_playbooks" "$STATE_MD" | grep "^${focus}:" | sed 's/.*:[[:space:]]*//' | sed 's/[[:space:]]*#.*//'
    else
        echo "null"
    fi
}

# plan_hierarchy.current_milestone を取得
get_current_milestone() {
    if [ -f "$STATE_MD" ]; then
        grep -A20 "^## plan_hierarchy" "$STATE_MD" | grep "current_milestone:" | head -1 | sed 's/.*current_milestone:[[:space:]]*//' | sed 's/[[:space:]]*#.*//'
    else
        echo ""
    fi
}

# plan_hierarchy.current_phase を取得
get_current_phase() {
    if [ -f "$STATE_MD" ]; then
        grep -A20 "^## plan_hierarchy" "$STATE_MD" | grep "current_phase:" | head -1 | sed 's/.*current_phase:[[:space:]]*//' | sed 's/[[:space:]]*#.*//'
    else
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# Git 関連関数
# ------------------------------------------------------------------------------

# 現在のブランチ名を取得
get_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

# main ブランチにいるかどうか
is_main_branch() {
    local branch=$(get_branch)
    [ "$branch" = "main" ] || [ "$branch" = "master" ]
}

# 未コミット変更があるか
has_uncommitted_changes() {
    [ -n "$(git status --porcelain 2>/dev/null)" ]
}

# 未 push コミットがあるか
has_unpushed_commits() {
    local upstream=$(git rev-parse --abbrev-ref @{u} 2>/dev/null)
    if [ -n "$upstream" ]; then
        [ -n "$(git log "$upstream"..HEAD --oneline 2>/dev/null)" ]
    else
        return 1
    fi
}

# ------------------------------------------------------------------------------
# roadmap 関連関数
# ------------------------------------------------------------------------------

# roadmap.current_focus.milestone を取得
get_roadmap_milestone() {
    if [ -f "$ROADMAP_MD" ]; then
        grep -A5 "^## current_focus" "$ROADMAP_MD" | grep "milestone:" | head -1 | sed 's/.*milestone:[[:space:]]*//' | sed 's/[[:space:]]*#.*//'
    else
        echo ""
    fi
}

# roadmap.current_focus.next_actions を取得（配列として）
get_roadmap_next_actions() {
    if [ -f "$ROADMAP_MD" ]; then
        grep -A20 "^## current_focus" "$ROADMAP_MD" | grep -A10 "next_actions:" | grep "^\s*-" | sed 's/^\s*-\s*//'
    fi
}

# ------------------------------------------------------------------------------
# ファイル依存関係関数
# ------------------------------------------------------------------------------

# 指定ファイルの依存先を取得
get_file_dependencies() {
    local file="$1"
    if [ -f "$FILE_DEPS" ]; then
        # file-dependencies.yaml から該当ファイルの affects を取得
        local in_section=0
        while IFS= read -r line; do
            if echo "$line" | grep -q "\"$file\":"; then
                in_section=1
                continue
            fi
            if [ $in_section -eq 1 ]; then
                if echo "$line" | grep -q "affects:"; then
                    echo "$line" | sed 's/.*affects:\s*\[//' | sed 's/\].*//' | tr ',' '\n' | sed 's/^\s*//' | sed 's/\s*$//'
                    break
                fi
                # 次のセクションに入ったら終了
                if echo "$line" | grep -q "^  \""; then
                    break
                fi
            fi
        done < "$FILE_DEPS"
    fi
}

# ------------------------------------------------------------------------------
# 出力関数
# ------------------------------------------------------------------------------

# エラー出力
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# 警告出力
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

# 情報出力
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# 成功出力
log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

# セパレータ出力
print_separator() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ------------------------------------------------------------------------------
# Hook 共通チェック関数
# ------------------------------------------------------------------------------

# session が TASK 以外ならスキップ（CHAT, QUESTION, META は guard をスキップ）
should_skip_for_non_task() {
    local session=$(get_session)
    [ "$session" != "TASK" ]
}

# 後方互換性のため残す（非推奨）
should_skip_for_discussion() {
    should_skip_for_non_task
}

# state.md への編集は常に許可（デッドロック回避）
is_state_md_edit() {
    local file="$1"
    [ "$file" = "state.md" ] || [ "$file" = "$STATE_MD" ]
}

# Read/Grep/Glob ツールは許可
is_read_only_tool() {
    local tool="$1"
    [ "$tool" = "Read" ] || [ "$tool" = "Grep" ] || [ "$tool" = "Glob" ]
}

# ------------------------------------------------------------------------------
# SubAgent 関連関数
# ------------------------------------------------------------------------------

# SubAgent 発動ログに記録
log_subagent_dispatch() {
    local agent_name="$1"
    local trigger="$2"
    local result="${3:-COMPLETED}"
    local log_file="$WORKSPACE_ROOT/.claude/logs/subagent-dispatch.log"

    mkdir -p "$(dirname "$log_file")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | $agent_name | $trigger | $result" >> "$log_file"
}

# 直近の SubAgent 呼び出しをチェック
check_recent_subagent() {
    local agent_name="$1"
    local since_minutes="${2:-30}"
    local log_file="$WORKSPACE_ROOT/.claude/logs/subagent-dispatch.log"

    if [ ! -f "$log_file" ]; then
        return 1
    fi

    # 直近 N 分以内に呼び出しがあったか
    local since_time=$(date -u -v-${since_minutes}M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "${since_minutes} minutes ago" +"%Y-%m-%dT%H:%M:%SZ")
    grep "$agent_name" "$log_file" | while read line; do
        local log_time=$(echo "$line" | cut -d'|' -f1 | tr -d ' ')
        if [[ "$log_time" > "$since_time" ]]; then
            return 0
        fi
    done
    return 1
}

# ------------------------------------------------------------------------------
# JSON パース関数（jq 依存）
# ------------------------------------------------------------------------------

# stdin から JSON を読み、指定フィールドを取得
json_get() {
    local field="$1"
    jq -r ".$field // empty" 2>/dev/null
}

# PreToolUse の tool_input から file_path を取得
get_tool_file_path() {
    jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null
}

# PreToolUse の tool_input から command を取得
get_tool_command() {
    jq -r '.tool_input.command // empty' 2>/dev/null
}

# ------------------------------------------------------------------------------
# 初期化（source 時に実行）
# ------------------------------------------------------------------------------

# WORKSPACE_ROOT が存在しない場合はエラー
if [ ! -d "$WORKSPACE_ROOT" ]; then
    log_error "Workspace root not found: $WORKSPACE_ROOT"
fi
