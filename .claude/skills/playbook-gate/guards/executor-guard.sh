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
SKIP_REASON=""
if [[ -z "$FILE_PATH" ]]; then
    SKIP_REASON="missing file_path" # success return removed: consolidated skip exit below
else
    # 相対パスに変換
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"

    if [[ ! -f "$STATE_FILE" ]]; then
        SKIP_REASON="state.md missing" # success return removed: consolidated skip exit below
    else
        # playbook から active を取得
        PLAYBOOK_PATH=$(grep -A8 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ' || true)

        if [[ -z "$PLAYBOOK_PATH" || "$PLAYBOOK_PATH" == "null" ]]; then
            SKIP_REASON="playbook not set" # success return removed: consolidated skip exit below
        elif [[ ! -f "$PLAYBOOK_PATH" ]]; then
            SKIP_REASON="playbook file missing" # success return removed: consolidated skip exit below
        else
            # playbook から in_progress の Phase を探す
            # 形式: status: in_progress または **status**: in_progress
            IN_PROGRESS_LINE=$(grep -n -E "(status:|\\*\\*status\\*\\*:).*in_progress" "$PLAYBOOK_PATH" 2>/dev/null | head -1 || echo "")
            if [[ -z "$IN_PROGRESS_LINE" ]]; then
                SKIP_REASON="no in_progress phase" # success return removed: consolidated skip exit below
            else
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

                if [[ -z "$EXECUTOR" || "$EXECUTOR" == "claudecode" ]]; then
                    SKIP_REASON="executor not enforced" # success return removed: consolidated skip exit below
                fi
            fi
        fi
    fi
fi

if [[ -n "$SKIP_REASON" ]]; then
    # success return consolidated: multiple skip paths return here to reduce redundant exits.
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

# コードファイルでない場合は処理を進めない（許可）
if [[ "$IS_CODE_FILE" == false ]]; then
    : # success return removed: non-code edits skip enforcement by falling through to final success exit.
else
    # executor 別のメッセージ
    case "$EXECUTOR" in
        codex)
            # =============================================================
            # M088: codex-delegate SubAgent への自動委譲を構造的に強制
            # =============================================================
            # exit 2 でブロックするが、JSON 形式で具体的な呼び出し方法を提示
            # Claude はこのメッセージを見て Task ツールで codex-delegate を呼び出す
            #
            # V17: フォールバック検出とユーザー確認フローを追加
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
    "fallback_policy": {
      "on_mcp_timeout": "CLI 直接実行 (codex exec) に切り替え",
      "on_cli_failure": "AskUserQuestion でユーザーに確認"
    }
  },
  "systemMessage": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n  🔄 executor: codex - codex-delegate SubAgent に自動委譲\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n  この subtask は Codex が担当です。\\n\\n  【1. 推奨: codex-delegate SubAgent】\\n  Task(subagent_type='codex-delegate', prompt='...')\\n\\n  【2. MCP タイムアウト時: CLI フォールバック】\\n  Bash: codex exec '...'\\n\\n  【3. CLI 失敗時: ユーザー確認】\\n  AskUserQuestion を使用して以下を確認:\\n    - 再試行する\\n    - claudecode で代行（executor 変更必須）\\n    - 中止\\n\\n  対象ファイル: $RELATIVE_PATH\\n\\n  参照: docs/executor-fallback-policy.md\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
EOF
            exit 2
            ;;

        coderabbit)
            # V17: フォールバック検出とユーザー確認フローを追加
            cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: coderabbit - Reviewer SubAgent を呼び出してください
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は CodeRabbit によるレビューです。
  Claude Code が直接コードを編集することは許可されていません。

  【1. 推奨: crit Skill】
    Skill(skill='crit') または /crit

  【2. 代替: CodeRabbit CLI】
    Bash: coderabbit review

  【3. CLI 失敗時: ユーザー確認】
    AskUserQuestion を使用して以下を確認:
      - 再試行する
      - reviewer SubAgent で代行
      - 中止

  レビュー後の対応:
    指摘事項は別の Phase（executor: worker）で対応

  参照: docs/executor-fallback-policy.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
        echo "  対象ファイル: $RELATIVE_PATH" >&2
        echo "  現在の executor: $EXECUTOR" >&2
        echo "" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
            exit 2
            ;;

        user)
            # V17: AskUserQuestion による確認フローを強調
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

  【必須: AskUserQuestion で確認】
    1. ユーザーに作業内容を説明
    2. AskUserQuestion で完了確認:
       - 作業完了（次に進む）
       - まだ作業中
       - 作業を中止
    3. 完了確認後に done_criteria をチェック

  executor を変更したい場合:
    AskUserQuestion で確認後、playbook を更新

  参照: docs/executor-fallback-policy.md

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
            # success return removed: fall through to final success exit after warning.
            ;;
    esac
fi

exit 0
