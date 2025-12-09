#!/bin/bash
# executor-guard.sh - Phase の executor を構造的に強制
#
# 目的: executor: codex/coderabbit/user の Phase で Claude が直接作業することを防止
# トリガー: PreToolUse(Edit), PreToolUse(Write)
#
# 動作:
#   1. 現在の playbook を特定
#   2. in_progress の Phase を特定
#   3. その Phase の executor を取得
#   4. executor が claudecode 以外の場合:
#      - codex: Codex MCP 使用を促す
#      - coderabbit: CodeRabbit CLI 使用を促す
#      - user: ユーザー作業であることを通知
#   5. コードファイル編集をブロック

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# 編集対象ファイルを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# 相対パスに変換
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"

# state.md が存在しない場合はパス
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# focus.current を取得
FOCUS=$(grep -A6 "^## focus" "$STATE_FILE" | grep "^current:" | head -1 | sed 's/current: *//' | sed 's/ *#.*//' | tr -d ' ')

# active_playbooks から現在の focus の playbook を取得
PLAYBOOK_PATH=$(grep -A8 "^## active_playbooks" "$STATE_FILE" | grep "^${FOCUS}:" | head -1 | sed "s/${FOCUS}: *//" | sed 's/ *#.*//' | tr -d ' ')

# playbook が null または空ならスキップ
if [[ -z "$PLAYBOOK_PATH" || "$PLAYBOOK_PATH" == "null" ]]; then
    exit 0
fi

# playbook ファイルが存在しない場合はスキップ
if [[ ! -f "$PLAYBOOK_PATH" ]]; then
    exit 0
fi

# playbook から in_progress の Phase を探す
# 形式: status: in_progress
IN_PROGRESS_LINE=$(grep -n "status: in_progress" "$PLAYBOOK_PATH" 2>/dev/null | head -1 || echo "")
if [[ -z "$IN_PROGRESS_LINE" ]]; then
    exit 0
fi

# その Phase の executor を取得（status: in_progress の前の行を遡る）
LINE_NUM=$(echo "$IN_PROGRESS_LINE" | cut -d: -f1)

# executor を探す（status 行より前の近い行を探す）
EXECUTOR=""
for i in $(seq "$LINE_NUM" -1 1); do
    LINE=$(sed -n "${i}p" "$PLAYBOOK_PATH")
    if [[ "$LINE" =~ ^[[:space:]]*executor:[[:space:]]*(.+)$ ]]; then
        EXECUTOR=$(echo "${BASH_REMATCH[1]}" | tr -d ' ')
        break
    fi
    # id: に到達したら止める（Phase の境界）
    if [[ "$LINE" =~ ^[[:space:]]*-[[:space:]]*id: ]]; then
        break
    fi
done

# executor が空または claudecode ならスキップ
if [[ -z "$EXECUTOR" || "$EXECUTOR" == "claudecode" ]]; then
    exit 0
fi

# --------------------------------------------------
# executor が claudecode 以外の場合の処理
# --------------------------------------------------

# コードファイルかどうか判定（拡張子ベース）
IS_CODE_FILE=false
CODE_EXTENSIONS=("ts" "tsx" "js" "jsx" "py" "go" "rs" "java" "c" "cpp" "h" "hpp" "rb" "php" "swift" "kt")
for ext in "${CODE_EXTENSIONS[@]}"; do
    if [[ "$RELATIVE_PATH" == *".$ext" ]]; then
        IS_CODE_FILE=true
        break
    fi
done

# src/, app/, lib/, components/ などのディレクトリもコードとみなす
if [[ "$RELATIVE_PATH" == src/* ]] || [[ "$RELATIVE_PATH" == app/* ]] || \
   [[ "$RELATIVE_PATH" == lib/* ]] || [[ "$RELATIVE_PATH" == components/* ]] || \
   [[ "$RELATIVE_PATH" == pages/* ]] || [[ "$RELATIVE_PATH" == api/* ]]; then
    IS_CODE_FILE=true
fi

# コードファイルでない場合はスキップ（ドキュメント等は許可）
if [[ "$IS_CODE_FILE" == false ]]; then
    exit 0
fi

# executor 別のメッセージ
case "$EXECUTOR" in
    codex)
        cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: codex - Codex MCP を使用してください
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は Codex が担当です。
  Claude Code が直接コードを編集することは許可されていません。

  正しい手順:
    1. Codex MCP を呼び出す:
       mcp__codex__codex(prompt='実装内容を説明')

    2. Codex の出力を確認

    3. 必要に応じて修正を依頼

  playbook の executor を変更したい場合:
    pm エージェントに依頼してください。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
        echo "  対象ファイル: $RELATIVE_PATH" >&2
        echo "  現在の executor: $EXECUTOR" >&2
        echo "" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        exit 2
        ;;

    coderabbit)
        cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: coderabbit - CodeRabbit CLI を使用してください
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は CodeRabbit によるレビューです。
  Claude Code が直接コードを編集することは許可されていません。

  正しい手順:
    1. CodeRabbit CLI を実行:
       Bash: coderabbit review

    2. レビュー結果を確認

    3. 指摘事項を別の Phase で対応

  playbook の executor を変更したい場合:
    pm エージェントに依頼してください。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
        echo "  対象ファイル: $RELATIVE_PATH" >&2
        echo "  現在の executor: $EXECUTOR" >&2
        echo "" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        exit 2
        ;;

    user)
        cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: user - ユーザー作業の Phase です
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase はユーザーが手動で行う作業です。
  Claude Code が代行することは許可されていません。

  例:
    - 外部サービスへの登録
    - API キーの取得
    - 支払い情報の入力
    - 手動での確認作業

  正しい手順:
    1. ユーザーに作業内容を説明
    2. ユーザーが作業を完了するのを待つ
    3. done_criteria をチェックリストで確認

  playbook の executor を変更したい場合:
    pm エージェントに依頼してください。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
        echo "  対象ファイル: $RELATIVE_PATH" >&2
        echo "  現在の executor: $EXECUTOR" >&2
        echo "" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        exit 2
        ;;

    *)
        # 未知の executor は警告のみ
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠️ 未知の executor: $EXECUTOR"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        exit 0
        ;;
esac
