#!/bin/bash
# ==============================================================================
# test-rollback.sh - ロールバック機能統合テスト
# ==============================================================================
# Issue #11: ロールバック機能
# ==============================================================================

# set -e を削除（テスト失敗時にスクリプトが止まらないようにする）

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

# テスト関数
test_case() {
    local name=$1
    local result=$2

    if [ "$result" -eq 0 ]; then
        echo -e "[${GREEN}PASS${NC}] $name"
        ((PASS++))
    else
        echo -e "[${RED}FAIL${NC}] $name"
        ((FAIL++))
    fi
}

echo "=== Rollback Feature Integration Test ==="
echo ""

# ==============================================================================
# Git ロールバック機能テスト
# ==============================================================================
echo "--- Git Rollback Tests ---"

# 1. rollback.sh 存在確認
test_case "rollback.sh exists" $([ -f ".claude/scripts/rollback.sh" ] && echo 0 || echo 1)

# 2. rollback.sh 実行権限確認
test_case "rollback.sh is executable" $([ -x ".claude/scripts/rollback.sh" ] && echo 0 || echo 1)

# 3. rollback.sh --help 動作確認
.claude/scripts/rollback.sh --help > /dev/null 2>&1
test_case "rollback.sh --help works" $?

# 4. rollback.sh status 動作確認
.claude/scripts/rollback.sh status > /dev/null 2>&1
test_case "rollback.sh status works" $?

# 5. /rollback コマンド定義確認
test_case "/rollback command exists" $([ -f ".claude/commands/rollback.md" ] && echo 0 || echo 1)

echo ""

# ==============================================================================
# state.md ロールバック機能テスト
# ==============================================================================
echo "--- state.md Rollback Tests ---"

# 6. state-rollback.sh 存在確認
test_case "state-rollback.sh exists" $([ -f ".claude/scripts/state-rollback.sh" ] && echo 0 || echo 1)

# 7. state-rollback.sh 実行権限確認
test_case "state-rollback.sh is executable" $([ -x ".claude/scripts/state-rollback.sh" ] && echo 0 || echo 1)

# 8. state-rollback.sh --help 動作確認
.claude/scripts/state-rollback.sh --help > /dev/null 2>&1
test_case "state-rollback.sh --help works" $?

# 9. state-history ディレクトリ確認
test_case "state-history directory exists" $([ -d ".claude/state-history" ] && echo 0 || echo 1)

# 10. state-rollback.sh backup 動作確認
.claude/scripts/state-rollback.sh backup > /dev/null 2>&1
test_case "state-rollback.sh backup works" $?

# 11. state-rollback.sh list 動作確認
.claude/scripts/state-rollback.sh list > /dev/null 2>&1
test_case "state-rollback.sh list works" $?

# 12. バックアップファイル存在確認
BACKUP_COUNT=$(ls -1 .claude/state-history/state-*.md 2>/dev/null | wc -l | tr -d ' ')
test_case "backup files exist (count: $BACKUP_COUNT)" $([ "$BACKUP_COUNT" -gt 0 ] && echo 0 || echo 1)

# 13. /state-rollback コマンド定義確認
test_case "/state-rollback command exists" $([ -f ".claude/commands/state-rollback.md" ] && echo 0 || echo 1)

echo ""

# ==============================================================================
# 設計ドキュメント確認
# ==============================================================================
echo "--- Design Document Tests ---"

# 14. 設計ドキュメント存在確認
test_case "rollback-design.md exists" $([ -f "plan/active/rollback-design.md" ] && echo 0 || echo 1)

# 15. playbook 存在確認
test_case "playbook-rollback.md exists" $([ -f "plan/active/playbook-rollback.md" ] && echo 0 || echo 1)

echo ""

# ==============================================================================
# 結果サマリー
# ==============================================================================
echo "=== Results: PASS=$PASS, FAIL=$FAIL ==="
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

exit 0
