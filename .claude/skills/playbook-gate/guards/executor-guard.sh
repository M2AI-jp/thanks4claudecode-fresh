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
#      - codex: Codex CLI 使用を促す
#      - coderabbit: CodeRabbit CLI 使用を促す
#      - user: ユーザー作業であることを通知
#   5. コードファイル編集をブロック

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# ============================================================
# Admin モードチェック（M079: コア契約は回避不可）
# ============================================================
# admin モードでも executor 強制は維持
# CLAUDE.md Core Contract: AIエージェントオーケストレーションは回避不可
# 注: admin は「executor の変更」を許可するが「executor 無視」は不可

# ============================================================
# Toolstack 取得
# ============================================================
TOOLSTACK="A"  # デフォルト
if [ -f "$STATE_FILE" ]; then
    TS=$(grep -A3 "^## config" "$STATE_FILE" 2>/dev/null | grep "toolstack:" | head -1 | sed 's/toolstack: *//' | sed 's/ *#.*//' | tr -d ' ')
    if [[ -n "$TS" ]]; then
        TOOLSTACK="$TS"
    fi
fi

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

# focus.current を取得（pipefail 対策: || true）
FOCUS=$(grep -A6 "^## focus" "$STATE_FILE" 2>/dev/null | grep "^current:" | head -1 | sed 's/current: *//' | sed 's/ *#.*//' | tr -d ' ' || true)

# playbook から active を取得（M085 修正: 正しい state.md フォーマットに対応）
# 旧フォーマット: ## active_playbooks + ${FOCUS}: path
# 新フォーマット: ## playbook + active: path
PLAYBOOK_PATH=$(grep -A8 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ' || true)

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
    # M085 修正: "- executor:" 形式にも対応（YAML リストアイテム）
    if [[ "$LINE" =~ ^[[:space:]]*-?[[:space:]]*executor:[[:space:]]*(.+)$ ]]; then
        EXECUTOR=$(echo "${BASH_REMATCH[1]}" | tr -d ' ')
        break
    fi
    # id: に到達したら止める（Phase の境界）
    if [[ "$LINE" =~ ^[[:space:]]*-[[:space:]]*id: ]]; then
        break
    fi
done

# ==============================================================
# role-resolver.sh で役割名を具体的な executor に解決
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$SCRIPT_DIR/role-resolver.sh" && -n "$EXECUTOR" ]]; then
    RESOLVED_EXECUTOR=$(TOOLSTACK="$TOOLSTACK" bash "$SCRIPT_DIR/role-resolver.sh" "$EXECUTOR" 2>/dev/null || echo "$EXECUTOR")
    if [[ -n "$RESOLVED_EXECUTOR" ]]; then
        EXECUTOR="$RESOLVED_EXECUTOR"
    fi
fi

# executor が空または claudecode ならスキップ
if [[ -z "$EXECUTOR" || "$EXECUTOR" == "claudecode" ]]; then
    exit 0
fi

# --------------------------------------------------
# Toolstack による executor 事前チェック
# --------------------------------------------------
# A: claudecode, user のみ
# B: claudecode, codex, user
# C: claudecode, codex, coderabbit, user

case "$TOOLSTACK" in
    A)
        if [[ "$EXECUTOR" == "codex" || "$EXECUTOR" == "coderabbit" ]]; then
            cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ Toolstack A では $EXECUTOR は使用できません
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  現在の toolstack: A (Claude Code のみ)
  playbook の executor: $EXECUTOR

  Toolstack A で許可される executor:
    - claudecode
    - user

  対処法:
    1. state.md の config.toolstack を B または C に変更
    2. または playbook の executor を claudecode に変更

  Toolstack の説明:
    A: Claude Code のみ（シンプル）
    B: Claude Code + Codex（コード生成強化）
    C: Claude Code + Codex + CodeRabbit（フルスタック）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
            exit 2
        fi
        ;;
    B)
        if [[ "$EXECUTOR" == "coderabbit" ]]; then
            cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ Toolstack B では coderabbit は使用できません
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  現在の toolstack: B (Claude Code + Codex)
  playbook の executor: coderabbit

  Toolstack B で許可される executor:
    - claudecode
    - codex
    - user

  対処法:
    1. state.md の config.toolstack を C に変更
    2. または playbook の executor を claudecode または codex に変更

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
            exit 2
        fi
        ;;
    C)
        # C は全て許可
        ;;
esac

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
  ⛔ executor: codex - Codex SubAgent を呼び出してください
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は Codex が担当です。
  Claude Code が直接コードを編集することは許可されていません。

  正しい手順（M085: SubAgent 呼び出し）:
    Task(subagent_type='codex-delegate', prompt='実装内容を説明')

  代替手順（Codex MCP 直接実行）:
    mcp__codex__codex(prompt='実装内容を説明')

  代替手順（Codex CLI）:
    Bash: codex exec "実装内容を説明"

  playbook の executor を変更したい場合:
    Task(subagent_type='pm', prompt='executor を変更')

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
  ⛔ executor: coderabbit - Reviewer SubAgent を呼び出してください
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は CodeRabbit によるレビューです。
  Claude Code が直接コードを編集することは許可されていません。

  正しい手順（M085: SubAgent 呼び出し）:
    Task(subagent_type='reviewer', prompt='レビュー対象を説明')

  代替手順（CodeRabbit CLI）:
    Bash: coderabbit review

  レビュー後の対応:
    指摘事項は別の Phase（executor: worker）で対応

  playbook の executor を変更したい場合:
    Task(subagent_type='pm', prompt='executor を変更')

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
