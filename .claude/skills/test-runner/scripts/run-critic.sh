#!/usr/bin/env bash
# ==============================================================================
# .claude/skills/test-runner/scripts/run-critic.sh - Critic テスト実行
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "Running critic tests..."
bash "$ROOT_DIR/tests/critic/run-critic-tests.sh"
