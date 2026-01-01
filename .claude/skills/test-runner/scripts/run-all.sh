#!/usr/bin/env bash
# ==============================================================================
# .claude/skills/test-runner/scripts/run-all.sh - 全テスト実行
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Test Runner - Full Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

FAILED=0

# 1. Unit テスト（ガードスクリプト）
echo -e "${YELLOW}[1/4] Running guard tests...${NC}"
if bash "$SCRIPT_DIR/run-unit.sh"; then
    echo -e "${GREEN}Guard tests: PASS${NC}"
else
    echo -e "${RED}Guard tests: FAIL${NC}"
    FAILED=1
fi
echo ""

# 2. Critic テスト
echo -e "${YELLOW}[2/4] Running critic tests...${NC}"
if bash "$SCRIPT_DIR/run-critic.sh"; then
    echo -e "${GREEN}Critic tests: PASS${NC}"
else
    echo -e "${RED}Critic tests: FAIL${NC}"
    FAILED=1
fi
echo ""

# 3. Type チェック（シェルスクリプト構文）
echo -e "${YELLOW}[3/4] Running typecheck (syntax)...${NC}"
if bash "$SCRIPT_DIR/run-typecheck.sh"; then
    echo -e "${GREEN}Typecheck: PASS${NC}"
else
    echo -e "${RED}Typecheck: FAIL${NC}"
    FAILED=1
fi
echo ""

# 4. E2E テスト
echo -e "${YELLOW}[4/4] Running E2E tests...${NC}"
if bash "$SCRIPT_DIR/run-e2e.sh"; then
    echo -e "${GREEN}E2E tests: PASS${NC}"
else
    echo -e "${RED}E2E tests: FAIL${NC}"
    FAILED=1
fi
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}  All tests passed!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}  Some tests failed${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
