#\!/bin/sh
# orchestration-utils.sh - Codex 委譲のログ記録・検証ユーティリティ
# 作成: Codex (M5-T1 オーケストレーション検証タスクで委譲)

ORCHESTRATION_LOG_FILE=${ORCHESTRATION_LOG_FILE:-.claude/logs/subagent-dispatch.log}

log_delegation() {
  agent=${1:-UNKNOWN_AGENT}
  trigger=${2:-UNKNOWN_TRIGGER}
  result=${3:-UNKNOWN_RESULT}
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$(dirname "$ORCHESTRATION_LOG_FILE")" 2>/dev/null
  printf "%s | %s | %s | %s\n" "$timestamp" "$agent" "$trigger" "$result" >>"$ORCHESTRATION_LOG_FILE"
}

verify_delegation() {
  if [ \! -f "$ORCHESTRATION_LOG_FILE" ]; then
    echo "Log file not found" >&2
    return 1
  fi
  tail -n 1 "$ORCHESTRATION_LOG_FILE"
}
