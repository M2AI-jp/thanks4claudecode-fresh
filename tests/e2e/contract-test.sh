#!/usr/bin/env bash
# ==============================================================================
# tests/e2e/contract-test.sh - E2E コントラクトテスト
# ==============================================================================
#
# 目的: INIT → LOOP → CRITIQUE → POST_LOOP の主要フローをテスト
#
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

TOTAL=0
PASSED=0

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

assert_file_exists() {
    local name="$1"
    local file="$2"
    TOTAL=$((TOTAL + 1))
    if [[ -f "$file" ]]; then
        PASSED=$((PASSED + 1))
        echo -e "  ${GREEN}✓${NC} $name"
    else
        echo -e "  ${RED}✗${NC} $name (file not found: $file)"
    fi
}

assert_contains() {
    local name="$1"
    local file="$2"
    local pattern="$3"
    TOTAL=$((TOTAL + 1))
    if grep -q "$pattern" "$file" 2>/dev/null; then
        PASSED=$((PASSED + 1))
        echo -e "  ${GREEN}✓${NC} $name"
    else
        echo -e "  ${RED}✗${NC} $name (pattern not found: $pattern)"
    fi
}

assert_script_syntax() {
    local name="$1"
    local script="$2"
    TOTAL=$((TOTAL + 1))
    if bash -n "$script" 2>/dev/null; then
        PASSED=$((PASSED + 1))
        echo -e "  ${GREEN}✓${NC} $name"
    else
        echo -e "  ${RED}✗${NC} $name (syntax error)"
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  E2E Contract Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ==============================================================================
# Test 1: INIT フロー
# ==============================================================================
echo -e "${YELLOW}[1/4] Testing INIT flow...${NC}"
assert_file_exists "state.md exists" "$ROOT_DIR/state.md"
assert_file_exists "CLAUDE.md exists" "$ROOT_DIR/CLAUDE.md"
assert_file_exists "settings.json exists" "$ROOT_DIR/.claude/settings.json"
assert_contains "state.md has playbook section" "$ROOT_DIR/state.md" "playbook"
assert_script_syntax "session.sh syntax OK" "$ROOT_DIR/.claude/hooks/session.sh"

echo ""

# ==============================================================================
# Test 2: LOOP フロー（playbook-gate）
# ==============================================================================
echo -e "${YELLOW}[2/4] Testing LOOP flow (playbook gate)...${NC}"
assert_file_exists "playbook-guard.sh exists" "$ROOT_DIR/.claude/skills/playbook-gate/guards/playbook-guard.sh"
assert_script_syntax "playbook-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/playbook-gate/guards/playbook-guard.sh"
assert_file_exists "pre-tool.sh exists" "$ROOT_DIR/.claude/hooks/pre-tool.sh"
assert_script_syntax "pre-tool.sh syntax OK" "$ROOT_DIR/.claude/hooks/pre-tool.sh"

echo ""

# ==============================================================================
# Test 3: CRITIQUE フロー
# ==============================================================================
echo -e "${YELLOW}[3/4] Testing CRITIQUE flow...${NC}"
assert_file_exists "critic-guard.sh exists" "$ROOT_DIR/.claude/skills/reward-guard/guards/critic-guard.sh"
assert_script_syntax "critic-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/reward-guard/guards/critic-guard.sh"
assert_file_exists "critic.md exists" "$ROOT_DIR/.claude/skills/reward-guard/agents/critic.md"
assert_contains "critic.md has PASS/FAIL rule" "$ROOT_DIR/.claude/skills/reward-guard/agents/critic.md" "PASS\|FAIL"

echo ""

# ==============================================================================
# Test 4: POST_LOOP フロー
# ==============================================================================
echo -e "${YELLOW}[4/4] Testing POST_LOOP flow...${NC}"
assert_file_exists "post-loop SKILL.md exists" "$ROOT_DIR/.claude/skills/post-loop/SKILL.md"
assert_file_exists "post-tool.sh exists" "$ROOT_DIR/.claude/hooks/post-tool.sh"
assert_script_syntax "post-tool.sh syntax OK" "$ROOT_DIR/.claude/hooks/post-tool.sh"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Results: $PASSED/$TOTAL passed"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $PASSED -eq $TOTAL ]]; then
    echo -e "${GREEN}All E2E contract tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some E2E tests failed${NC}"
    exit 1
fi
