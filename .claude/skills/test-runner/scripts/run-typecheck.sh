#!/usr/bin/env bash
# ==============================================================================
# .claude/skills/test-runner/scripts/run-typecheck.sh - シェルスクリプト構文チェック
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "Running shell script syntax check..."

FAILED=0
TOTAL=0

# 全シェルスクリプトの構文チェック
for script in $(find "$ROOT_DIR/.claude/skills" -name "*.sh" -type f 2>/dev/null); do
    TOTAL=$((TOTAL + 1))
    if bash -n "$script" 2>/dev/null; then
        echo "  ✓ $(basename "$script")"
    else
        echo "  ✗ $(basename "$script")"
        FAILED=$((FAILED + 1))
    fi
done

# hooks のシェルスクリプトもチェック
for script in $(find "$ROOT_DIR/.claude/hooks" -name "*.sh" -type f 2>/dev/null); do
    TOTAL=$((TOTAL + 1))
    if bash -n "$script" 2>/dev/null; then
        echo "  ✓ $(basename "$script")"
    else
        echo "  ✗ $(basename "$script")"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "Syntax check: $((TOTAL - FAILED))/$TOTAL passed"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
exit 0
