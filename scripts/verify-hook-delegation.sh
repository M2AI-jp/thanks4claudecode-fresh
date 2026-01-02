#!/bin/bash
# verify-hook-delegation.sh - Hook が contract.sh に委譲しているか検証
#
# Usage:
#   bash scripts/verify-hook-delegation.sh
#
# 目的:
#   - 全ての Hook が contract.sh を source しているか確認
#   - 契約ロジックの重複を検出
#   - HARD_BLOCK 以外の Hook の委譲状態をレポート
#
# Exit codes:
#   0 - 全て PASS
#   1 - 検証エラーあり

set -uo pipefail

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
HOOKS_DIR="${REPO_ROOT}/.claude/hooks"
CONTRACT_SCRIPT="${SCRIPT_DIR}/contract.sh"

# カウンタ
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# ==============================================================================
# ヘルパー関数
# ==============================================================================

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# ==============================================================================
# 検証: contract.sh の存在
# ==============================================================================

check_contract_exists() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1. contract.sh の存在確認"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ -f "$CONTRACT_SCRIPT" ]]; then
        log_pass "contract.sh が存在: $CONTRACT_SCRIPT"
    else
        log_fail "contract.sh が存在しない: $CONTRACT_SCRIPT"
        echo ""
        echo "  contract.sh は契約判定の中核スクリプトです。"
        echo "  先に作成してください。"
        exit 1
    fi
}

# ==============================================================================
# 検証: Hook の委譲状態
# ==============================================================================

check_hook_delegation() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  2. Hook の委譲状態"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # 契約判定を含むべき Hook（HARD_BLOCK 以外）
    local delegation_required=(
        "pre-bash-check.sh"
        "check-protected-edit.sh"
    )

    # HARD_BLOCK Hook で contract.sh 統合が必要なもの
    local hard_block_hooks_need_patch=(
        "playbook-guard.sh"
    )

    # HARD_BLOCK Hook だが専門用途で contract.sh 統合不要
    local hard_block_hooks_no_patch=(
        "init-guard.sh"      # セッション初期化専用
        "critic-guard.sh"    # 自己承認防止専用
        "scope-guard.sh"     # スコープクリープ検出専用
        "executor-guard.sh"  # 役割強制専用
    )

    # 委譲が不要な Hook（契約チェック対象外）
    local no_delegation_needed=(
        "session-start.sh"
        "session-end.sh"
        "coherence.sh"
        "failure-logger.sh"
        "generate-repository-map.sh"
    )

    echo "--- 委譲必須 Hook ---"
    for hook in "${delegation_required[@]}"; do
        local hook_path="${HOOKS_DIR}/${hook}"
        if [[ -f "$hook_path" ]]; then
            local has_source=false
            local has_call=false

            # source contract.sh があるか
            if grep -q "source.*contract\.sh" "$hook_path" 2>/dev/null; then
                has_source=true
            fi

            # contract_check_bash or contract_check_edit を呼んでいるか
            if grep -q "contract_check_bash\|contract_check_edit" "$hook_path" 2>/dev/null; then
                has_call=true
            fi

            if [[ "$has_source" == "true" ]] && [[ "$has_call" == "true" ]]; then
                log_pass "$hook: contract.sh を source し、contract_check を呼んでいる"
            elif [[ "$has_source" == "true" ]]; then
                log_warn "$hook: source しているが contract_check_* を呼んでいない（形だけの委譲）"
            elif [[ "$has_call" == "true" ]]; then
                log_warn "$hook: contract_check を使用しているが source が見つからない"
            else
                log_fail "$hook: contract.sh への委譲なし"
            fi
        else
            log_info "$hook: ファイルが存在しない（スキップ）"
        fi
    done

    echo ""
    echo "--- HARD_BLOCK Hook（contract.sh 統合必要） ---"
    local patches_dir="${REPO_ROOT}/docs/manual-patches"
    for hook in "${hard_block_hooks_need_patch[@]}"; do
        local hook_path="${HOOKS_DIR}/${hook}"
        local patch_path="${patches_dir}/${hook}.patch"
        if [[ -f "$hook_path" ]]; then
            local has_source=false
            local has_call=false
            local has_patch=false

            if grep -q "source.*contract\.sh" "$hook_path" 2>/dev/null; then
                has_source=true
            fi
            if grep -q "contract_check_bash\|contract_check_edit" "$hook_path" 2>/dev/null; then
                has_call=true
            fi
            if [[ -f "$patch_path" ]]; then
                has_patch=true
            fi

            if [[ "$has_source" == "true" ]] && [[ "$has_call" == "true" ]]; then
                log_pass "$hook: 委譲済み"
            elif [[ "$has_patch" == "true" ]]; then
                log_warn "$hook: HARD_BLOCK - パッチ提供済み (${hook}.patch)"
            else
                log_fail "$hook: HARD_BLOCK - パッチ未提供"
            fi
        else
            log_info "$hook: ファイルが存在しない"
        fi
    done

    echo ""
    echo "--- HARD_BLOCK Hook（専門用途、統合不要） ---"
    for hook in "${hard_block_hooks_no_patch[@]}"; do
        local hook_path="${HOOKS_DIR}/${hook}"
        if [[ -f "$hook_path" ]]; then
            log_info "$hook: 専門用途（contract.sh 統合不要）"
        else
            log_info "$hook: ファイルが存在しない"
        fi
    done

    echo ""
    echo "--- 委譲不要 Hook ---"
    for hook in "${no_delegation_needed[@]}"; do
        local hook_path="${HOOKS_DIR}/${hook}"
        if [[ -f "$hook_path" ]]; then
            log_info "$hook: 契約チェック対象外（委譲不要）"
        fi
    done
}

# ==============================================================================
# 検証: ロジック重複
# ==============================================================================

check_duplicate_logic() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  3. ロジック重複の検出"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # 重複の兆候となるパターン
    local duplicate_patterns=(
        "HARD_BLOCK_FILES="
        "MUTATION_PATTERNS="
        "maintenance_whitelist"
        "is_hard_block"
        "is_maintenance_allowed"
    )

    for pattern in "${duplicate_patterns[@]}"; do
        local found_in=""
        for hook in "${HOOKS_DIR}"/*.sh; do
            if [[ -f "$hook" ]] && grep -q "$pattern" "$hook" 2>/dev/null; then
                local hook_name=$(basename "$hook")
                # contract.sh を source しているか確認
                if ! grep -q "source.*contract\.sh" "$hook" 2>/dev/null; then
                    found_in="${found_in}${hook_name}, "
                fi
            fi
        done

        if [[ -n "$found_in" ]]; then
            log_warn "パターン '$pattern' が重複: ${found_in%, }"
            echo "      → contract.sh に集約すべき"
        else
            log_pass "パターン '$pattern': 重複なし"
        fi
    done
}

# ==============================================================================
# 検証: contract.sh の必須関数
# ==============================================================================

check_contract_functions() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  4. contract.sh の必須関数"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local required_functions=(
        "normalize_command"
        "is_compound_command"
        "has_file_redirect"
        "get_state_value"
        "is_hard_block"
        "is_maintenance_allowed"
        "is_playbook_file"
        "is_state_file"
        "is_admin_maintenance_allowed"
        "contract_check_edit"
        "contract_check_bash"
    )

    for func in "${required_functions[@]}"; do
        if grep -q "^${func}()" "$CONTRACT_SCRIPT" 2>/dev/null || \
           grep -q "^export -f ${func}" "$CONTRACT_SCRIPT" 2>/dev/null; then
            log_pass "関数 '${func}': 定義済み"
        else
            log_fail "関数 '${func}': 未定義"
        fi
    done
}

# ==============================================================================
# サマリー
# ==============================================================================

print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  検証結果サマリー"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${GREEN}PASS${NC}: $PASS_COUNT"
    echo -e "  ${YELLOW}WARN${NC}: $WARN_COUNT"
    echo -e "  ${RED}FAIL${NC}: $FAIL_COUNT"
    echo ""

    if [[ $FAIL_COUNT -gt 0 ]]; then
        echo -e "  ${RED}検証エラーあり${NC}"
        echo ""
        echo "  対処法:"
        echo "    1. FAIL の Hook に contract.sh への委譲を追加"
        echo "    2. HARD_BLOCK Hook は docs/manual-patches/ を参照"
        return 1
    elif [[ $WARN_COUNT -gt 0 ]]; then
        echo -e "  ${YELLOW}警告あり（動作に問題なし）${NC}"
        echo ""
        echo "  推奨対処:"
        echo "    - HARD_BLOCK Hook は手動パッチを適用"
        echo "    - ロジック重複は contract.sh に集約"
        return 0
    else
        echo -e "  ${GREEN}ALL PASS${NC}"
        return 0
    fi
}

# ==============================================================================
# メイン
# ==============================================================================

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Hook Delegation Verification"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    check_contract_exists
    check_hook_delegation
    check_duplicate_logic
    check_contract_functions

    print_summary
}

main "$@"
