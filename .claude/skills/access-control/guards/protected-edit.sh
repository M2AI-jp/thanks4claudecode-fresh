#!/bin/bash
# check-protected-edit.sh - 保護対象ファイルの編集をブロック
#
# PreToolUse(Edit/Write) フックとして実行される。
# stdin から JSON を受け取り、保護対象ファイルなら BLOCK を返す。
#
# 契約判定は .claude/lib/contract.sh に委譲（新アーキテクチャ）
#
# 保護レベル:
#   HARD_BLOCK - 絶対守護（security_mode に関係なく常にブロック）
#   BLOCK      - strict: ブロック / trusted: WARN
#   WARN       - 警告のみ（編集は許可）
#
# 設計思想（spec.yaml 8.5 準拠）:
#   - 軽量（10KB 以下の出力）
#   - LLMは「ルールを書いても守らない」ため、構造的にブロックする
#   - このスクリプト自体も保護対象（自己防衛）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../../../.."
CONTRACT_SCRIPT="${REPO_ROOT}/.claude/lib/contract.sh"

# contract.sh が存在する場合は source
if [[ -f "$CONTRACT_SCRIPT" ]]; then
    # shellcheck source=../../../../.claude/lib/contract.sh
    source "$CONTRACT_SCRIPT"
fi

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# パス定義
PROTECTED_LIST=".claude/protected-files.txt"
STATE_FILE="state.md"

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はブロック（Fail-closed）
if ! command -v jq &> /dev/null; then
    cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ jq 未インストール - セキュリティチェック不可
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
jq はセキュリティガードに必須です。
Install: brew install jq
EOF
    exit 2
fi

# tool_input.file_path を取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# 絶対パスを相対パスに変換
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"

# 保護ファイルリストが存在しない場合は通過
if [ ! -f "$PROTECTED_LIST" ]; then
    exit 0
fi

# security.mode を state.md から取得（デフォルト: strict）
SECURITY_MODE="strict"
if [ -f "$STATE_FILE" ]; then
    # ## security セクションから mode: を探す（コードブロック内を考慮）
    MODE_LINE=$(grep -A 10 "^## config" "$STATE_FILE" 2>/dev/null | grep "security:" | head -1 || echo "")
    if [ -n "$MODE_LINE" ]; then
        # コメントを除去してから値を取得
        SECURITY_MODE=$(echo "$MODE_LINE" | sed "s/#.*//" | sed "s/security:[[:space:]]*//" | tr -d " ")
    fi
fi

# --------------------------------------------------
# HARD_BLOCK を先にチェック（developer モードでも保護）
# --------------------------------------------------
# 新アーキテクチャ: contract.sh の is_hard_block() を使用
# これにより AUTO_HARD_BLOCK_PATTERNS も適用される
IS_HARD_BLOCK=false
if type is_hard_block &>/dev/null; then
    # contract.sh が正常に source されている場合
    if is_hard_block "$RELATIVE_PATH"; then
        IS_HARD_BLOCK=true
    fi
else
    # フォールバック: contract.sh がない場合は protected-files.txt を直接読む
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^HARD_BLOCK:(.+)$ ]]; then
            PROTECTED_PATH="${BASH_REMATCH[1]}"
            # shellcheck disable=SC2053  # Intentional glob matching for wildcard patterns
            if [[ "$RELATIVE_PATH" == "$PROTECTED_PATH" ]] || [[ "$RELATIVE_PATH" == $PROTECTED_PATH ]]; then
                IS_HARD_BLOCK=true
                break
            fi
        fi
    done < "$PROTECTED_LIST"
fi

# HARD_BLOCK の処理（M079: admin でも回避不可）
if [ "$IS_HARD_BLOCK" = true ]; then
    # M079: HARD_BLOCK は security_mode に関係なく常に保護
    # CLAUDE.md Core Contract: "HARD_BLOCK ファイル保護" は回避不可
    echo "" >&2
    echo "========================================" >&2
    echo -e "${RED}[HARD_BLOCK]${NC} 絶対守護ファイル" >&2
    echo "========================================" >&2
    echo "" >&2
    echo "ファイル: $RELATIVE_PATH" >&2
    echo "モード: $SECURITY_MODE" >&2
    echo "" >&2
    echo "このファイルは security_mode に関係なく" >&2
    echo "常に保護されています（M079 Core Contract）。" >&2
    echo "" >&2
    echo "編集するには:" >&2
    echo "  1. 直接手動で編集してください" >&2
    echo "  2. または .claude/protected-files.txt から" >&2
    echo "     HARD_BLOCK エントリを削除してください" >&2
    echo "" >&2
    echo "========================================"  >&2
    exit 2
fi

# developer モード: HARD_BLOCK 以外は無効化（非推奨）
if [ "$SECURITY_MODE" = "developer" ]; then
    echo ""
    echo "========================================"
    echo -e "${YELLOW}[DEVELOPER]${NC} 保護緩和モード（非推奨）"
    echo "========================================"
    echo ""
    echo "ファイル: $RELATIVE_PATH"
    echo "モード: developer（HARD_BLOCK 以外を無効化）"
    echo ""
    echo "⚠️ 注意: HARD_BLOCK ファイルは引き続き保護されます。"
    echo "⚠️ セッション終了時に strict モードに戻してください。"
    echo ""
    echo "========================================"
    echo ""
    exit 0
fi

# 保護ファイルリストをチェック
while IFS= read -r line || [ -n "$line" ]; do
    # コメント行と空行をスキップ
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    # HARD_BLOCK: / BLOCK: / WARN: プレフィックスを解析
    if [[ "$line" =~ ^HARD_BLOCK:(.+)$ ]]; then
        PROTECTED_PATH="${BASH_REMATCH[1]}"
        LEVEL="HARD_BLOCK"
    elif [[ "$line" =~ ^BLOCK:(.+)$ ]]; then
        PROTECTED_PATH="${BASH_REMATCH[1]}"
        LEVEL="BLOCK"
    elif [[ "$line" =~ ^WARN:(.+)$ ]]; then
        PROTECTED_PATH="${BASH_REMATCH[1]}"
        LEVEL="WARN"
    else
        # プレフィックスなしは BLOCK として扱う
        PROTECTED_PATH="$line"
        LEVEL="BLOCK"
    fi

    # パスが一致するかチェック
    # shellcheck disable=SC2053  # Intentional glob matching for wildcard patterns
    if [[ "$RELATIVE_PATH" == "$PROTECTED_PATH" ]] || [[ "$RELATIVE_PATH" == $PROTECTED_PATH ]]; then
        
        # HARD_BLOCK: 常にブロック
        if [ "$LEVEL" = "HARD_BLOCK" ]; then
            echo "" >&2
            echo "========================================" >&2
            echo -e "${RED}[HARD_BLOCK]${NC} 絶対守護ファイル" >&2
            echo "========================================" >&2
            echo "" >&2
            echo "ファイル: $RELATIVE_PATH" >&2
            echo "" >&2
            echo "このファイルは security_mode に関係なく" >&2
            echo "常に保護されています。" >&2
            echo "" >&2
            echo "編集するには:" >&2
            echo "  1. このファイルを直接手動で編集してください" >&2
            echo "  2. または .claude/protected-files.txt から" >&2
            echo "     HARD_BLOCK エントリを削除してください" >&2
            echo "" >&2
            echo "========================================" >&2
            exit 2
        
        # BLOCK: mode に応じて挙動を変える
        elif [ "$LEVEL" = "BLOCK" ]; then
            # admin モード: 全て通過
            if [ "$SECURITY_MODE" = "admin" ]; then
                exit 0
            elif [ "$SECURITY_MODE" = "trusted" ]; then
                # trusted モード: WARN として通過
                echo ""
                echo "========================================"
                echo -e "${YELLOW}[BLOCK→WARN]${NC} trusted モード"
                echo "========================================"
                echo ""
                echo "ファイル: $RELATIVE_PATH"
                echo "モード: trusted（BLOCK を WARN に緩和）"
                echo ""
                echo "注意: このファイルは通常 BLOCK ですが、"
                echo "trusted モードのため編集を許可します。"
                echo ""
                echo "========================================"
                echo ""
                exit 0
            else
                # strict モード: ブロック
                echo "" >&2
                echo "========================================" >&2
                echo -e "${RED}[BLOCK]${NC} 保護対象ファイル" >&2
                echo "========================================" >&2
                echo "" >&2
                echo "ファイル: $RELATIVE_PATH" >&2
                echo "モード: strict" >&2
                echo "" >&2
                echo "このファイルは BLOCK 保護されています。" >&2
                echo "" >&2
                echo "対処法:" >&2
                echo "  1. state.md の security.mode を trusted に変更" >&2
                echo "  2. または保護リストから削除" >&2
                echo "" >&2
                echo "========================================" >&2
                exit 2
            fi
        
        # WARN: 常に警告のみ
        elif [ "$LEVEL" = "WARN" ]; then
            echo ""
            echo "========================================"
            echo -e "${YELLOW}[WARN]${NC} 慎重に扱うべきファイル"
            echo "========================================"
            echo ""
            echo "ファイル: $RELATIVE_PATH"
            echo ""
            echo "このファイルは重要なファイルです。"
            echo "編集内容が適切か確認してください。"
            echo ""
            echo "========================================"
            echo ""
            exit 0
        fi
    fi
done < "$PROTECTED_LIST"

# 保護対象でない場合は通過
exit 0
