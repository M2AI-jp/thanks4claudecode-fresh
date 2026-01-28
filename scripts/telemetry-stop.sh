#!/bin/bash
# telemetry-stop.sh - stop event telemetry
# Symlinked from .claude/events/stop/telemetry.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$REPO_ROOT/.claude/logs"
LOG_FILE="$LOG_DIR/stop.log"
mkdir -p "$LOG_DIR"
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_ENTRY=$(jq -n --arg ts "$TIMESTAMP" --arg sid "$SESSION_ID" --arg event "stop" --argjson input "$INPUT" '{timestamp: $ts, session_id: $sid, event: $event, status: "recorded", input: $input}' 2>/dev/null || echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"stop\",\"error\":\"jq_failed\"}")
echo "$LOG_ENTRY" >> "$LOG_FILE"
exit 0
