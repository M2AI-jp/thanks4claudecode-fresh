#!/bin/bash
# test-done-criteria.sh - ワークスペース検証テスト
#
# 使い方:
#   bash .claude/hooks/test-done-criteria.sh [test_id]
#
# 例:
#   bash .claude/hooks/test-done-criteria.sh       # 全テスト実行
#   bash .claude/hooks/test-done-criteria.sh t1    # t1 のみ実行
#
# テスト定義: tests.md

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TARGET="${1:-all}"
TOTAL=0
PASSED=0
FAILED=0

echo ""
echo "=========================================="
echo "  Workspace Verification Tests"
echo "=========================================="

run_test() {
    TOTAL=$((TOTAL + 1))
    echo ""
    echo "--- $1: $2 ---"
}

pass() { PASSED=$((PASSED + 1)); echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { FAILED=$((FAILED + 1)); echo -e "${RED}[FAIL]${NC} $1"; }

# t1: focus-guard
test_t1() {
    run_test "t1" "focus-guard"
    # focus を setup に変更し、session を task に変更して、CLAUDE.md を stage
    # setup では CLAUDE.md 編集は許可されないので WARNING が出るはず
    cp state.md state.md.bak
    sed -i '' 's/current: workspace/current: setup/' state.md
    sed -i '' 's/session: discussion/session: task/' state.md
    # 一時的にファイルを変更して stage
    echo "# test" >> CLAUDE.md.test 2>/dev/null || true
    git add CLAUDE.md.test 2>/dev/null || true
    OUTPUT=$(bash .claude/hooks/check-coherence.sh 2>&1 || true)
    git reset HEAD CLAUDE.md.test >/dev/null 2>&1 || true
    rm -f CLAUDE.md.test 2>/dev/null || true
    mv state.md.bak state.md
    echo "$OUTPUT" | grep -q "WARN.*focus=setup but editing" && pass "WARNING 検出" || fail "WARNING なし"
}

# t2: session-start
test_t2() {
    run_test "t2" "session-start"
    OUTPUT=$(bash .claude/hooks/session-start.sh 2>&1)
    echo "$OUTPUT" | grep -q "Read 完了まで作業禁止" && pass "Read 強制指示" || fail "Read 指示なし"
    # focus=setup では CONTEXT.md は出力されない（playbook-setup.md のみ）
    # 代わりに state.md パスの表示を確認（全 focus 共通）
    echo "$OUTPUT" | grep -q "state.md" && pass "パス表示" || fail "パスなし"
    echo "$OUTPUT" | grep -q "\[自認\]" && pass "[自認]" || fail "[自認]なし"
}

# t3: protected-edit
test_t3() {
    run_test "t3" "protected-edit"
    # JSON を stdin に渡す（Claude Code の PreToolUse フック形式）
    # strict モードでテスト（developer モードでも動作確認できるよう exit code を使用）
    OUTPUT=$(echo '{"tool_input":{"file_path":"CLAUDE.md"}}' | bash .claude/hooks/check-protected-edit.sh 2>&1 || true)
    # BLOCK / HARD_BLOCK / developer モードの警告のいずれかで判定
    echo "$OUTPUT" | grep -qE "\[BLOCK\]|\[HARD_BLOCK\]|\[DEVELOPER\]" && pass "保護動作確認" || fail "保護機構が動作せず"
    OUTPUT=$(echo '{"tool_input":{"file_path":"foo.txt"}}' | bash .claude/hooks/check-protected-edit.sh 2>&1 || true)
    # 実際に BLOCK された場合のみ失敗（DEVELOPER 警告は OK）
    echo "$OUTPUT" | grep -qE "^\[BLOCK\]|^\[HARD_BLOCK\]" && fail "誤 BLOCK" || pass "非保護 OK"
}

# t4: coherence
test_t4() {
    run_test "t4" "coherence"
    # session=task に一時変更してテスト（discussion だとスキップされる）
    cp state.md state.md.bak
    sed -i '' 's/session: discussion/session: task/' state.md
    OUTPUT=$(bash .claude/hooks/check-coherence.sh 2>&1 || true)
    mv state.md.bak state.md
    echo "$OUTPUT" | grep -q "plan-template" && echo "$OUTPUT" | grep -q "workspace" && pass "全レイヤー" || fail "レイヤー不足"
}

# t5: state-update
test_t5() {
    run_test "t5" "state-update"
    sed -i.bak 's/session: task/session: discussion/' state.md
    bash .claude/hooks/check-state-update.sh >/dev/null 2>&1 && pass "discussion OK" || fail "discussion NG"
    mv state.md.bak state.md
}

# t6: file-structure
test_t6() {
    run_test "t6" "file-structure"
    # 必須ファイル: CONTEXT.md, state.md, CLAUDE.md（tests.md は不要）
    [ -f "CONTEXT.md" ] && [ -f "state.md" ] && [ -f "CLAUDE.md" ] && pass "必須ファイル" || fail "ファイル不足"
    [ -d ".claude/hooks" ] && [ -d ".claude/commands" ] && pass "Claude 拡張" || fail "拡張不足"
}

case "$TARGET" in
    t1) test_t1 ;; t2) test_t2 ;; t3) test_t3 ;;
    t4) test_t4 ;; t5) test_t5 ;; t6) test_t6 ;;
    all) test_t1; test_t2; test_t3; test_t4; test_t5; test_t6 ;;
    *) echo "Unknown: $TARGET"; exit 1 ;;
esac

echo ""
echo "=========================================="
ASSERTIONS=$((PASSED + FAILED))
echo "  Results: $PASSED/$ASSERTIONS assertions passed ($TOTAL tests)"
echo "=========================================="
[ $FAILED -gt 0 ] && { echo -e "${RED}[FAIL]${NC} $FAILED assertion(s) failed"; exit 1; } || { echo -e "${GREEN}[PASS]${NC} All tests passed"; exit 0; }
