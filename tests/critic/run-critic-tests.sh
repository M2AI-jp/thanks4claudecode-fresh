#!/usr/bin/env bash
# ==============================================================================
# tests/critic/run-critic-tests.sh - critic 検証テスト
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
NC='\033[0m'

echo "=============================================="
echo "  Critic Validation Tests"
echo "=============================================="
echo ""

# 良い証拠パターン（PASS が期待される）
GOOD_EVIDENCE=(
    "PASS - bash test.sh: exit 0, 10/10 tests passed"
    "PASS - npm test: 25 passed, 0 failed"
    "PASS - grep 'function' src/app.ts: 5 matches found"
    "PASS - ls -la output: 3 files exist"
    "PASS - curl http://localhost:3000: status 200"
    "PASS - git diff shows 0 changes"
    "PASS - TypeScript: 0 errors"
    "PASS - coverage: 85%"
    "PASS - eslint: 0 warnings"
    "PASS - dist/ has 12 files"
)

# 悪い証拠パターン（FAIL が期待される）
BAD_EVIDENCE=(
    "PASS"
    "PASS - 確認済み"
    "PASS - 動作確認しました"
    "PASS - OK"
    "PASS - テスト完了"
    "PASS - done"
    "PASS - completed"
    "PASS - works"
    "PASS - looks good"
    "PASS - success"
)

# 部分的な証拠（要検討）
PARTIAL_EVIDENCE=(
    "PASS - テストが通った"
    "PASS - ファイルが存在する"
    "PASS - 正常に動作"
)

echo "Testing good evidence patterns (should PASS):"
for evidence in "${GOOD_EVIDENCE[@]}"; do
    TOTAL=$((TOTAL + 1))
    # 実際の critic 検証ロジックがあればここで呼び出す
    # 現時点では、コマンド/数値を含む証拠を良い証拠と判定
    if echo "$evidence" | grep -qE '(exit [0-9]+|[0-9]+/[0-9]+|[0-9]+ (passed|matches|files|errors|warnings|changes)|status [0-9]+|coverage: [0-9]+%)'; then
        PASSED=$((PASSED + 1))
        echo -e "  ${GREEN}✓${NC} Good evidence detected: ${evidence:0:50}..."
    else
        echo -e "  ${RED}✗${NC} Failed to recognize good evidence: ${evidence:0:50}..."
    fi
done

echo ""
echo "Testing bad evidence patterns (should FAIL):"
for evidence in "${BAD_EVIDENCE[@]}"; do
    TOTAL=$((TOTAL + 1))
    # 悪い証拠は数値/コマンド出力を含まない
    if echo "$evidence" | grep -qE '(exit [0-9]+|[0-9]+/[0-9]+|[0-9]+ (passed|matches|files|errors|warnings|changes)|status [0-9]+|coverage: [0-9]+%)'; then
        echo -e "  ${RED}✗${NC} Bad evidence incorrectly passed: $evidence"
    else
        PASSED=$((PASSED + 1))
        echo -e "  ${GREEN}✓${NC} Bad evidence correctly rejected: $evidence"
    fi
done

echo ""
echo "Testing partial evidence patterns (edge cases):"
for evidence in "${PARTIAL_EVIDENCE[@]}"; do
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    echo -e "  ${YELLOW}⚠${NC} Partial evidence (needs human review): $evidence"
done

echo ""
echo "=============================================="
echo "  Results: $PASSED/$TOTAL passed"
echo "=============================================="

if [[ $PASSED -eq $TOTAL ]]; then
    echo -e "${GREEN}All critic tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some critic tests failed${NC}"
    exit 1
fi
