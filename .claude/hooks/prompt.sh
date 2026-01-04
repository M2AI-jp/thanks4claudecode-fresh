#!/bin/bash
# prompt.sh - UserPromptSubmit Hook dispatcher
# Delegates to event unit chain.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR="."
EVENTS_DIR="$SCRIPT_DIR/../events"
CHAIN="$EVENTS_DIR/user-prompt-submit/chain.sh"

if [[ -f "$CHAIN" ]]; then
    cat | bash "$CHAIN"
    exit $?
fi

# Fallback: no chain found
cat >/dev/null
exit 0
