#!/bin/bash
# chain.sh - event unit: session-start
# Current: thin wrapper to existing session-manager handler.

set -euo pipefail

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$EVENT_DIR/../.." && pwd)"
SKILLS_DIR="$CLAUDE_DIR/skills"

INPUT=$(cat)

invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        echo "$INPUT" | bash "$path"
    fi
}

invoke_skill "session-manager" "handlers/start.sh"
