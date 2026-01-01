#!/usr/bin/env bash
# ==============================================================================
# tests/guards/run-all.sh - ガードスクリプト全テスト実行
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0

run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)

    TOTAL=$((TOTAL + 1))
    echo -n "  Testing $test_name... "

    if bash "$test_file" > /tmp/test-output-$$.txt 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Output:"
        sed 's/^/    /' /tmp/test-output-$$.txt | head -20
        FAILED=$((FAILED + 1))
    fi
    rm -f /tmp/test-output-$$.txt
}

echo "=============================================="
echo "  Guard Script Tests"
echo "=============================================="
echo ""

# 全テストファイルを実行
for test_file in "$SCRIPT_DIR"/test-*.sh; do
    if [[ -f "$test_file" ]]; then
        run_test "$test_file"
    fi
done

echo ""
echo "=============================================="
echo "  Results: $PASSED/$TOTAL passed"
echo "=============================================="

if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}FAIL: $FAILED tests failed${NC}"
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"
exit 0
