#!/bin/bash
# reward-fraud-test.sh - Test reward fraud prevention guards

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
GUARD_DIR="${REPO_ROOT}/.claude/skills/reward-guard/guards"

PASS_COUNT=0
FAIL_COUNT=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_guard() {
    local name="$1"
    local result="$2"
    if [ "$result" = "PASS" ]; then
        echo -e "TEST $name: ${GREEN}PASS${NC}"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        echo -e "TEST $name: ${RED}FAIL${NC}"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
}

echo "=== Reward Fraud Prevention Test ==="
echo ""

# Test 1: critic-guard.sh
echo "--- Testing critic-guard.sh ---"
[ -f "${GUARD_DIR}/critic-guard.sh" ] && test_guard "critic-guard.sh exists" "PASS" || test_guard "critic-guard.sh exists" "FAIL"
grep -q 'self_complete' "${GUARD_DIR}/critic-guard.sh" 2>/dev/null && grep -q 'exit 2' "${GUARD_DIR}/critic-guard.sh" 2>/dev/null && test_guard "critic-guard has BLOCK logic" "PASS" || test_guard "critic-guard has BLOCK logic" "FAIL"
echo ""

# Test 2: subtask-guard.sh
echo "--- Testing subtask-guard.sh ---"
[ -f "${GUARD_DIR}/subtask-guard.sh" ] && test_guard "subtask-guard.sh exists" "PASS" || test_guard "subtask-guard.sh exists" "FAIL"
grep -q 'validated_by' "${GUARD_DIR}/subtask-guard.sh" 2>/dev/null && grep -q 'critic' "${GUARD_DIR}/subtask-guard.sh" 2>/dev/null && test_guard "subtask-guard requires validated_by" "PASS" || test_guard "subtask-guard requires validated_by" "FAIL"
echo ""

# Test 3: phase-status-guard.sh
echo "--- Testing phase-status-guard.sh ---"
[ -f "${GUARD_DIR}/phase-status-guard.sh" ] && test_guard "phase-status-guard.sh exists" "PASS" || test_guard "phase-status-guard.sh exists" "FAIL"
grep -q 'subtask' "${GUARD_DIR}/phase-status-guard.sh" 2>/dev/null && grep -q 'exit 2' "${GUARD_DIR}/phase-status-guard.sh" 2>/dev/null && test_guard "phase-status-guard checks dependencies" "PASS" || test_guard "phase-status-guard checks dependencies" "FAIL"
echo ""

# Test 4: scope-guard.sh
echo "--- Testing scope-guard.sh ---"
[ -f "${GUARD_DIR}/scope-guard.sh" ] && test_guard "scope-guard.sh exists" "PASS" || test_guard "scope-guard.sh exists" "FAIL"
grep -qE 'done_when|done_criteria' "${GUARD_DIR}/scope-guard.sh" 2>/dev/null && test_guard "scope-guard checks file scope" "PASS" || test_guard "scope-guard checks file scope" "FAIL"
echo ""

# Test 5: completion-check.sh
echo "--- Testing completion-check.sh ---"
[ -f "${GUARD_DIR}/completion-check.sh" ] && test_guard "completion-check.sh exists" "PASS" || test_guard "completion-check.sh exists" "FAIL"
grep -q 'subtask' "${GUARD_DIR}/completion-check.sh" 2>/dev/null && grep -q 'exit 1' "${GUARD_DIR}/completion-check.sh" 2>/dev/null && test_guard "completion-check verifies done_criteria" "PASS" || test_guard "completion-check verifies done_criteria" "FAIL"
echo ""

# Test 6: progress-reminder.sh
echo "--- Testing progress-reminder.sh ---"
[ -f "${GUARD_DIR}/progress-reminder.sh" ] && test_guard "progress-reminder.sh exists" "PASS" || test_guard "progress-reminder.sh exists" "FAIL"
grep -q 'systemMessage' "${GUARD_DIR}/progress-reminder.sh" 2>/dev/null && test_guard "progress-reminder outputs reminders" "PASS" || test_guard "progress-reminder outputs reminders" "FAIL"
echo ""

# Test 7: coherence.sh
echo "--- Testing coherence.sh ---"
[ -f "${GUARD_DIR}/coherence.sh" ] && test_guard "coherence.sh exists" "PASS" || test_guard "coherence.sh exists" "FAIL"
grep -q 'state.md' "${GUARD_DIR}/coherence.sh" 2>/dev/null && grep -q 'Coherence' "${GUARD_DIR}/coherence.sh" 2>/dev/null && test_guard "coherence checks state consistency" "PASS" || test_guard "coherence checks state consistency" "FAIL"
echo ""

echo "=== Summary ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All tests passed - Reward Fraud Prevention is active${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed - Reward Fraud Prevention may be compromised${NC}"
    exit $FAIL_COUNT
fi
