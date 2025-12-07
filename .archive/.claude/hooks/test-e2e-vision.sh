#!/bin/bash
# ==============================================================================
# test-e2e-vision.sh - 完成形ビジョン E2E テスト
# ==============================================================================
# 目的: 新規ユーザー視点で完成形ビジョンが実現するか検証
# ==============================================================================

set -u
# Note: pipefail disabled due to interaction with grep -q in tests

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

# クリーンアップ関数
cleanup() {
    if [ -f "state.md.backup" ]; then
        mv state.md.backup state.md
    fi
    if [ -n "${ORIGINAL_BRANCH:-}" ]; then
        git checkout "$ORIGINAL_BRANCH" -q 2>/dev/null || true
    fi
    git stash pop -q 2>/dev/null || true
}
trap cleanup EXIT

# テスト関数
test_case() {
    local id="$1"
    local desc="$2"
    local cmd="$3"

    echo -n "[$id] $desc ... "

    local output
    local exit_code
    output=$(eval "$cmd" 2>&1) && exit_code=0 || exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}FAIL${NC}"
        echo "    → $(echo "$output" | head -1)"
        ((FAIL_COUNT++))
    fi
}

echo "=============================================="
echo "  完成形ビジョン E2E テスト"
echo "=============================================="
echo ""

# 現在のブランチを保存
ORIGINAL_BRANCH=$(git branch --show-current)

# テスト用に main に切り替え
echo "→ main ブランチに切り替えてテスト..."
git stash -q 2>/dev/null || true
git checkout main -q

# state.md を初期状態に一時設定
cp state.md state.md.backup

# 最小限の state.md を作成
cat > state.md << 'STATEEOF'
# state.md
## focus
```yaml
current: setup
session: task
```
## security
```yaml
mode: strict
```
## active_playbooks
```yaml
setup: setup/playbook-setup.md
```
STATEEOF

echo ""
echo "=== E2E-1: session-start.sh テスト ==="

# session-start.sh が実行できるかテスト（"Read" が出力に含まれる）
test_case "E2E-1a" "session-start.sh が実行できる" \
    "bash .claude/hooks/session-start.sh 2>&1 | grep -q 'Read'"

# main ブランチ警告が出ないかテスト（focus=setup なので警告不要）
test_case "E2E-1b" "main ブランチ警告が出ない（focus=setup）" \
    "! bash .claude/hooks/session-start.sh 2>&1 | grep -q '🚨 main ブランチで作業中'"

# セットアップ案内が出るかテスト
test_case "E2E-1c" "セットアップ案内が表示される" \
    "bash .claude/hooks/session-start.sh 2>&1 | grep -q 'Phase 0'"

echo ""
echo "=== E2E-2: check-main-branch.sh テスト ==="

# focus=setup で Bash がブロックされないかテスト
test_case "E2E-2a" "focus=setup で Bash がブロックされない" \
    "echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo test\"}}' | bash .claude/hooks/check-main-branch.sh"

# focus=workspace で Bash がブロックされるかテスト
cat > state.md << 'STATEEOF'
# state.md
## focus
```yaml
current: workspace
session: task
```
## security
```yaml
mode: strict
```
STATEEOF

test_case "E2E-2b" "focus=workspace で Bash がブロックされる" \
    "! echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo test\"}}' | bash .claude/hooks/check-main-branch.sh 2>/dev/null"

echo ""
echo "=== E2E-3: ファイル存在確認 ==="

test_case "E2E-3a" "setup/playbook-setup.md が存在" \
    "test -f setup/playbook-setup.md"

test_case "E2E-3b" "README.md が新規ユーザー向け" \
    "grep -q 'フォーク' README.md"

echo ""
echo "=============================================="

# 結果サマリー
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo ""
echo "結果: $PASS_COUNT/$TOTAL PASS"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ 全テスト PASS${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAIL_COUNT 件の FAIL${NC}"
    exit 1
fi
