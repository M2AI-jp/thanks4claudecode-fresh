#!/usr/bin/env bash
# ==============================================================================
# .claude/skills/test-runner/scripts/run-build.sh - ビルドテスト
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "Running build test..."

# このプロジェクトはシェルスクリプトベースなので、
# ビルドテストは構文チェックと設定ファイルの検証を行う

echo "  Checking required files..."
REQUIRED_FILES=(
    "CLAUDE.md"
    "state.md"
    ".claude/settings.json"
    ".mcp.json"
)

FAILED=0
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$ROOT_DIR/$file" ]]; then
        echo "    ✓ $file"
    else
        echo "    ✗ $file (missing)"
        FAILED=1
    fi
done

echo ""
echo "  Validating JSON files..."

# settings.json の検証
if jq empty "$ROOT_DIR/.claude/settings.json" 2>/dev/null; then
    echo "    ✓ .claude/settings.json (valid JSON)"
else
    echo "    ✗ .claude/settings.json (invalid JSON)"
    FAILED=1
fi

# .mcp.json の検証
if jq empty "$ROOT_DIR/.mcp.json" 2>/dev/null; then
    echo "    ✓ .mcp.json (valid JSON)"
else
    echo "    ✗ .mcp.json (invalid JSON)"
    FAILED=1
fi

if [[ $FAILED -eq 0 ]]; then
    echo ""
    echo "Build test: PASS"
    exit 0
else
    echo ""
    echo "Build test: FAIL"
    exit 1
fi
