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
assert_file_exists "settings.local.json exists" "$ROOT_DIR/.claude/settings.local.json"
assert_file_exists "mcp.json exists" "$ROOT_DIR/.claude/mcp.json"
assert_file_exists "protected-files.txt exists" "$ROOT_DIR/.claude/protected-files.txt"
assert_file_exists "state-schema.sh exists" "$ROOT_DIR/.claude/schema/state-schema.sh"
assert_script_syntax "state-schema.sh syntax OK" "$ROOT_DIR/.claude/schema/state-schema.sh"
assert_contains "state.md has playbook section" "$ROOT_DIR/state.md" "playbook"
assert_script_syntax "session.sh syntax OK" "$ROOT_DIR/.claude/hooks/session.sh"
assert_file_exists "prompt.sh exists" "$ROOT_DIR/.claude/hooks/prompt.sh"
assert_script_syntax "prompt.sh syntax OK" "$ROOT_DIR/.claude/hooks/prompt.sh"
assert_file_exists "subagent-stop.sh exists" "$ROOT_DIR/.claude/hooks/subagent-stop.sh"
assert_script_syntax "subagent-stop.sh syntax OK" "$ROOT_DIR/.claude/hooks/subagent-stop.sh"
assert_file_exists "generate-repository-map.sh exists" "$ROOT_DIR/.claude/hooks/generate-repository-map.sh"
assert_script_syntax "generate-repository-map.sh syntax OK" "$ROOT_DIR/.claude/hooks/generate-repository-map.sh"

echo ""

# ==============================================================================
# Test 2: LOOP フロー（playbook-gate）
# ==============================================================================
echo -e "${YELLOW}[2/4] Testing LOOP flow (playbook gate)...${NC}"
assert_file_exists "playbook-guard.sh exists" "$ROOT_DIR/.claude/skills/playbook-gate/guards/playbook-guard.sh"
assert_script_syntax "playbook-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/playbook-gate/guards/playbook-guard.sh"
assert_file_exists "executor-guard.sh exists" "$ROOT_DIR/.claude/skills/playbook-gate/guards/executor-guard.sh"
assert_script_syntax "executor-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/playbook-gate/guards/executor-guard.sh"
assert_file_exists "task-executor-guard.sh exists" "$ROOT_DIR/.claude/skills/playbook-gate/guards/task-executor-guard.sh"
assert_script_syntax "task-executor-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/playbook-gate/guards/task-executor-guard.sh"
assert_file_exists "bash-executor-guard.sh exists" "$ROOT_DIR/.claude/skills/playbook-gate/guards/bash-executor-guard.sh"
assert_script_syntax "bash-executor-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/playbook-gate/guards/bash-executor-guard.sh"
assert_file_exists "role-resolver.sh exists" "$ROOT_DIR/.claude/skills/playbook-gate/guards/role-resolver.sh"
assert_script_syntax "role-resolver.sh syntax OK" "$ROOT_DIR/.claude/skills/playbook-gate/guards/role-resolver.sh"
assert_file_exists "depends-check.sh exists" "$ROOT_DIR/.claude/skills/playbook-gate/guards/depends-check.sh"
assert_script_syntax "depends-check.sh syntax OK" "$ROOT_DIR/.claude/skills/playbook-gate/guards/depends-check.sh"
assert_file_exists "bash-check.sh exists" "$ROOT_DIR/.claude/skills/access-control/guards/bash-check.sh"
assert_script_syntax "bash-check.sh syntax OK" "$ROOT_DIR/.claude/skills/access-control/guards/bash-check.sh"
assert_file_exists "protected-edit.sh exists" "$ROOT_DIR/.claude/skills/access-control/guards/protected-edit.sh"
assert_script_syntax "protected-edit.sh syntax OK" "$ROOT_DIR/.claude/skills/access-control/guards/protected-edit.sh"
assert_file_exists "main-branch.sh exists" "$ROOT_DIR/.claude/skills/access-control/guards/main-branch.sh"
assert_script_syntax "main-branch.sh syntax OK" "$ROOT_DIR/.claude/skills/access-control/guards/main-branch.sh"
assert_file_exists "pre-tool.sh exists" "$ROOT_DIR/.claude/hooks/pre-tool.sh"
assert_script_syntax "pre-tool.sh syntax OK" "$ROOT_DIR/.claude/hooks/pre-tool.sh"

echo ""

# ==============================================================================
# Test 3: CRITIQUE フロー
# ==============================================================================
echo -e "${YELLOW}[3/4] Testing CRITIQUE flow...${NC}"
assert_file_exists "critic-guard.sh exists" "$ROOT_DIR/.claude/skills/reward-guard/guards/critic-guard.sh"
assert_script_syntax "critic-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/reward-guard/guards/critic-guard.sh"
assert_file_exists "scope-guard.sh exists" "$ROOT_DIR/.claude/skills/reward-guard/guards/scope-guard.sh"
assert_script_syntax "scope-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/reward-guard/guards/scope-guard.sh"
assert_file_exists "subtask-guard.sh exists" "$ROOT_DIR/.claude/skills/reward-guard/guards/subtask-guard.sh"
assert_script_syntax "subtask-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/reward-guard/guards/subtask-guard.sh"
assert_file_exists "critic.md exists" "$ROOT_DIR/.claude/skills/reward-guard/agents/critic.md"
assert_contains "critic.md has PASS/FAIL rule" "$ROOT_DIR/.claude/skills/reward-guard/agents/critic.md" "PASS\|FAIL"

echo ""

# ==============================================================================
# Test 4: POST_LOOP フロー
# ==============================================================================
echo -e "${YELLOW}[4/4] Testing POST_LOOP flow...${NC}"
assert_file_exists "post-loop SKILL.md exists" "$ROOT_DIR/.claude/skills/post-loop/SKILL.md"
assert_file_exists "pending-guard.sh exists" "$ROOT_DIR/.claude/skills/post-loop/guards/pending-guard.sh"
assert_script_syntax "pending-guard.sh syntax OK" "$ROOT_DIR/.claude/skills/post-loop/guards/pending-guard.sh"
assert_file_exists "complete.sh exists" "$ROOT_DIR/.claude/skills/post-loop/handlers/complete.sh"
assert_script_syntax "complete.sh syntax OK" "$ROOT_DIR/.claude/skills/post-loop/handlers/complete.sh"
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
