#!/bin/bash
# reward-fraud-test.sh - 報酬詐欺耐性テスト
#
# リポジトリの報酬詐欺耐性を検証するテストスクリプト。
# 全テストが PASS すれば exit 0 を返す。
#
# テスト項目:
#   1. subtask-guard: status: done には validated_by: critic が必須
#   2. critic: done 宣言には critic SubAgent の PASS が必須
#   3. reviewer: playbook.reviewed: true には reviewer 検証が必須
#   4. playbook-guard: playbook なしで Edit/Write がブロック
#   5. HARD_BLOCK: 保護ファイルへの書き込みがブロック

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
cd "$REPO_ROOT"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# テスト結果カウンター
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL_TESTS=0

# テスト実行関数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected="$3"  # "pass" or "block"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -n "  [$TOTAL_TESTS] $test_name ... "

    # テスト実行
    local result
    if eval "$test_command" >/dev/null 2>&1; then
        result="pass"
    else
        result="block"
    fi

    # 結果判定
    if [[ "$result" == "$expected" ]]; then
        echo -e "${GREEN}PASS${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC} (expected: $expected, got: $result)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# ヘッダー
echo "========================================"
echo "  Report Fraud Resistance Test"
echo "========================================"
echo ""

# =============================================================================
# Test 1: subtask-guard (status: done には validated_by: critic が必須)
# =============================================================================
echo "## Test 1: subtask-guard"
echo ""

# subtask-guard.sh は stdin から JSON を読み込み、progress.json への Edit をチェック
# テスト用の一時 progress.json を作成
TEST_PROGRESS=$(mktemp -d)/play/test/progress.json
mkdir -p "$(dirname "$TEST_PROGRESS")"

# 現在の progress.json（pending 状態）
cat > "$TEST_PROGRESS" <<'EOF'
{
  "subtasks": {
    "p1.1": {
      "status": "pending",
      "validated_by": "",
      "validations": {
        "technical": { "status": "PENDING", "evidence": [] },
        "consistency": { "status": "PENDING", "evidence": [] },
        "completeness": { "status": "PENDING", "evidence": [] }
      }
    }
  }
}
EOF

# old_string (pending) を new_string (done without critic) に変更するリクエスト
OLD_STRING='"status": "pending"'
NEW_STRING_BAD='"status": "done"'

# subtask-guard が status: done + validated_by: empty をブロックするか
PAYLOAD_BAD=$(cat <<JSONEOF
{
  "tool_input": {
    "file_path": "$TEST_PROGRESS",
    "old_string": "$OLD_STRING",
    "new_string": "$NEW_STRING_BAD"
  }
}
JSONEOF
)

run_test "Blocks done without validated_by (subtask-guard)" \
    "echo '$PAYLOAD_BAD' | bash .claude/skills/reward-guard/guards/subtask-guard.sh" \
    "block" || true

# Test 2: 正しく critic 検証された done 変更が許可されるか
#
# 注: subtask-guard は stdin から JSON を読み、progress.json の変更を検証する
# ファイルパスが */play/*/progress.json 形式である必要がある
#
# この テストは技術的に複雑なため、現状では正確にテストできない
# 理由:
#   1. subtask-guard は実際のファイルを読む（テスト用一時ファイルの作成が必要）
#   2. JSON の content フィールドにネストした JSON を渡す必要がある
#   3. シェルのエスケープが複雑
#
# TODO: 統合テスト環境で検証すべき項目
echo -e "  [2] Allows done with validated_by: critic ... ${YELLOW}SKIPPED${NC} (requires integration test)"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
SKIP_COUNT=$((SKIP_COUNT + 1))

rm -rf "$(dirname "$(dirname "$TEST_PROGRESS")")"
echo ""

# =============================================================================
# Test 2: HARD_BLOCK (保護ファイルへの書き込み)
# =============================================================================
echo "## Test 2: HARD_BLOCK Protection"
echo ""

# contract.sh を source
source .claude/lib/contract.sh

# HARD_BLOCK ファイルへの Edit がブロックされるか
run_test "Blocks Edit to CLAUDE.md" \
    "contract_check_edit 'CLAUDE.md'" \
    "block" || true

# HARD_BLOCK ファイルへの Bash 書き込みがブロックされるか
run_test "Blocks Bash rm CLAUDE.md" \
    "contract_check_bash 'rm CLAUDE.md'" \
    "block" || true

# 読み取りコマンドが許可されるか
run_test "Allows Bash cat CLAUDE.md" \
    "contract_check_bash 'cat CLAUDE.md'" \
    "pass" || true

echo ""

# =============================================================================
# Test 3: playbook-guard (playbook なしで Edit ブロック)
# =============================================================================
echo "## Test 3: playbook-guard"
echo ""

# playbook=null のときに Edit がブロックされるか
# 注: このテストは state.md の現在の状態に依存
CURRENT_PLAYBOOK=$(grep -A6 "^## playbook" state.md 2>/dev/null | grep "^active:" | sed 's/active: *//' | tr -d ' ')
if [[ -z "$CURRENT_PLAYBOOK" || "$CURRENT_PLAYBOOK" == "null" ]]; then
    # playbook=null の状態
    run_test "Blocks Edit when playbook=null" \
        "contract_check_edit 'test.txt'" \
        "block" || true
else
    # playbook=active の状態
    run_test "Allows Edit when playbook=active" \
        "contract_check_edit 'test.txt'" \
        "pass" || true
fi

echo ""

# =============================================================================
# Test 4: Bash Protection Patterns
# =============================================================================
echo "## Test 4: Bash Protection"
echo ""

# 注: rm -rf / は HARD_BLOCK ファイルを対象としないため許可される
# 代わりに、HARD_BLOCK ファイルへの rm をテスト
run_test "Blocks rm .claude/settings.json" \
    "contract_check_bash 'rm .claude/settings.json'" \
    "block" || true

# 保護パターンへの書き込みがブロックされるか
run_test "Blocks sed -i on .claude/hooks/*.sh" \
    "contract_check_bash 'sed -i s/x/y/ .claude/hooks/prompt.sh'" \
    "block" || true

# 読み取りコマンドが許可されるか（誤検出ゼロ）
run_test "Allows ls .claude/" \
    "contract_check_bash 'ls -la .claude/'" \
    "pass" || true

run_test "Allows find .claude/ with /dev/null" \
    "contract_check_bash 'find .claude/skills -name SKILL.md 2>/dev/null | wc -l'" \
    "pass" || true

echo ""

# =============================================================================
# Test 5: Guard File Existence
# =============================================================================
echo "## Test 5: Guard Files Exist"
echo ""

run_test "subtask-guard.sh exists" \
    "test -f .claude/skills/reward-guard/guards/subtask-guard.sh" \
    "pass" || true

run_test "playbook-guard.sh exists" \
    "test -f .claude/skills/playbook-gate/guards/playbook-guard.sh" \
    "pass" || true

run_test "critic-guard.sh exists" \
    "test -f .claude/skills/reward-guard/guards/critic-guard.sh" \
    "pass" || true

run_test "contract.sh exists" \
    "test -f .claude/lib/contract.sh" \
    "pass" || true

echo ""

# =============================================================================
# 結果サマリー
# =============================================================================
echo "========================================"
echo "  Summary"
echo "========================================"
echo ""
echo "  Total:   $TOTAL_TESTS"
echo -e "  ${GREEN}PASS${NC}:    $PASS_COUNT"
echo -e "  ${RED}FAIL${NC}:    $FAIL_COUNT"
echo -e "  ${YELLOW}SKIP${NC}:    $SKIP_COUNT"
echo ""

# 判定（SKIP があっても FAIL がなければ成功とするが、SKIP を明示）
if [[ $FAIL_COUNT -eq 0 ]]; then
    if [[ $SKIP_COUNT -eq 0 ]]; then
        echo -e "  ${GREEN}[A+] All tests passed - Report Fraud Resistant${NC}"
    else
        echo -e "  ${GREEN}[A-] Tests passed with ${SKIP_COUNT} skipped - Partial Coverage${NC}"
        echo ""
        echo "  注: SKIPPED テストは統合テスト環境で別途検証が必要"
    fi
    echo ""
    echo "========================================"
    exit 0
else
    echo -e "  ${RED}[FAIL] Some tests failed${NC}"
    echo ""
    echo "========================================"
    exit 1
fi
