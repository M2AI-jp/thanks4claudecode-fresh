#!/usr/bin/env bash
# ==============================================================================
# .claude/skills/test-runner/scripts/run-e2e.sh - E2E テスト実行
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "Running E2E tests..."

E2E_DIR="$ROOT_DIR/tests/e2e"

if [[ -f "$E2E_DIR/contract-test.sh" ]]; then
    bash "$E2E_DIR/contract-test.sh"
else
    echo "  ⚠ E2E tests not yet implemented"
    echo "  Creating placeholder..."
    exit 0
fi
