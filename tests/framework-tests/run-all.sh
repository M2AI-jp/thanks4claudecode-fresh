#!/bin/bash
# Run all framework tests

cd "$(dirname "$0")"

echo "========================================"
echo "  Framework Tests Runner"
echo "========================================"
echo ""

passed=0
failed=0
total=3

# Test 1: critic-proxy-detection-test.sh
echo "[1/3] Running critic-proxy-detection-test.sh..."
echo "----------------------------------------"
if bash ./critic-proxy-detection-test.sh; then
    ((passed++))
    echo ""
else
    ((failed++))
    echo ""
fi

# Test 2: immutable-rules-test.sh
echo "[2/3] Running immutable-rules-test.sh..."
echo "----------------------------------------"
if bash ./immutable-rules-test.sh; then
    ((passed++))
    echo ""
else
    ((failed++))
    echo ""
fi

# Test 3: template-functional-test-requirement.sh
echo "[3/3] Running template-functional-test-requirement.sh..."
echo "----------------------------------------"
if bash ./template-functional-test-requirement.sh; then
    ((passed++))
    echo ""
else
    ((failed++))
    echo ""
fi

echo "========================================"
echo "  Results: $passed/$total tests passed"
echo "========================================"

if [ $failed -gt 0 ]; then
    echo "FAILED: $failed tests failed"
    exit 1
fi

echo ""
echo "3/3 tests passed"
echo "SUCCESS: All tests passed"
exit 0
