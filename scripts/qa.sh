#!/bin/bash
#
# scripts/qa.sh - 品質チェック統合コマンド
#
# 全ての品質チェック（テスト・静的解析・セキュリティ）を一括実行する。
# skip はツール未インストールを示し、FAIL 扱いとする（品質ゲート厳格化）。
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PROJECT_ROOT/evidence"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
LOG_FILE="$EVIDENCE_DIR/qa-results-$TIMESTAMP.log"

# 証跡ディレクトリ作成
mkdir -p "$EVIDENCE_DIR"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 結果追跡
PASSED=0
FAILED=0
SKIPPED=0

# ログ記録関数
log_to_file() {
    echo "$1" >> "$LOG_FILE"
}

log_pass() {
    echo -e "${GREEN}✓${NC} $1"
    log_to_file "[PASS] $1"
    PASSED=$((PASSED + 1))
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    log_to_file "[FAIL] $1"
    FAILED=$((FAILED + 1))
}

log_skip() {
    # skip は FAIL 扱い（ツール未インストールは品質ゲート失敗）
    echo -e "${YELLOW}○${NC} $1 (skipped - counted as FAIL)"
    log_to_file "[SKIP/FAIL] $1"
    SKIPPED=$((SKIPPED + 1))
    FAILED=$((FAILED + 1))
}

echo "=== Quality Assurance Checks ==="
echo ""

# 1. bats テスト
echo "[1/5] Integration Tests (bats)"
if command -v bats &> /dev/null; then
    if bats "$PROJECT_ROOT/tests/tmp-run.bats"; then
        log_pass "bats tests"
    else
        log_fail "bats tests"
    fi
else
    log_skip "bats not installed"
fi

echo ""

# 2. shellcheck
echo "[2/5] Shell Analysis (shellcheck)"
if command -v shellcheck &> /dev/null; then
    if shellcheck "$PROJECT_ROOT/tmp/run.sh"; then
        log_pass "shellcheck tmp/run.sh"
    else
        log_fail "shellcheck tmp/run.sh"
    fi
else
    log_skip "shellcheck not installed"
fi

echo ""

# 3. ruff
echo "[3/5] Python Analysis (ruff)"
if command -v ruff &> /dev/null; then
    if ruff check "$PROJECT_ROOT/tmp/process.py"; then
        log_pass "ruff tmp/process.py"
    else
        log_fail "ruff tmp/process.py"
    fi
else
    log_skip "ruff not installed"
fi

echo ""

# 4. eslint
echo "[4/5] TypeScript Analysis (eslint)"
if npx eslint --version &> /dev/null; then
    if npx eslint "$PROJECT_ROOT/tmp/transform.ts" 2>/dev/null; then
        log_pass "eslint tmp/transform.ts"
    else
        log_fail "eslint tmp/transform.ts"
    fi
else
    log_skip "eslint not available"
fi

echo ""

# 5. npm audit
echo "[5/5] Security Audit (npm audit)"
cd "$PROJECT_ROOT"
if npm audit --audit-level=high 2>/dev/null; then
    log_pass "npm audit"
else
    log_fail "npm audit"
fi

echo ""
echo "=== Summary ==="
echo -e "${GREEN}Passed${NC}: $PASSED"
echo -e "${RED}Failed${NC}: $FAILED"
echo -e "${YELLOW}Skipped${NC}: $SKIPPED (counted as FAIL)"

# ログファイルにサマリーを記録
log_to_file ""
log_to_file "=== Summary ==="
log_to_file "Passed: $PASSED"
log_to_file "Failed: $FAILED"
log_to_file "Skipped: $SKIPPED (counted as FAIL)"
log_to_file "Timestamp: $TIMESTAMP"

echo ""
echo "Evidence log: $LOG_FILE"

if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo -e "${RED}QA FAILED${NC}"
    log_to_file "Result: QA FAILED"
    exit 1
else
    echo ""
    echo -e "${GREEN}QA PASSED${NC}"
    log_to_file "Result: QA PASSED"
    exit 0
fi
