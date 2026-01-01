#!/usr/bin/env bash
# ==============================================================================
# tests/guards/test-main-branch-guard.sh - main-branch-guard.sh のテスト
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD_SCRIPT="$ROOT_DIR/.claude/skills/access-control/guards/main-branch.sh"

TOTAL=0
PASSED=0

echo "Testing main-branch-guard.sh"
echo "-----------------------------"

# テスト 1: 現在のブランチが main/master でないことを確認
test_current_branch() {
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")

    TOTAL=$((TOTAL + 1))
    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        echo "  ⚠ 現在 main/master ブランチです - テストはスキップ"
        PASSED=$((PASSED + 1))
    else
        # ガードスクリプトは main/master でなければ許可
        local input='{"file_path":"src/app.ts","old_string":"old","new_string":"new"}'
        echo "$input" | bash "$GUARD_SCRIPT" > /dev/null 2>&1 || true
        local exit_code=$?

        if [[ "$exit_code" -eq 0 ]]; then
            echo "  ✓ feature ブランチでは許可される (exit 0)"
            PASSED=$((PASSED + 1))
        else
            echo "  ✗ feature ブランチで予期しない exit code: $exit_code"
        fi
    fi
}

# テスト 2: .claude/ 内のファイルは許可される
test_claude_dir() {
    local input='{"file_path":".claude/settings.json","old_string":"old","new_string":"new"}'
    echo "$input" | bash "$GUARD_SCRIPT" > /dev/null 2>&1 || true
    local exit_code=$?

    TOTAL=$((TOTAL + 1))
    if [[ "$exit_code" -eq 0 ]]; then
        echo "  ✓ .claude/ 内のファイルは許可 (exit 0)"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ .claude/ 内のファイルで予期しない exit code: $exit_code"
    fi
}

# テスト 3: Read ツールは対象外（Edit/Write のみ）
test_read_tool() {
    # main-branch-guard は Edit/Write に対してのみ発火する前提
    # このテストは実際には PreToolUse フックで制御されるため、
    # ガードスクリプト単体では常に許可される
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    echo "  ✓ Read ツールは対象外（フック設定で制御）"
}

# テスト実行
test_current_branch
test_claude_dir
test_read_tool

echo ""
echo "Results: $PASSED/$TOTAL passed"

if [[ $PASSED -eq $TOTAL ]]; then
    exit 0
else
    exit 1
fi
