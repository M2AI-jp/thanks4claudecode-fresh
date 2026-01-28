#!/bin/bash
# session-start-chain.sh - event unit: session-start
# セッション開始時の統合チェーンエントリポイント
# Symlinked from .claude/events/session-start/chain.sh

set -euo pipefail

# Resolve actual script location (follow symlink)
REAL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_ROOT="$(cd "$REAL_DIR/.." && pwd)"
EVENT_DIR="$REPO_ROOT/.claude/events/session-start"
CLAUDE_DIR="$REPO_ROOT/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

INPUT=$(cat)

# ==============================================================================
# Telemetry (ログ記録)
# ==============================================================================
if [[ -x "$EVENT_DIR/telemetry.sh" ]]; then
    echo "$INPUT" | "$EVENT_DIR/telemetry.sh" 2>/dev/null || true
fi

# ==============================================================================
# Helper: Skill の呼び出し
# ==============================================================================
invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        echo "$INPUT" | bash "$path" 2>&1 || true
    fi
}

# ==============================================================================
# 1. Session Manager: セッション開始処理
# ==============================================================================
invoke_skill "session-manager" "handlers/start.sh"

# ==============================================================================
# 2. Health Check: システム健全性チェック
# ==============================================================================
HEALTH_CHECK="$SKILLS_DIR/quality-assurance/checkers/health.sh"
if [[ -x "$HEALTH_CHECK" ]]; then
    bash "$HEALTH_CHECK" 2>&1 || true
fi

# ==============================================================================
# 3. Integrity Check: リポジトリ整合性チェック
# ==============================================================================
INTEGRITY_CHECK="$SKILLS_DIR/quality-assurance/checkers/integrity.sh"
if [[ -x "$INTEGRITY_CHECK" ]]; then
    bash "$INTEGRITY_CHECK" 2>&1 || true
fi

exit 0
