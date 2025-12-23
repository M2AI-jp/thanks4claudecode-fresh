#!/bin/bash
# ==============================================================================
# role-resolver.sh - 役割名を具体的な executor に解決
# ==============================================================================
# 目的: 抽象的な役割名（orchestrator, worker, reviewer, human）を
#       具体的な executor（claudecode, codex, coderabbit, user）に解決する
#
# 使用方法:
#   echo 'worker' | bash role-resolver.sh
#   bash role-resolver.sh orchestrator
#
# 解決優先順位:
#   1. playbook.meta.roles（引数で PLAYBOOK_PATH を指定）
#   2. state.md config.roles
#   3. ハードコードされたデフォルト（toolstack に応じる）
#
# トリガー: utility（executor-guard.sh から呼び出される）
# ==============================================================================

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"
PLAYBOOK_PATH="${PLAYBOOK_PATH:-}"

# ==============================================================================
# 引数または stdin から役割名を取得
# ==============================================================================
if [[ $# -ge 1 ]]; then
    ROLE="$1"
else
    read -r ROLE || ROLE=""
fi

# 空の場合は何も出力しない
if [[ -z "$ROLE" ]]; then
    exit 0
fi

# ==============================================================================
# 既存の executor 名はそのまま返す（互換性）
# ==============================================================================
case "$ROLE" in
    claudecode|codex|coderabbit|user)
        echo "$ROLE"
        exit 0
        ;;
esac

# ==============================================================================
# Toolstack 取得（環境変数 > state.md > デフォルト "A"）
# ==============================================================================
if [[ -z "${TOOLSTACK:-}" ]]; then
    TOOLSTACK="A"  # デフォルト
    if [[ -f "$STATE_FILE" ]]; then
        TS=$(grep -A10 "^## config" "$STATE_FILE" 2>/dev/null | grep "toolstack:" | head -1 | sed 's/toolstack: *//' | sed 's/ *#.*//' | tr -d ' ')
        if [[ -n "$TS" ]]; then
            TOOLSTACK="$TS"
        fi
    fi
fi

# ==============================================================================
# state.md から roles マッピングを取得
# ==============================================================================
get_role_from_state() {
    local role_name="$1"
    if [[ -f "$STATE_FILE" ]]; then
        local value
        value=$(grep -A20 "^## config" "$STATE_FILE" 2>/dev/null | grep -A10 "roles:" | grep "${role_name}:" | head -1 | sed "s/${role_name}: *//" | sed 's/ *#.*//' | tr -d ' ')
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    return 1
}

# ==============================================================================
# playbook から roles マッピングを取得（override）
# ==============================================================================
get_role_from_playbook() {
    local role_name="$1"
    if [[ -n "$PLAYBOOK_PATH" && -f "$PLAYBOOK_PATH" ]]; then
        local value
        value=$(grep -A20 "^## meta" "$PLAYBOOK_PATH" 2>/dev/null | grep -A10 "roles:" | grep "${role_name}:" | head -1 | sed "s/${role_name}: *//" | sed 's/ *#.*//' | tr -d ' ')
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    return 1
}

# ==============================================================================
# デフォルト解決（toolstack に応じる）
# ==============================================================================
get_default_executor() {
    local role_name="$1"

    case "$role_name" in
        orchestrator)
            # 常に claudecode
            echo "claudecode"
            ;;
        worker)
            # A: claudecode, B/C: codex
            case "$TOOLSTACK" in
                A) echo "claudecode" ;;
                B|C) echo "codex" ;;
                *) echo "claudecode" ;;
            esac
            ;;
        reviewer)
            # A/B: claudecode, C: coderabbit
            case "$TOOLSTACK" in
                A|B) echo "claudecode" ;;
                C) echo "coderabbit" ;;
                *) echo "claudecode" ;;
            esac
            ;;
        human)
            # 常に user
            echo "user"
            ;;
        *)
            # 未知の役割名はそのまま返す
            echo "$role_name"
            ;;
    esac
}

# ==============================================================================
# 解決実行（優先順位順）
# ==============================================================================
# 1. playbook.meta.roles（override）
RESOLVED=$(get_role_from_playbook "$ROLE" || echo "")
if [[ -n "$RESOLVED" ]]; then
    echo "$RESOLVED"
    exit 0
fi

# 2. state.md config.roles
RESOLVED=$(get_role_from_state "$ROLE" || echo "")
if [[ -n "$RESOLVED" ]]; then
    echo "$RESOLVED"
    exit 0
fi

# 3. デフォルト（toolstack に応じる）
get_default_executor "$ROLE"
