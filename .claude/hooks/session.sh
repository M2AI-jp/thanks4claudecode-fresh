#!/bin/bash
# session.sh - SessionStart/End/PreCompact 導火線
# セッションライフサイクルイベントを Skills に委譲

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
LIB_DIR="$SCRIPT_DIR/../lib"

# 共通ライブラリ読み込み
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

# 入力を読み込み
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "startup"')

# Skill を呼び出す関数
invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        echo "$INPUT" | bash "$path"
    fi
}

case "$TRIGGER" in
    startup|resume|clear)
        invoke_skill "session-manager" "handlers/start.sh"
        ;;
    end)
        invoke_skill "session-manager" "handlers/end.sh"
        ;;
    compact)
        invoke_skill "session-manager" "handlers/compact.sh"
        ;;
esac

exit 0
