#!/bin/bash
# post-tool.sh - PostToolUse(*) 導火線
# ツール実行後の処理を Skills に委譲

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
EVENTS_DIR="$SCRIPT_DIR/../events"
LIB_DIR="$SCRIPT_DIR/../lib"

# 共通ライブラリ読み込み
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

# 入力を読み込み
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Skill を呼び出す関数（失敗しても継続）
invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        echo "$INPUT" | bash "$path" || true
    fi
}

invoke_event_chain() {
    local unit="$1"
    local path="$EVENTS_DIR/$unit/chain.sh"
    if [[ -f "$path" ]]; then
        echo "$INPUT" | bash "$path"
    fi
}

case "$TOOL_NAME" in
    Edit)
        invoke_event_chain "post-tool-edit"
        ;;
    Task)
        # SubAgent ログ記録（必要に応じて）
        ;;
esac

exit 0
