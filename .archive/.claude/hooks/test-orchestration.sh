#!/bin/bash
# ==============================================================================
# test-orchestration.sh - Claude Code → Codex → CodeRabbit オーケストレーション検証
# ==============================================================================
# 目的:
#   - plan/vision.md と plan/roadmap.md の整合性から、委譲とレビューのシナリオが
#     明文化されていることを確認する。
#   - M0-T4 の done_criteria（シナリオ 1, 2）がリポジトリに反映されているか検証。
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

# Script may be invoked from anywhere; normalize to repo root for consistent paths.
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
echo " Claude Code Orchestration Test (M0-T4)"
echo "=============================================="
echo ""

assert_file_exists "SETUP-1" "plan/vision.md が存在" "plan/vision.md"
assert_file_exists "SETUP-2" "plan/roadmap.md が存在" "plan/roadmap.md"
echo ""

echo "=== Scenario 1: Claude Code → Codex 委譲 ==="
assert_contains "S1-1" "ユーザーリクエストが roadmap に定義" "plan/roadmap.md" '1. ユーザー: "認証機能を追加して"'
assert_contains "S1-2" "Claude Code が playbook を生成する手順を保持" "plan/roadmap.md" "2. Claude Code: playbook 生成"
assert_contains "S1-3" "Codex への委譲ステップが明示" "plan/roadmap.md" "3. Claude Code: Codex に委譲"
assert_contains "S1-4" "Codex の実装ステップが記述" "plan/roadmap.md" "4. Codex: 実装"
assert_contains "S1-5" "Claude Code の結果検証ステップが定義" "plan/roadmap.md" "5. Claude Code: 結果検証"
assert_contains "S1-6" "Claude Code が Codex へ委譲する責務を保持" "plan/vision.md" "codex: 長時間のコード実装"
assert_contains "S1-7" "Codex の capabilities にコード実装が含まれる" "plan/vision.md" "      - コード実装"
assert_contains "S1-8" "Codex から実装結果を返す定義が存在" "plan/vision.md" "      - 実装結果"
assert_contains "S1-9" "done_when で委譲成功の証跡が求められる" "plan/roadmap.md" "Claude Code → Codex 委譲が正常動作"
echo ""

echo "=== Scenario 2: Claude Code → CodeRabbit 連携 ==="
assert_contains "S2-1" "git push をトリガーにしたシナリオが記載" "plan/roadmap.md" "1. git push"
assert_contains "S2-2" "CodeRabbit レビュー工程が記載" "plan/roadmap.md" "2. CodeRabbit がレビュー"
assert_contains "S2-3" "レビュー結果確認ステップが存在" "plan/roadmap.md" "3. レビュー結果を確認"
assert_contains "S2-4" "修正対応までの流れが記載" "plan/roadmap.md" "4. 修正対応"
assert_contains "S2-5" "CodeRabbit のトリガーが vision に定義" "plan/vision.md" "      - git push 時"
assert_contains "S2-6" "CodeRabbit がレビューコメントを返却する定義が存在" "plan/vision.md" "      - レビューコメント"
assert_contains "S2-7" "done_when で CodeRabbit レビュー自動実行を要求" "plan/roadmap.md" "CodeRabbit レビューが自動実行"
assert_contains "S2-8" "Claude Code から CodeRabbit への委譲関係を保持" "plan/vision.md" "coderabbit: 自動レビュー"
echo ""

TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "=============================================="
echo "結果: $PASS_COUNT/$TOTAL PASS"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ オーケストレーション定義はシナリオ通りです${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAIL_COUNT 件の不足があります${NC}"
    exit 1
fi
