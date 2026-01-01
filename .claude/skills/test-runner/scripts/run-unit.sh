#!/usr/bin/env bash
# ==============================================================================
# .claude/skills/test-runner/scripts/run-unit.sh - Unit テスト実行
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "Running guard unit tests..."
bash "$ROOT_DIR/tests/guards/run-all.sh"
