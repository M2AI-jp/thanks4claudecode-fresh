#!/bin/bash
# task-executor-guard.sh - Task ツールの executor 強制
#
# 目的: executor: codex の Phase で、codex-delegate 以外の SubAgent 呼び出しをブロック
# トリガー: PreToolUse(Task)
#
# 動作:
#   1. Task ツールの subagent_type を取得
#   2. 現在の Phase の executor を取得
#   3. executor: codex で subagent_type != codex-delegate → BLOCK
#   4. executor: coderabbit で subagent_type != reviewer → BLOCK
#
# 例外:
#   - executor: claudecode → 全ての SubAgent 許可
#   - Explore, general-purpose 等の調査系 SubAgent は常に許可

set -uo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# ============================================================
# Toolstack 取得
# ============================================================
TOOLSTACK="A"  # デフォルト
if [ -f "$STATE_FILE" ]; then
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

# subagent_type を取得
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // ""')
SKIP_REASON=""
if [[ -z "$SUBAGENT_TYPE" ]]; then
    SKIP_REASON="missing subagent_type" # success return removed: consolidated skip exit below
fi

# 常に許可する SubAgent（調査・分析系）
ALWAYS_ALLOWED="Explore general-purpose claude-code-guide health-checker"
ALWAYS_ALLOWED_MATCH=false
if [[ -z "$SKIP_REASON" ]]; then
    for allowed in $ALWAYS_ALLOWED; do
        if [[ "$SUBAGENT_TYPE" == "$allowed" ]]; then
            ALWAYS_ALLOWED_MATCH=true
            break
        fi
    done
fi
if [[ "$ALWAYS_ALLOWED_MATCH" == true ]]; then
    SKIP_REASON="always-allowed subagent" # success return removed: consolidated skip exit below
fi

if [[ -z "$SKIP_REASON" && ! -f "$STATE_FILE" ]]; then
    SKIP_REASON="state.md missing" # success return removed: consolidated skip exit below
fi

if [[ -z "$SKIP_REASON" ]]; then
    # playbook から active を取得
    PLAYBOOK_PATH=$(grep -A8 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ' || true)

    if [[ -z "$PLAYBOOK_PATH" || "$PLAYBOOK_PATH" == "null" ]]; then
        SKIP_REASON="playbook not set" # success return removed: consolidated skip exit below
    elif [[ ! -f "$PLAYBOOK_PATH" ]]; then
        SKIP_REASON="playbook file missing" # success return removed: consolidated skip exit below
    else
        # playbook から in_progress の Phase を探す
        IN_PROGRESS_LINE=$(grep -n -E "(status:|\\*\\*status\\*\\*:).*in_progress" "$PLAYBOOK_PATH" 2>/dev/null | head -1 || echo "")
        if [[ -z "$IN_PROGRESS_LINE" ]]; then
            SKIP_REASON="no in_progress phase" # success return removed: consolidated skip exit below
        else
            # その Phase の executor を取得
            LINE_NUM=$(echo "$IN_PROGRESS_LINE" | cut -d: -f1)
            EXECUTOR=""
            for i in $(seq "$LINE_NUM" -1 1); do
                LINE=$(sed -n "${i}p" "$PLAYBOOK_PATH")
                if [[ "$LINE" =~ ^[[:space:]]*-?[[:space:]]*executor:[[:space:]]*(.+)$ ]]; then
                    EXECUTOR=$(echo "${BASH_REMATCH[1]}" | tr -d ' ')
                    break
                fi
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

if [[ -n "$SKIP_REASON" ]]; then
    # success return consolidated: multiple skip paths return here to reduce redundant exits.
    exit 0
fi

# executor 別のチェック
case "$EXECUTOR" in
    codex)
        # codex の Phase では codex-delegate のみ許可
        # V17: フォールバック検出とユーザー確認フローを追加
        if [[ "$SUBAGENT_TYPE" != "codex-delegate" ]]; then
            cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: codex - codex-delegate SubAgent を使用してください
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は Codex が担当です。
  SubAgent '$SUBAGENT_TYPE' は許可されていません。

  【1. 推奨: codex-delegate SubAgent】
    Task(subagent_type='codex-delegate', prompt='...')

  【2. MCP タイムアウト時: CLI フォールバック】
    Bash: codex exec '...'

  【3. CLI 失敗時: ユーザー確認】
    AskUserQuestion を使用して以下を確認:
      - 再試行する
      - claudecode で代行（executor 変更必須）
      - 中止

  参照: docs/executor-fallback-policy.md

  現在の executor: $EXECUTOR
  要求された SubAgent: $SUBAGENT_TYPE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
            exit 2
        fi
        ;;
    coderabbit)
        # coderabbit の Phase では reviewer のみ許可
        # V17: フォールバック検出とユーザー確認フローを追加
        if [[ "$SUBAGENT_TYPE" != "reviewer" ]]; then
            cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: coderabbit - reviewer SubAgent を使用してください
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は CodeRabbit によるレビューです。
  SubAgent '$SUBAGENT_TYPE' は許可されていません。

  【1. 推奨: reviewer SubAgent】
    Task(subagent_type='reviewer', prompt='...')

  【2. 代替: crit Skill】
    Skill(skill='crit') または /crit

  【3. CLI 失敗時: ユーザー確認】
    AskUserQuestion を使用して以下を確認:
      - 再試行する
      - claudecode でレビュー代行
      - 中止

  参照: docs/executor-fallback-policy.md

  現在の executor: $EXECUTOR
  要求された SubAgent: $SUBAGENT_TYPE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
            exit 2
        fi
        ;;
    user)
        # user の Phase では SubAgent 呼び出し自体を警告
        # V17: AskUserQuestion による確認フローを強調
        cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⚠️ executor: user - ユーザー作業の Phase です
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase はユーザーが手動で行う作業です。
  SubAgent '$SUBAGENT_TYPE' の呼び出しは推奨されません。

  【必須: AskUserQuestion で確認】
    1. ユーザーに作業内容を説明
    2. AskUserQuestion で完了確認:
       - 作業完了（次に進む）
       - まだ作業中
       - 作業を中止
    3. 完了確認後に done_criteria をチェック

  参照: docs/executor-fallback-policy.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
        # 警告のみ、ブロックはしない
        # success return removed: fall through to final success exit after warning.
        ;;
esac

exit 0
