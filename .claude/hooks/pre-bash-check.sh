#!/bin/bash
# pre-bash-check.sh - Bash コマンド実行前の契約チェック
#
# PreToolUse(Bash) フックとして実行される。
# 契約判定は scripts/contract.sh に集約。

set -e

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../.."
CONTRACT_SCRIPT="${REPO_ROOT}/scripts/contract.sh"
STATE_FILE="state.md"

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合は Fail-closed
if ! command -v jq &> /dev/null; then
    echo "[FAIL-CLOSED] jq not found" >&2
    exit 2
fi

# tool_input.command を取得
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# contract.sh が存在する場合は使用（新アーキテクチャ）
USE_CONTRACT=false
if [[ -f "$CONTRACT_SCRIPT" ]]; then
    # shellcheck source=../../scripts/contract.sh
    source "$CONTRACT_SCRIPT"

    # 契約チェック実行
    if ! contract_check_bash "$COMMAND"; then
        exit 2
    fi
    USE_CONTRACT=true
fi

# contract.sh がない場合のみ旧ロジックを実行（フォールバック）
if [[ "$USE_CONTRACT" == "false" ]]; then
    SECURITY=""
    PLAYBOOK=""
    if [ -f "$STATE_FILE" ]; then
        SECURITY=$(grep -A3 "^## config" "$STATE_FILE" 2>/dev/null | grep "security:" | head -1 | sed 's/security: *//' | tr -d ' ')
        PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
    fi

    # === HARD_BLOCK ファイルへのアクセス検出 ===
    HARD_BLOCK_FILES=(
        "CLAUDE.md"
        ".claude/protected-files.txt"
    )

    WRITE_PATTERNS=(
        "sed -i" "sed -i ''" "perl -i" "perl -pi"
        "echo.*>" "cat.*>" "printf.*>" "tee "
        " > " " >> " "rm " "rm -f" "rm -rf"
    )

    # /dev/null への出力は許可（誤検出防止）
    if [[ "$COMMAND" == *"> /dev/null"* ]] || [[ "$COMMAND" == *">/dev/null"* ]]; then
        COMMAND_WITHOUT_NULL=$(echo "$COMMAND" | sed 's/>[[:space:]]*\/dev\/null//g; s/2>&1//g')
        COMMAND="$COMMAND_WITHOUT_NULL"
    fi

    # HARD_BLOCK チェック
    for protected in "${HARD_BLOCK_FILES[@]}"; do
        if [[ "$COMMAND" == *"$protected"* ]]; then
            for write_pattern in "${WRITE_PATTERNS[@]}"; do
                if [[ "$COMMAND" == *$write_pattern* ]]; then
                    echo -e "${RED}[HARD_BLOCK]${NC} Bash による絶対守護ファイルへの書き込み: $protected" >&2
                    exit 2
                fi
            done
        fi
    done

    # playbook=null で変更系コマンドをブロック
    if [ -z "$PLAYBOOK" ] || [ "$PLAYBOOK" = "null" ]; then
        MUTATION_PATTERNS='cat[[:space:]]+.*>|tee[[:space:]]|sed[[:space:]]+-i|git[[:space:]]+add|git[[:space:]]+commit|mkdir[[:space:]]|touch[[:space:]]|mv[[:space:]]|cp[[:space:]]|rm[[:space:]]'
        if [[ "$COMMAND" =~ $MUTATION_PATTERNS ]]; then
            echo -e "${RED}[BLOCK]${NC} playbook=null で変更系 Bash をブロック" >&2
            exit 2
        fi
    fi
fi

# === git commit チェック ===
# 注意: "commit" を含む文字列（コメント等）で誤発動しないよう、パターンを厳密に
# パターン: "git commit" で始まる、または "&&" や ";" の後に "git commit" がある
GIT_COMMIT_PATTERN='^git[[:space:]]+commit|&&[[:space:]]*git[[:space:]]+commit|;[[:space:]]*git[[:space:]]+commit'
if [[ "$COMMAND" =~ $GIT_COMMIT_PATTERN ]]; then
    # 回帰テストを実行（stdout 出力: stderr は Claude Code にエラーと解釈される）
    if [ -f ".claude/tests/regression-test.sh" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  🧪 回帰テスト実行中..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if ! bash .claude/tests/regression-test.sh; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "  ${RED}❌ 回帰テスト失敗 - コミットをブロック${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "回帰テストが失敗しました。"
            echo "問題を修正してから再度コミットしてください。"
            echo ""
            exit 2
        fi
        echo ""
        echo -e "  ✅ 回帰テスト PASS"
        echo ""
    fi

    # 整合性チェックを実行
    bash .claude/hooks/check-coherence.sh

    # state 更新チェックを実行
    bash .claude/hooks/check-state-update.sh
fi

# 通常は通過
exit 0
