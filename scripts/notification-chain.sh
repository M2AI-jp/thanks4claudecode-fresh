#!/bin/bash
# notification-chain.sh - event unit: notification
# Routes input to telemetry and passes through.
# Symlinked from .claude/events/notification/chain.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve actual script location (follow symlink)
REAL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_ROOT="$(cd "$REAL_DIR/.." && pwd)"
EVENT_DIR="$REPO_ROOT/.claude/events/notification"

# Read input once
INPUT=$(cat)

# Call telemetry (if exists and executable)
if [[ -x "$EVENT_DIR/telemetry.sh" ]]; then
    echo "$INPUT" | "$EVENT_DIR/telemetry.sh" 2>/dev/null || true
fi

exit 0
