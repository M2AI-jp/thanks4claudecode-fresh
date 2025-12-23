#!/bin/bash
# ==============================================================================
# state-schema.sh - state.md のスキーマ定義（単一定義源）
# ==============================================================================
# 目的: state.md のセクション名とパスを一元管理
# 使用方法: 各 Hook で source してスキーマを参照
#
# 【依存性逆転原則 (DIP)】
# 各 Hook はこのスキーマに依存し、state.md の詳細に直接依存しない
# ==============================================================================

# --------------------------------------------------
# セクション名定義
# --------------------------------------------------
SECTION_FOCUS="## focus"
SECTION_PLAYBOOK="## playbook"
SECTION_GOAL="## goal"
SECTION_SESSION="## session"
SECTION_CONFIG="## config"

# --------------------------------------------------
# フィールド名定義
# --------------------------------------------------
FIELD_CURRENT="current:"
FIELD_ACTIVE="active:"
FIELD_BRANCH="branch:"
FIELD_MILESTONE="milestone:"
FIELD_PHASE="phase:"
FIELD_SECURITY="security:"
FIELD_LAST_START="last_start:"
FIELD_LAST_END="last_end:"
FIELD_LAST_ARCHIVED="last_archived:"

# --------------------------------------------------
# ファイルパス定義
# --------------------------------------------------
STATE_FILE="${STATE_FILE:-state.md}"
PLAYBOOK_DIR="plan"

# --------------------------------------------------
# Getter 関数
# --------------------------------------------------

# focus.current を取得
get_focus_current() {
    grep -A5 "$SECTION_FOCUS" "$STATE_FILE" | grep "$FIELD_CURRENT" | head -1 | sed "s/$FIELD_CURRENT *//" | sed 's/ *#.*//' | tr -d ' '
}

# playbook.active を取得
get_playbook_active() {
    grep -A5 "$SECTION_PLAYBOOK" "$STATE_FILE" | grep "$FIELD_ACTIVE" | head -1 | sed "s/$FIELD_ACTIVE *//" | sed 's/ *#.*//' | tr -d ' '
}

# playbook.branch を取得
get_playbook_branch() {
    grep -A5 "$SECTION_PLAYBOOK" "$STATE_FILE" | grep "$FIELD_BRANCH" | head -1 | sed "s/$FIELD_BRANCH *//" | sed 's/ *#.*//' | tr -d ' '
}

# goal.milestone を取得
get_goal_milestone() {
    grep -A5 "$SECTION_GOAL" "$STATE_FILE" | grep "$FIELD_MILESTONE" | head -1 | sed "s/$FIELD_MILESTONE *//" | sed 's/ *#.*//' | tr -d ' '
}

# goal.phase を取得
get_goal_phase() {
    grep -A5 "$SECTION_GOAL" "$STATE_FILE" | grep "$FIELD_PHASE" | head -1 | sed "s/$FIELD_PHASE *//" | sed 's/ *#.*//' | tr -d ' '
}

# config.security を取得
get_security_mode() {
    grep -A10 "$SECTION_CONFIG" "$STATE_FILE" | grep "$FIELD_SECURITY" | head -1 | sed "s/$FIELD_SECURITY *//" | sed 's/ *#.*//' | tr -d ' '
}

# session.last_start を取得
get_session_last_start() {
    grep -A5 "$SECTION_SESSION" "$STATE_FILE" | grep "$FIELD_LAST_START" | head -1 | sed "s/$FIELD_LAST_START *//" | sed 's/ *#.*//'
}

# --------------------------------------------------
# Validation 関数
# --------------------------------------------------

# state.md の必須セクションが存在するか確認
validate_state_structure() {
    local missing=""

    grep -q "$SECTION_FOCUS" "$STATE_FILE" || missing+="focus "
    grep -q "$SECTION_PLAYBOOK" "$STATE_FILE" || missing+="playbook "
    grep -q "$SECTION_GOAL" "$STATE_FILE" || missing+="goal "
    grep -q "$SECTION_CONFIG" "$STATE_FILE" || missing+="config "

    if [[ -n "$missing" ]]; then
        echo "Missing sections: $missing" >&2
        return 1
    fi
    return 0
}

# playbook と milestone の整合性を確認
validate_playbook_milestone_consistency() {
    local playbook=$(get_playbook_active)
    local milestone=$(get_goal_milestone)

    # playbook が存在するのに milestone が null は不整合
    if [[ -n "$playbook" && "$playbook" != "null" ]]; then
        if [[ -z "$milestone" || "$milestone" == "null" ]]; then
            echo "Inconsistency: playbook exists but milestone is null" >&2
            return 1
        fi
    fi
    return 0
}

# ==============================================================================
# 使用例:
#   source .claude/schema/state-schema.sh
#   FOCUS=$(get_focus_current)
#   PLAYBOOK=$(get_playbook_active)
# ==============================================================================
