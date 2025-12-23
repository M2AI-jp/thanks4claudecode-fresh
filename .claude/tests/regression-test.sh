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

# Agents 存在チェック
for f in .claude/agents/*.md; do
    if [ -f "$f" ]; then
        pass "$(basename $f): exists"
    else
        fail "$(basename $f): missing"
    fi
done

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
