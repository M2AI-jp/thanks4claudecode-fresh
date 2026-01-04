#!/bin/bash
# subagent-stop.sh - SubagentStop Hook dispatcher
# Delegates to event unit chain.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVENTS_DIR="$SCRIPT_DIR/../events"
CHAIN="$EVENTS_DIR/subagent-stop/chain.sh"

if [[ -f "$CHAIN" ]]; then
    cat | bash "$CHAIN"
    exit $?
fi

cat >/dev/null
exit 0
