#!/bin/bash
# session.sh - SessionStart/End/PreCompact 導火線
# セッションライフサイクルイベントを Skills に委譲

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVENTS_DIR="$SCRIPT_DIR/../events"
LIB_DIR="$SCRIPT_DIR/../lib"

# 共通ライブラリ読み込み
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

# 入力を読み込み
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "startup"')

# Skill を呼び出す関数
invoke_event_chain() {
    local unit="$1"
    local path="$EVENTS_DIR/$unit/chain.sh"
    if [[ -f "$path" ]]; then
        echo "$INPUT" | bash "$path"
    fi
}

case "$TRIGGER" in
    startup|resume|clear)
        invoke_event_chain "session-start"
        ;;
    end)
        invoke_event_chain "session-end"
        ;;
    compact)
        invoke_event_chain "pre-compact"
        ;;
esac

exit 0
