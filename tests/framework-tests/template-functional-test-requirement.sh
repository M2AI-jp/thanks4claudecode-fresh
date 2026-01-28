#!/bin/bash
# Test: play/template/plan.json の requires_functional_test が正しく設定されているか

set -e
cd "$(dirname "$0")/../.."

echo "=== Template Functional Test Requirement Test ==="

TARGET_FILE="play/template/plan.json"

# Test 1: requires_functional_test が true か
echo "Test 1: requires_functional_test value..."
value=$(jq -r '.meta.requires_functional_test' "$TARGET_FILE")
if [ "$value" = "true" ]; then
    echo "  [PASS] requires_functional_test is true"
else
    echo "  [FAIL] requires_functional_test is '$value' (expected: true)"
    exit 1
fi

# Test 2: functional_test_requirement セクションが存在するか
echo "Test 2: functional_test_requirement section..."
if jq -e '._template_rules.functional_test_requirement' "$TARGET_FILE" > /dev/null 2>&1; then
    echo "  [PASS] functional_test_requirement section exists"
else
    echo "  [FAIL] functional_test_requirement section not found"
    exit 1
fi

# Test 3: MUST フィールドが存在するか
echo "Test 3: MUST field in functional_test_requirement..."
must_value=$(jq -r '._template_rules.functional_test_requirement.MUST' "$TARGET_FILE")
if [ -n "$must_value" ] && [ "$must_value" != "null" ]; then
    echo "  [PASS] MUST field exists"
else
    echo "  [FAIL] MUST field not found"
    exit 1
fi

# Test 4: PROHIBITED_VERIFICATION に test -f が含まれているか
echo "Test 4: PROHIBITED_VERIFICATION includes test -f..."
if jq -r '._template_rules.functional_test_requirement.PROHIBITED_VERIFICATION[]' "$TARGET_FILE" 2>/dev/null | grep -q "test -f"; then
    echo "  [PASS] test -f is in PROHIBITED_VERIFICATION"
else
    echo "  [FAIL] test -f is NOT in PROHIBITED_VERIFICATION"
    exit 1
fi

# Test 5: REQUIRED_VERIFICATION が存在するか
echo "Test 5: REQUIRED_VERIFICATION field..."
req_value=$(jq -r '._template_rules.functional_test_requirement.REQUIRED_VERIFICATION' "$TARGET_FILE")
if [ -n "$req_value" ] && [ "$req_value" != "null" ]; then
    echo "  [PASS] REQUIRED_VERIFICATION field exists"
else
    echo "  [FAIL] REQUIRED_VERIFICATION field not found"
    exit 1
fi

echo ""
echo "=== Template validation passed ==="
exit 0
