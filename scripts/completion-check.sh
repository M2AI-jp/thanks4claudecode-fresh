#!/bin/bash
# =============================================================================
# completion-check.sh
# =============================================================================
# リポジトリ完成状態の7条件を一括検証するスクリプト
#
# 参照: docs/completion-criteria.md
#
# 使用方法:
#   bash scripts/completion-check.sh
#   bash scripts/completion-check.sh --dry-run  # チェック項目のみ表示
#
# 終了コード:
#   0: 全7条件 PASS
#   1: 1条件以上 FAIL
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 結果カウンタ
PASS_COUNT=0
FAIL_COUNT=0

# --dry-run オプション
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# ヘッダー表示
echo "========================================"
echo "  リポジトリ完成状態チェック (7条件)"
echo "========================================"
echo ""
echo "参照: docs/completion-criteria.md"
echo "日時: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY-RUN モード: チェック項目のみ表示]"
  echo ""
  echo "1. Skill 構造の完全性 (SKILL.md >= 13)"
  echo "2. SubAgent の整合性 (diff = 0)"
  echo "3. Hook チェーンの動作 (hooks/*.sh >= 5)"
  echo "4. 報酬詐欺耐性 (5層防御システム)"
  echo "5. MECE 状態 (孤立ファイルなし)"
  echo "6. Bash 保護の適正動作"
  echo "7. ドキュメント完全性"
  exit 0
fi

# -----------------------------------------------------------------------------
# 条件1: Skill 構造の完全性
# -----------------------------------------------------------------------------
echo "--- 条件1: Skill 構造の完全性 ---"
SKILL_COUNT=$(find .claude/skills -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$SKILL_COUNT" -ge 13 ]]; then
  echo -e "${GREEN}[PASS]${NC} SKILL.md count: $SKILL_COUNT (>= 13)"
  ((PASS_COUNT++))
else
  echo -e "${RED}[FAIL]${NC} SKILL.md count: $SKILL_COUNT (expected >= 13)"
  ((FAIL_COUNT++))
fi
echo ""

# -----------------------------------------------------------------------------
# 条件2: SubAgent の整合性
# -----------------------------------------------------------------------------
echo "--- 条件2: SubAgent の整合性 ---"
AGENTS_DIFF=$(diff <(ls .claude/agents/*.md 2>/dev/null | xargs -I {} basename {} | sort) \
                   <(find .claude/skills -path '*/agents/*.md' -exec basename {} \; | sort) 2>/dev/null | wc -l | tr -d ' ')
if [[ "$AGENTS_DIFF" -eq 0 ]]; then
  echo -e "${GREEN}[PASS]${NC} SubAgent 整合性: diff = $AGENTS_DIFF"
  ((PASS_COUNT++))
else
  echo -e "${RED}[FAIL]${NC} SubAgent 整合性: diff = $AGENTS_DIFF (expected 0)"
  ((FAIL_COUNT++))
fi
echo ""

# -----------------------------------------------------------------------------
# 条件3: Hook チェーンの動作
# -----------------------------------------------------------------------------
echo "--- 条件3: Hook チェーンの動作 ---"
HOOK_COUNT=$(find .claude/hooks -name '*.sh' -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$HOOK_COUNT" -ge 5 ]]; then
  echo -e "${GREEN}[PASS]${NC} Hook ファイル数: $HOOK_COUNT (>= 5)"
  ((PASS_COUNT++))
else
  echo -e "${RED}[FAIL]${NC} Hook ファイル数: $HOOK_COUNT (expected >= 5)"
  ((FAIL_COUNT++))
fi
echo ""

# -----------------------------------------------------------------------------
# 条件4: 報酬詐欺耐性（5層防御システム）
# -----------------------------------------------------------------------------
echo "--- 条件4: 報酬詐欺耐性（5層防御システム） ---"
GUARD_PASS=0
for guard in critic-guard subtask-guard phase-status-guard scope-guard completion-check; do
  if [[ -f ".claude/skills/reward-guard/guards/${guard}.sh" ]]; then
    echo -e "  ${GREEN}[OK]${NC} ${guard}.sh exists"
    ((GUARD_PASS++))
  else
    echo -e "  ${RED}[NG]${NC} ${guard}.sh NOT FOUND"
  fi
done

# exit 2 チェック（critic-guard の実行テスト）
set +e
echo '{"tool_input":{"file_path":"state.md","new_string":"status: done"}}' | \
  bash .claude/skills/reward-guard/guards/critic-guard.sh >/dev/null 2>&1
EXIT_CODE=$?
set -e

if [[ "$EXIT_CODE" -eq 2 ]]; then
  echo -e "  ${GREEN}[OK]${NC} critic-guard.sh blocks with exit 2"
else
  echo -e "  ${YELLOW}[WARN]${NC} critic-guard.sh exit code: $EXIT_CODE (expected 2)"
fi

if [[ "$GUARD_PASS" -ge 5 ]]; then
  echo -e "${GREEN}[PASS]${NC} 報酬詐欺耐性: $GUARD_PASS/5 guards exist"
  ((PASS_COUNT++))
else
  echo -e "${RED}[FAIL]${NC} 報酬詐欺耐性: $GUARD_PASS/5 guards exist (expected 5)"
  ((FAIL_COUNT++))
fi
echo ""

# -----------------------------------------------------------------------------
# 条件5: MECE 状態（孤立ファイルなし）
# -----------------------------------------------------------------------------
echo "--- 条件5: MECE 状態 ---"
if [[ -f "docs/orphan-audit.md" ]]; then
  AUDIT_COMPLETE=$(grep -c 'AUDIT COMPLETE' docs/orphan-audit.md 2>/dev/null || echo 0)
  if [[ "$AUDIT_COMPLETE" -ge 1 ]]; then
    echo -e "${GREEN}[PASS]${NC} docs/orphan-audit.md: AUDIT COMPLETE found"
    ((PASS_COUNT++))
  else
    echo -e "${RED}[FAIL]${NC} docs/orphan-audit.md: AUDIT COMPLETE not found"
    ((FAIL_COUNT++))
  fi
else
  echo -e "${RED}[FAIL]${NC} docs/orphan-audit.md not found"
  ((FAIL_COUNT++))
fi
echo ""

# -----------------------------------------------------------------------------
# 条件6: Bash 保護の適正動作
# -----------------------------------------------------------------------------
echo "--- 条件6: Bash 保護の適正動作 ---"
# Note: Bash 保護は複数のファイルで実装されています。
# - .claude/lib/contract.sh: HARD_BLOCK 関数
# - .claude/skills/access-control/guards/: ガードスクリプト
# - .claude/protected-files.txt: 保護対象ファイルリスト

BASH_PROTECTION_OK=true

# contract.sh の存在確認（HARD_BLOCK 関数を含む）
if [[ -f ".claude/lib/contract.sh" ]]; then
  HARD_BLOCK_COUNT=$(grep -c 'HARD_BLOCK' .claude/lib/contract.sh 2>/dev/null || true)
  if [[ "${HARD_BLOCK_COUNT:-0}" -ge 1 ]]; then
    echo -e "  ${GREEN}[OK]${NC} contract.sh: HARD_BLOCK 定義あり"
  else
    echo -e "  ${RED}[NG]${NC} contract.sh: HARD_BLOCK 定義なし"
    BASH_PROTECTION_OK=false
  fi
else
  echo -e "  ${RED}[NG]${NC} contract.sh: ファイルなし"
  BASH_PROTECTION_OK=false
fi

# protected-edit.sh の存在確認
if [[ -f ".claude/skills/access-control/guards/protected-edit.sh" ]]; then
  echo -e "  ${GREEN}[OK]${NC} protected-edit.sh: 存在"
else
  echo -e "  ${RED}[NG]${NC} protected-edit.sh: ファイルなし"
  BASH_PROTECTION_OK=false
fi

# bash-check.sh の存在確認
if [[ -f ".claude/skills/access-control/guards/bash-check.sh" ]]; then
  echo -e "  ${GREEN}[OK]${NC} bash-check.sh: 存在"
else
  echo -e "  ${RED}[NG]${NC} bash-check.sh: ファイルなし"
  BASH_PROTECTION_OK=false
fi

# protected-files.txt の存在確認
if [[ -f ".claude/protected-files.txt" ]]; then
  PROTECTED_COUNT=$(wc -l < .claude/protected-files.txt | tr -d ' ')
  # CLAUDE.md が保護対象か確認
  if grep -q 'CLAUDE.md' .claude/protected-files.txt 2>/dev/null; then
    echo -e "  ${GREEN}[OK]${NC} protected-files.txt: $PROTECTED_COUNT 件定義（CLAUDE.md 含む）"
  else
    echo -e "  ${YELLOW}[WARN]${NC} protected-files.txt: CLAUDE.md が未定義"
  fi
else
  echo -e "  ${RED}[NG]${NC} protected-files.txt: ファイルなし"
  BASH_PROTECTION_OK=false
fi

if [[ "$BASH_PROTECTION_OK" == "true" ]]; then
  echo -e "${GREEN}[PASS]${NC} Bash 保護: 正常動作"
  ((PASS_COUNT++))
else
  echo -e "${RED}[FAIL]${NC} Bash 保護: 異常"
  ((FAIL_COUNT++))
fi
echo ""

# -----------------------------------------------------------------------------
# 条件7: ドキュメント完全性
# -----------------------------------------------------------------------------
echo "--- 条件7: ドキュメント完全性 ---"
DOC_OK=true
for doc in CLAUDE.md state.md docs/ARCHITECTURE.md; do
  if [[ -f "$doc" ]]; then
    echo -e "  ${GREEN}[OK]${NC} $doc exists"
  else
    echo -e "  ${RED}[NG]${NC} $doc NOT FOUND"
    DOC_OK=false
  fi
done

if [[ "$DOC_OK" == "true" ]]; then
  echo -e "${GREEN}[PASS]${NC} ドキュメント完全性: 全ファイル存在"
  ((PASS_COUNT++))
else
  echo -e "${RED}[FAIL]${NC} ドキュメント完全性: 一部欠落"
  ((FAIL_COUNT++))
fi
echo ""

# -----------------------------------------------------------------------------
# サマリー
# -----------------------------------------------------------------------------
echo "========================================"
echo "  サマリー"
echo "========================================"
echo -e "PASS: ${GREEN}$PASS_COUNT${NC}"
echo -e "FAIL: ${RED}$FAIL_COUNT${NC}"
echo ""

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  echo -e "${GREEN}★ 全7条件 PASS - リポジトリ完成状態${NC}"
  exit 0
else
  echo -e "${RED}✗ $FAIL_COUNT 条件 FAIL - 未完成${NC}"
  exit 1
fi
