#!/bin/bash
# pre-bash-check.sh - Bash コマンド実行前のチェック
#
# PreToolUse(Bash) フックとして実行される。
# 1. 保護ファイルへの書き込みコマンドをブロック
# 2. git commit コマンドの場合は整合性チェックを実行
#
# 注意: 変数経由のファイルアクセス（export F=file && cat > "$F"）は
#       検出困難なため、HARD_BLOCK ファイルへの直接参照のみチェックする。
#       完全な保護は check-protected-edit.sh（Edit/Write）側で担保。

set -e

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# tool_input.command を取得
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# === HARD_BLOCK ファイルへのアクセス検出 ===
# これらのファイルは security_mode に関係なく常に保護
HARD_BLOCK_FILES=(
    "CONTEXT.md"
    "CLAUDE.md"
    ".claude/protected-files.txt"
)

# BLOCK ファイル（strict モードでのみ保護）
BLOCK_FILES=(
    ".claude/settings.json"
    ".claude/hooks/"
    "plan/template/"
)

# 書き込み系パターン
WRITE_PATTERNS=(
    "sed -i"
    "sed -i ''"
    "perl -i"
    "perl -pi"
    "echo.*>"
    "cat.*>"
    "printf.*>"
    "tee "
    " > "
    " >> "
)

# HARD_BLOCK チェック（常時ブロック）
for protected in "${HARD_BLOCK_FILES[@]}"; do
    if [[ "$COMMAND" == *"$protected"* ]]; then
        for write_pattern in "${WRITE_PATTERNS[@]}"; do
            if [[ "$COMMAND" == *$write_pattern* ]]; then
                echo "========================================" >&2
                echo -e "${RED}[HARD_BLOCK]${NC} Bash による絶対守護ファイルへの書き込み" >&2
                echo "========================================" >&2
                echo "" >&2
                echo "コマンド: $COMMAND" >&2
                echo "" >&2
                echo "検出されたパターン:" >&2
                echo "  - 保護ファイル: $protected" >&2
                echo "  - 書き込み操作: $write_pattern" >&2
                echo "" >&2
                echo "HARD_BLOCK ファイルは security_mode に関係なく" >&2
                echo "常に保護されています。" >&2
                echo "" >&2
                echo "========================================" >&2
                exit 1
            fi
        done
    fi
done

# security.mode を取得（strict | trusted）
STATE_FILE="state.md"
SECURITY_MODE="strict"
if [ -f "$STATE_FILE" ]; then
    MODE_LINE=$(grep -A 1 "^## security" "$STATE_FILE" 2>/dev/null | grep "mode:" | head -1 || echo "")
    if [[ "$MODE_LINE" =~ mode:\ *([a-z]+) ]]; then
        SECURITY_MODE="${BASH_REMATCH[1]}"
    fi
fi

# BLOCK チェック（strict モードのみブロック）
if [ "$SECURITY_MODE" = "strict" ]; then
    for protected in "${BLOCK_FILES[@]}"; do
        if [[ "$COMMAND" == *"$protected"* ]]; then
            for write_pattern in "${WRITE_PATTERNS[@]}"; do
                if [[ "$COMMAND" == *$write_pattern* ]]; then
                    echo "========================================" >&2
                    echo -e "${RED}[BLOCK]${NC} Bash による保護ファイルへの書き込み" >&2
                    echo "========================================" >&2
                    echo "" >&2
                    echo "コマンド: $COMMAND" >&2
                    echo "モード: strict" >&2
                    echo "" >&2
                    echo "検出されたパターン:" >&2
                    echo "  - 保護ファイル: $protected" >&2
                    echo "  - 書き込み操作: $write_pattern" >&2
                    echo "" >&2
                    echo "対処法:" >&2
                    echo "  1. Edit ツールを使用（フック検証あり）" >&2
                    echo "  2. state.md の security.mode を trusted に変更" >&2
                    echo "" >&2
                    echo "========================================" >&2
                    exit 1
                fi
            done
        fi
    done
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
            exit 1
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
