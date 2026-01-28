#!/bin/bash
# subagent-stop-chain.sh - event unit: subagent-stop
# Symlinked from .claude/events/subagent-stop/chain.sh

set -euo pipefail

REAL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_ROOT="$(cd "$REAL_DIR/.." && pwd)"
EVENT_DIR="$REPO_ROOT/.claude/events/subagent-stop"
CLAUDE_DIR="$REPO_ROOT/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

INPUT=$(cat)

# Telemetry
if [[ -x "$EVENT_DIR/telemetry.sh" ]]; then
    echo "$INPUT" | "$EVENT_DIR/telemetry.sh" 2>/dev/null || true
fi

if ! command -v jq &> /dev/null; then
    echo "[FAIL-CLOSED] jq not found - blocking for security" >&2
    exit 2
fi

AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

LOG_DIR="$CLAUDE_DIR/logs"
mkdir -p "$LOG_DIR"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] SubAgent stopped: $AGENT_ID (session: $SESSION_ID)" >> "$LOG_DIR/subagent.log"

STATE_FILE="$REPO_ROOT/state.md"
if [ -f "$STATE_FILE" ]; then
    ACTIVE_PLAYBOOK=$(grep '^active:' "$STATE_FILE" 2>/dev/null | sed 's/active: *//' | tr -d ' ')

    if [ -n "$ACTIVE_PLAYBOOK" ] && [ "$ACTIVE_PLAYBOOK" != "null" ] && [ -f "$REPO_ROOT/$ACTIVE_PLAYBOOK" ]; then
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Checking playbook completion: $ACTIVE_PLAYBOOK" >> "$LOG_DIR/subagent.log"

        ARCHIVE_SCRIPT="$SKILLS_DIR/playbook-gate/workflow/archive-playbook.sh"
        if [ -x "$ARCHIVE_SCRIPT" ]; then
            PROGRESS_PATH=$(echo "$ACTIVE_PLAYBOOK" | sed 's/plan\.json$/progress.json/')
            if [ -f "$REPO_ROOT/$PROGRESS_PATH" ]; then
                PSEUDO_INPUT=$(cat <<EOF2
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "$REPO_ROOT/$PROGRESS_PATH"
  }
}
EOF2
)
                set +e
                ARCHIVE_OUTPUT=$(echo "$PSEUDO_INPUT" | bash "$ARCHIVE_SCRIPT" 2>&1)
                ARCHIVE_EXIT_CODE=$?
                set -e

                echo "$ARCHIVE_OUTPUT" | tee -a "$LOG_DIR/subagent.log"

                case $ARCHIVE_EXIT_CODE in
                    0)
                        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] archive-playbook.sh completed (exit 0)" >> "$LOG_DIR/subagent.log"
                        ;;
                    2)
                        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] archive-playbook.sh blocked (exit 2) - awaiting completion" >> "$LOG_DIR/subagent.log"
                        ;;
                    *)
                        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] archive-playbook.sh failed with exit code $ARCHIVE_EXIT_CODE" >> "$LOG_DIR/subagent.log"
                        echo "[WARN] SubagentStop: archive-playbook.sh failed (exit $ARCHIVE_EXIT_CODE)" >&2
                        ;;
                esac
            else
                echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] progress.json not found: $PROGRESS_PATH" >> "$LOG_DIR/subagent.log"
            fi
        fi
    fi
fi

exit 0
