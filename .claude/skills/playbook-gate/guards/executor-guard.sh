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

set -uo pipefail
# Note: -e を外す（grep が空の結果を返す場合のpipefail回避）

STATE_FILE="${STATE_FILE:-state.md}"
SESSION_STATE_DIR="${SESSION_STATE_DIR:-.claude/session-state}"
LAST_FAIL_REASON_FILE="$SESSION_STATE_DIR/last-fail-reason"
ITERATION_COUNT_FILE="$SESSION_STATE_DIR/iteration-count"

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
    # -A10 に変更（config セクション全体を取得）
    TS=$(grep -A10 "^## config" "$STATE_FILE" 2>/dev/null | grep "toolstack:" | head -1 | sed 's/toolstack: *//' | sed 's/ *#.*//' | tr -d ' ' || echo "")
    if [[ -n "$TS" ]]; then
        TOOLSTACK="$TS"
    fi
fi

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

# playbook から active を取得
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
# 形式: status: in_progress または **status**: in_progress
IN_PROGRESS_LINE=$(grep -n -E "(status:|\\*\\*status\\*\\*:).*in_progress" "$PLAYBOOK_PATH" 2>/dev/null | head -1 || echo "")
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
        # =============================================================
        # M088: codex-delegate SubAgent への自動委譲を構造的に強制
        # =============================================================
        # exit 2 でブロックするが、JSON 形式で具体的な呼び出し方法を提示
        # Claude はこのメッセージを見て Task ツールで codex-delegate を呼び出す

        # =====================================================
        # 自動リトライ機構: last-fail-reason の読み込みと注入
        # =====================================================
        FAIL_INFO=""
        ITERATION_INFO=""
        MAX_ITERATIONS_WARNING=""

        if [[ -f "$LAST_FAIL_REASON_FILE" ]]; then
            # FAIL 理由を読み込み
            FAIL_REASON=$(cat "$LAST_FAIL_REASON_FILE" | tr '\n' '\\n' | sed 's/"/\\"/g')
            FAIL_INFO="\\n\\n━━━ 前回の FAIL 情報 ━━━\\n$FAIL_REASON\\n━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n⚠️ 上記のエラーを修正してください。"

            # 注入後にファイルをクリア
            rm -f "$LAST_FAIL_REASON_FILE"
        fi

        if [[ -f "$ITERATION_COUNT_FILE" ]]; then
            # イテレーションカウントを読み込み
            CURRENT_COUNT=$(grep "^count:" "$ITERATION_COUNT_FILE" 2>/dev/null | sed 's/count: *//' | tr -d ' ' || echo "0")
            ITERATION_INFO="\\n[iteration: $CURRENT_COUNT]"

            # max_iterations を playbook から取得
            MAX_ITER=5  # デフォルト
            if [[ -f "$PLAYBOOK_PATH" ]]; then
                PLAYBOOK_MAX=$(grep "max_iterations:" "$PLAYBOOK_PATH" 2>/dev/null | head -1 | sed 's/.*max_iterations: *//' | tr -d ' ' || echo "")
                if [[ -n "$PLAYBOOK_MAX" && "$PLAYBOOK_MAX" =~ ^[0-9]+$ ]]; then
                    MAX_ITER=$PLAYBOOK_MAX
                fi
            fi

            # max_iterations 到達チェック
            if [[ "$CURRENT_COUNT" -ge "$MAX_ITER" ]]; then
                MAX_ITERATIONS_WARNING="\\n\\n🚨 MAX_ITERATIONS ($MAX_ITER) に到達しました。\\nAskUserQuestion で人間の確認を取ってください。\\n選択肢: リトライ継続 / 中止 / 手動対応"
            fi
        fi

        cat << EOF
{
  "continue": false,
  "decision": "block",
  "reason": "executor: codex - codex-delegate SubAgent への委譲が必要です",
  "hookSpecificOutput": {
    "action": "delegate_to_subagent",
    "target_subagent": "codex-delegate",
    "executor": "codex",
    "file_path": "$RELATIVE_PATH",
    "has_fail_info": $([ -n "$FAIL_INFO" ] && echo "true" || echo "false"),
    "iteration_count": "${CURRENT_COUNT:-0}",
    "max_iterations": "${MAX_ITER:-5}"
  },
  "systemMessage": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n  🔄 executor: codex - codex-delegate SubAgent に自動委譲\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n  この subtask は Codex が担当です。\\n  以下の Task ツールを使って codex-delegate SubAgent に委譲してください:\\n\\n  Task(\\n    subagent_type='codex-delegate',\\n    prompt='【ここに実装内容を説明】'\\n  )\\n\\n  対象ファイル: $RELATIVE_PATH$FAIL_INFO$ITERATION_INFO$MAX_ITERATIONS_WARNING\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
EOF
        exit 2
        ;;

    coderabbit)
        # coderabbit も codex と同じ hookSpecificOutput 形式で stdout に出力
        cat << EOF
{
  "continue": false,
  "decision": "block",
  "reason": "executor: coderabbit - coderabbit-delegate SubAgent への委譲が必要です",
  "hookSpecificOutput": {
    "action": "delegate_to_subagent",
    "target_subagent": "coderabbit-delegate",
    "executor": "coderabbit",
    "file_path": "$RELATIVE_PATH",
    "review_type": "uncommitted"
  },
  "systemMessage": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n  🔄 executor: coderabbit - coderabbit-delegate SubAgent に自動委譲\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n  この Phase は CodeRabbit によるレビューです。\\n  以下の Task ツールを使って coderabbit-delegate SubAgent に委譲してください:\\n\\n  Task(\\n    subagent_type='coderabbit-delegate',\\n    prompt='【レビュー対象を説明】'\\n  )\\n\\n  対象ファイル: $RELATIVE_PATH\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
EOF
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
