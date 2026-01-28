#!/bin/bash
# telemetry-pre-tool-edit.sh - pre-tool-edit event telemetry
set -euo pipefail
REAL_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$REPO_ROOT/.claude/logs"
LOG_FILE="$LOG_DIR/pre-tool-edit.log"
mkdir -p "$LOG_DIR"
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_ENTRY=$(jq -n --arg ts "$TIMESTAMP" --arg sid "$SESSION_ID" --arg event "pre-tool-edit" --arg tool "$TOOL" --argjson input "$INPUT" '{timestamp: $ts, session_id: $sid, event: $event, tool: $tool, status: "recorded", input: $input}' 2>/dev/null || echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"pre-tool-edit\",\"error\":\"jq_failed\"}")
echo "$LOG_ENTRY" >> "$LOG_FILE"
exit 0
