#!/bin/bash
# chain.sh - event unit: stop
# Claude が会話を終了しようとした時に発火

set -euo pipefail

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$EVENT_DIR/../.." && pwd)"
SKILLS_DIR="$CLAUDE_DIR/skills"

INPUT=$(cat)

# completion-check は exit code を伝播させる（ブロック機能）
COMPLETION_CHECK="$SKILLS_DIR/reward-guard/guards/completion-check.sh"
if [[ -x "$COMPLETION_CHECK" ]]; then
    echo "$INPUT" | bash "$COMPLETION_CHECK"
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        exit $EXIT_CODE
    fi
fi

exit 0
