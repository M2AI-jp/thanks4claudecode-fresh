#!/bin/bash
# ==============================================================================
# failure-logger.sh - 失敗パターン記録ユーティリティ
# ==============================================================================
#
# 目的:
#   - Hook ブロック時の失敗パターンを記録
#   - learning Skill と連携して同じ問題を繰り返さない
#
# 使用方法（他の Hook から呼び出し）:
#   source .claude/hooks/failure-logger.sh
#   log_failure "hook_name" "context" "user_action"
#
# または直接実行:
#   echo '{"hook": "xxx", "context": "yyy", "action": "zzz"}' | bash failure-logger.sh
#
# ==============================================================================

LOG_DIR=".claude/logs"
LOG_FILE="$LOG_DIR/failures.log"
MAX_LOG_ENTRIES=100

# ==============================================================================
# 1. 失敗を記録する関数
# ==============================================================================

log_failure() {
    local hook_name="$1"
    local context="$2"
    local user_action="$3"

    mkdir -p "$LOG_DIR"

    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
    local branch=$(git branch --show-current 2>/dev/null || echo "unknown")

    # JSONL 形式で記録
    local entry=$(jq -n \
        --arg ts "$timestamp" \
        --arg hook "$hook_name" \
        --arg ctx "$context" \
        --arg action "$user_action" \
        --arg branch "$branch" \
        '{timestamp: $ts, hook: $hook, context: $ctx, user_action: $action, branch: $branch}')

    echo "$entry" >> "$LOG_FILE"

    # ログファイルが大きくなりすぎたら古いエントリを削除
    if [ -f "$LOG_FILE" ]; then
        local line_count=$(wc -l < "$LOG_FILE")
        if [ "$line_count" -gt "$MAX_LOG_ENTRIES" ]; then
            tail -n "$MAX_LOG_ENTRIES" "$LOG_FILE" > "$LOG_FILE.tmp"
            mv "$LOG_FILE.tmp" "$LOG_FILE"
        fi
    fi
}

# ==============================================================================
# 2. 同じ失敗パターンの回数をカウント
# ==============================================================================

count_similar_failures() {
    local hook_name="$1"
    local context="$2"

    if [ ! -f "$LOG_FILE" ]; then
        echo "0"
        return
    fi

    # 同じ hook と context の組み合わせをカウント
    local count=$(grep -c "\"hook\":\"$hook_name\".*\"context\":\"$context\"" "$LOG_FILE" 2>/dev/null || echo "0")
    echo "$count"
}

# ==============================================================================
# 3. 失敗パターンの警告を生成
# ==============================================================================

get_failure_warnings() {
    if [ ! -f "$LOG_FILE" ]; then
        return
    fi

    # 3回以上繰り返された失敗パターンを抽出
    local warnings=""
    local patterns=$(jq -r '[.hook, .context] | @csv' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -5)

    while IFS= read -r line; do
        local count=$(echo "$line" | awk '{print $1}')
        if [ "$count" -ge 3 ]; then
            local pattern=$(echo "$line" | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
            warnings="$warnings\n  ⚠️ 繰り返し発生: $pattern ($count 回)"
        fi
    done <<< "$patterns"

    if [ -n "$warnings" ]; then
        echo -e "$warnings"
    fi
}

# ==============================================================================
# 4. 直接実行時の処理（stdin から JSON を読む）
# ==============================================================================

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # stdin から JSON を読み込む
    INPUT=$(cat 2>/dev/null)

    if [ -n "$INPUT" ]; then
        HOOK=$(echo "$INPUT" | jq -r '.hook // "unknown"' 2>/dev/null)
        CONTEXT=$(echo "$INPUT" | jq -r '.context // ""' 2>/dev/null)
        ACTION=$(echo "$INPUT" | jq -r '.action // ""' 2>/dev/null)

        log_failure "$HOOK" "$CONTEXT" "$ACTION"
        echo "Logged failure: $HOOK"
    else
        # 引数が渡された場合
        if [ $# -ge 2 ]; then
            log_failure "$1" "$2" "${3:-}"
            echo "Logged failure: $1"
        else
            echo "Usage: failure-logger.sh <hook_name> <context> [user_action]"
            echo "   or: echo '{\"hook\": \"...\", \"context\": \"...\", \"action\": \"...\"}' | failure-logger.sh"
            exit 1
        fi
    fi
fi
