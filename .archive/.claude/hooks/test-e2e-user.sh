#!/bin/bash
# ==============================================================================
# test-e2e-user.sh - 新規ユーザー向け E2E シナリオ検証 (M0-T5)
# ==============================================================================
# 目的:
#   - roadmap/vision/setup ドキュメントに、フォークからデプロイまでの
#     ユーザージャーニーが欠落なく記述されていることを検証する。
#   - M6-T1, M6-T2（scenario_1 / scenario_2）の要件と期待値が
#     リポジトリで根拠付けられているかを確認する。
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

log_result() {
    local status="$1"
    local id="$2"
    local desc="$3"
    local detail="${4:-}"

    if [ "$status" = "pass" ]; then
        echo -e "[$id] $desc ... ${GREEN}PASS${NC}"
        ((PASS_COUNT++))
    else
        echo -e "[$id] $desc ... ${RED}FAIL${NC}"
        if [ -n "$detail" ]; then
            echo "    → $detail"
        fi
        ((FAIL_COUNT++))
    fi

    return 0
}

assert_file_exists() {
    local id="$1"
    local desc="$2"
    local path="$3"

    if [ -f "$path" ]; then
        log_result "pass" "$id" "$desc"
    else
        log_result "fail" "$id" "$desc" "$path が見つかりません"
    fi
}

assert_contains() {
    local id="$1"
    local desc="$2"
    local path="$3"
    local needle="$4"

    if grep -Fq "$needle" "$path"; then
        log_result "pass" "$id" "$desc"
    else
        log_result "fail" "$id" "$desc" "\"$needle\" が $path に存在しません"
    fi
}

echo "=============================================="
echo " 新規ユーザー E2E シナリオテスト (M0-T5)"
echo "=============================================="
echo ""

assert_file_exists "DOC-1" "plan/vision.md が存在" "plan/vision.md"
assert_file_exists "DOC-2" "plan/roadmap.md が存在" "plan/roadmap.md"
assert_file_exists "DOC-3" "setup/playbook-setup.md が存在" "setup/playbook-setup.md"
echo ""

echo "=== Scenario 1: フォーク → setup 完走 ==="
assert_contains "S1-1" "フォーク開始ステップが roadmap に記載" "plan/roadmap.md" "1. リポジトリをフォーク"
assert_contains "S1-2" "Claude Code 起動ステップが記載" "plan/roadmap.md" "2. Claude Code 起動"
assert_contains "S1-3" "session-start.sh 自動実行が記載" "plan/roadmap.md" "3. session-start.sh 自動実行"
assert_contains "S1-4" "setup フロー開始ステップが記載" "plan/roadmap.md" "4. setup フロー開始"
assert_contains "S1-5" "環境セットアップ完了が記載" "plan/roadmap.md" "5. 環境セットアップ完了"
assert_contains "S1-6" "playbook 生成ステップが記載" "plan/roadmap.md" "6. playbook 生成"
assert_contains "S1-7" "vision でセットアップ時間が 30 分以内と定義" "plan/vision.md" "セットアップ時間 | 30分以内"
assert_contains "S1-8" "roadmap done_when で 30 分以内を要求" "plan/roadmap.md" "フォーク → setup 完走が 30 分以内"
assert_contains "S1-9" "setup playbook で plan/project.md 生成が必須" "setup/playbook-setup.md" "plan/project.md が生成されている"
assert_contains "S1-10" "setup 完了後に focus.current を product へ切替" "setup/playbook-setup.md" "focus.current が product"
echo ""

echo "=== Scenario 2: playbook → 実装 → デプロイ ==="
assert_contains "S2-1" "playbook に基づいて実装する工程が定義" "plan/roadmap.md" "1. playbook に基づいて実装"
assert_contains "S2-2" "テスト実行ステップが定義" "plan/roadmap.md" "2. テスト実行"
assert_contains "S2-3" "CodeRabbit レビュー工程が定義" "plan/roadmap.md" "3. CodeRabbit レビュー"
assert_contains "S2-4" "マージ工程が定義" "plan/roadmap.md" "4. マージ"
assert_contains "S2-5" "デプロイ工程が定義" "plan/roadmap.md" "5. デプロイ"
assert_contains "S2-6" "done_when で実装からデプロイ完了を要求" "plan/roadmap.md" "実装 → デプロイが正常完了"
assert_contains "S2-7" "vision で CodeRabbit 自動レビューを宣言" "plan/vision.md" "6. CodeRabbit が自動レビュー"
assert_contains "S2-8" "vision でデプロイ完了がゴールに含まれる" "plan/vision.md" "7. アプリ完成 → デプロイ"
assert_contains "S2-9" "setup playbook に Phase 6: API キー設定とデプロイ が存在" "setup/playbook-setup.md" "Phase 6: API キー設定とデプロイ"
assert_contains "S2-10" "setup 完了条件に Vercel デプロイ済みが含まれる" "setup/playbook-setup.md" "Vercel にデプロイ済み"
assert_contains "S2-11" "プロジェクト作成 Phase で pnpm dev 起動条件を要求" "setup/playbook-setup.md" "pnpm dev でローカルサーバーが起動する"
echo ""

TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "=============================================="
echo "結果: $PASS_COUNT/$TOTAL PASS"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ 新規ユーザー E2E シナリオはドキュメントで裏付けられています${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAIL_COUNT 件の不足があります${NC}"
    exit 1
fi
