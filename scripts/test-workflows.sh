#!/bin/bash
# ==============================================================================
# test-workflows.sh - ワークフロー統合テスト
# ==============================================================================
#
# 目的: 全てのワークフロー関連テストを実行
#
# 含まれるテスト:
#   1. test-workflow-simple.sh - 基本的なHook動作テスト (5テスト)
#   2. test-workflow-state-transition.sh - 状態遷移テスト (10テスト)
#
# 使用方法:
#   bash scripts/test-workflows.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# カラー
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=()

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ワークフロー統合テスト"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# テストスイート 1: test-workflow-simple.sh
# ==============================================================================
echo -e "${BLUE}▶ Running: test-workflow-simple.sh${NC}"
echo ""

if bash "$SCRIPT_DIR/test-workflow-simple.sh"; then
    echo -e "${GREEN}✓ test-workflow-simple.sh PASSED${NC}"
else
    echo -e "${RED}✗ test-workflow-simple.sh FAILED${NC}"
    FAILED_SUITES+=("test-workflow-simple.sh")
fi
echo ""

# ==============================================================================
# テストスイート 2: test-workflow-state-transition.sh
# ==============================================================================
echo -e "${BLUE}▶ Running: test-workflow-state-transition.sh${NC}"
echo ""

if bash "$SCRIPT_DIR/test-workflow-state-transition.sh"; then
    echo -e "${GREEN}✓ test-workflow-state-transition.sh PASSED${NC}"
else
    echo -e "${RED}✗ test-workflow-state-transition.sh FAILED${NC}"
    FAILED_SUITES+=("test-workflow-state-transition.sh")
fi
echo ""

# ==============================================================================
# サマリー
# ==============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  統合テスト結果"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ${#FAILED_SUITES[@]} -eq 0 ]; then
    echo -e "  ${GREEN}ALL TEST SUITES PASSED${NC}"
    echo ""
    echo "  テストスイート:"
    echo "    ✓ test-workflow-simple.sh"
    echo "    ✓ test-workflow-state-transition.sh"
    echo ""
    exit 0
else
    echo -e "  ${RED}SOME TEST SUITES FAILED${NC}"
    echo ""
    echo "  失敗したテストスイート:"
    for suite in "${FAILED_SUITES[@]}"; do
        echo "    ✗ $suite"
    done
    echo ""
    exit 1
fi
