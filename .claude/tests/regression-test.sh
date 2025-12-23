#!/bin/bash
# regression-test.sh - 回帰テストスクリプト（簡易版）

set -e

PASS=0
FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== Regression Test ==="

# Hooks 構文チェック
for f in .claude/hooks/*.sh; do
    if bash -n "$f" 2>/dev/null; then
        pass "$(basename $f): syntax OK"
    else
        fail "$(basename $f): syntax error"
    fi
done

# Agents 存在チェック（4QV+: .claude/skills/*/agents/ に移動）
AGENT_COUNT=$(find .claude/skills -path '*/agents/*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$AGENT_COUNT" -ge 6 ]; then
    pass "agents: $AGENT_COUNT found in Skills"
else
    fail "agents: expected >= 6, found $AGENT_COUNT"
fi

# Frameworks 存在チェック
if [ -f ".claude/frameworks/done-criteria-validation.md" ]; then
    pass "done-criteria-validation.md: exists"
else
    fail "done-criteria-validation.md: missing"
fi

# 結果
echo ""
echo "=== Results: PASS=$PASS, FAIL=$FAIL ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
