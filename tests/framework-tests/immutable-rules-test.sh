#!/bin/bash
# Test: done-criteria-validation.md の IMMUTABLE_RULES が正しく定義されているか

set -e
cd "$(dirname "$0")/../.."

echo "=== Immutable Rules Test ==="

TARGET_FILE=".claude/frameworks/done-criteria-validation.md"

# Test 1: IMMUTABLE_RULES セクションが存在するか
echo "Test 1: IMMUTABLE_RULES section existence..."
if grep -q "IMMUTABLE_RULES" "$TARGET_FILE"; then
    echo "  [PASS] IMMUTABLE_RULES section found"
else
    echo "  [FAIL] IMMUTABLE_RULES section not found"
    exit 1
fi

# Test 2: 違反時は自動 FAIL が明記されているか
echo "Test 2: Auto FAIL statement..."
if grep -q "違反時は自動 FAIL" "$TARGET_FILE"; then
    echo "  [PASS] Auto FAIL statement found"
else
    echo "  [FAIL] Auto FAIL statement not found"
    exit 1
fi

# Test 3: 6つの固定ルールが定義されているか
echo "Test 3: Six immutable rules defined..."
rule_count=$(grep -cE '^[[:space:]]*-[[:space:]]+IR[0-9]+:' "$TARGET_FILE" || echo "0")
if [ "$rule_count" -ge 6 ]; then
    echo "  [PASS] $rule_count rules defined (>= 6)"
else
    echo "  [FAIL] Only $rule_count rules defined (need >= 6)"
    exit 1
fi

# Test 4: PROXY_VERIFICATION_PROHIBITION が含まれているか
echo "Test 4: PROXY_VERIFICATION_PROHIBITION rule..."
if grep -q "PROXY_VERIFICATION_PROHIBITION" "$TARGET_FILE"; then
    echo "  [PASS] PROXY_VERIFICATION_PROHIBITION rule found"
else
    echo "  [FAIL] PROXY_VERIFICATION_PROHIBITION rule not found"
    exit 1
fi

# Test 5: 禁止コマンドリストが含まれているか
echo "Test 5: Blocked commands in PROXY_VERIFICATION_PROHIBITION..."
if grep -q "test -f" "$TARGET_FILE"; then
    echo "  [PASS] Blocked commands list found"
else
    echo "  [FAIL] Blocked commands list not found"
    exit 1
fi

# Test 6: 違反検出パターンが定義されているか
echo "Test 6: Violation detection patterns..."
if grep -q "違反検出パターン" "$TARGET_FILE"; then
    echo "  [PASS] Violation detection patterns defined"
else
    echo "  [FAIL] Violation detection patterns not defined"
    exit 1
fi

echo ""
echo "=== All immutable rules tests passed ==="
exit 0
