#!/bin/bash
# bash-executor-guard.sh - Bash ツールの executor 強制
#
# 目的: executor: codex/coderabbit/user の Phase で、変更系 Bash コマンドをブロック
# トリガー: PreToolUse(Bash)
#
# 動作:
#   1. Bash コマンドを取得
#   2. 現在の Phase の executor を取得
#   3. executor が claudecode 以外で変更系コマンド → BLOCK
#
# 変更系コマンド（ブロック対象）:
#   - git add, git commit, git push
#   - npm install, npm run build
#   - echo > file, cat > file (リダイレクト)
#   - sed -i, awk (ファイル変更)
#   - rm, mv, cp (ファイル操作)
#
# 読み取り系コマンド（許可）:
#   - cat, head, tail (表示のみ)
#   - ls, tree, find
#   - grep, rg
#   - git status, git log, git diff
#   - npm test, npm run lint

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

# Bash コマンドを取得
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
SKIP_REASON=""
if [[ -z "$COMMAND" ]]; then
    SKIP_REASON="missing command" # success return removed: consolidated skip exit below
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

# 読み取り系コマンドのパターン（常に許可）
READONLY_PATTERNS=(
    "^cat[[:space:]]"
    "^head[[:space:]]"
    "^tail[[:space:]]"
    "^ls"
    "^tree"
    "^find[[:space:]]"
    "^grep"
    "^rg[[:space:]]"
    "^git[[:space:]]status"
    "^git[[:space:]]log"
    "^git[[:space:]]diff"
    "^git[[:space:]]show"
    "^git[[:space:]]branch"
    "^npm[[:space:]]test"
    "^npm[[:space:]]run[[:space:]]lint"
    "^npm[[:space:]]run[[:space:]]test"
    "^echo[[:space:]]"  # echo without redirect is OK
    "^pwd"
    "^which"
    "^type[[:space:]]"
    "^codex[[:space:]]"  # codex commands are OK (they use Codex)
    "^wc[[:space:]]"
    "^sort[[:space:]]"
    "^uniq[[:space:]]"
    "^cut[[:space:]]"
    "^awk[[:space:]]"    # awk without -i is read-only
    "^jq[[:space:]]"
    "^date"
    "^printenv"
)

# 変更系コマンドのパターン（ブロック対象）
MODIFYING_PATTERNS=(
    "^git[[:space:]]add"
    "^git[[:space:]]commit"
    "^git[[:space:]]push"
    "^git[[:space:]]reset"
    "^git[[:space:]]revert"
    "^git[[:space:]]merge"
    "^git[[:space:]]rebase"
    "^git[[:space:]]checkout[[:space:]]"  # checkout with argument
    "^git[[:space:]]restore"
    "^npm[[:space:]]install"
    "^npm[[:space:]]i[[:space:]]"
    "^npm[[:space:]]run[[:space:]]build"
    "^npm[[:space:]]run[[:space:]]dev"
    "^npm[[:space:]]start"
    "^yarn[[:space:]]"
    "^pnpm[[:space:]]"
    "^rm[[:space:]]"
    "^mv[[:space:]]"
    "^cp[[:space:]]"
    "^mkdir[[:space:]]"
    "^touch[[:space:]]"
    "^chmod[[:space:]]"
    "^chown[[:space:]]"
    "^sed[[:space:]]+-i"
)

trim_whitespace() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

strip_command_wrapper() {
    local segment="$1"
    local -a parts
    read -r -a parts <<< "$segment"
    local i=1
    while [[ $i -lt ${#parts[@]} ]]; do
        local token="${parts[$i]}"
        if [[ "$token" == "--" ]]; then
            i=$((i + 1))
            break
        fi
        if [[ "$token" == -* ]]; then
            i=$((i + 1))
            continue
        fi
        break
    done
    printf '%s' "${parts[*]:$i}"
}

strip_env_wrapper() {
    local segment="$1"
    local -a parts
    read -r -a parts <<< "$segment"
    local i=1
    while [[ $i -lt ${#parts[@]} ]]; do
        local token="${parts[$i]}"
        case "$token" in
            --)
                i=$((i + 1))
                break
                ;;
            -u|--unset)
                i=$((i + 2))
                continue
                ;;
            --unset=*)
                i=$((i + 1))
                continue
                ;;
            -*)
                i=$((i + 1))
                continue
                ;;
            *=*)
                i=$((i + 1))
                continue
                ;;
            *)
                break
                ;;
        esac
    done
    printf '%s' "${parts[*]:$i}"
}

strip_time_wrapper() {
    local segment="$1"
    local -a parts
    read -r -a parts <<< "$segment"
    local i=1
    while [[ $i -lt ${#parts[@]} ]]; do
        local token="${parts[$i]}"
        if [[ "$token" == "--" ]]; then
            i=$((i + 1))
            break
        fi
        if [[ "$token" == -* ]]; then
            i=$((i + 1))
            continue
        fi
        break
    done
    printf '%s' "${parts[*]:$i}"
}

normalize_command_segment() {
    local segment
    segment=$(trim_whitespace "$1")
    while [[ -n "$segment" ]]; do
        case "$segment" in
            command|command[[:space:]]*)
                segment=$(strip_command_wrapper "$segment")
                ;;
            env|env[[:space:]]*)
                segment=$(strip_env_wrapper "$segment")
                ;;
            time|time[[:space:]]*)
                segment=$(strip_time_wrapper "$segment")
                ;;
            *)
                break
                ;;
        esac
        segment=$(trim_whitespace "$segment")
    done
    printf '%s' "$segment"
}

has_redirection() {
    local cmd="$1"
    if [[ "$cmd" =~ \>[[:space:]]+\& ]]; then
        return 0
    fi
    if [[ "$cmd" =~ \>\&[^0-9] ]]; then
        return 0
    fi
    if [[ "$cmd" =~ \>\>?[[:space:]]*[^[:space:][:digit:]\&] ]]; then
        return 0
    fi

    if [[ "$cmd" =~ \>\&[0-9] ]]; then
        return 1
    fi

    if [[ "$cmd" =~ \> ]]; then
        return 0
    fi
    return 1
}

is_readonly_command() {
    local cmd="$1"
    for pattern in "${READONLY_PATTERNS[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

is_modifying_command() {
    local cmd="$1"
    for pattern in "${MODIFYING_PATTERNS[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

COMMAND_SEGMENTS="$COMMAND"
COMMAND_SEGMENTS="${COMMAND_SEGMENTS//&&/$'\n'}"
COMMAND_SEGMENTS="${COMMAND_SEGMENTS//||/$'\n'}"
COMMAND_SEGMENTS="${COMMAND_SEGMENTS//;/$'\n'}"

BLOCK_REASON=""
while IFS= read -r segment; do
    segment=$(trim_whitespace "$segment")
    if [[ -z "$segment" ]]; then
        continue
    fi

    NORMALIZED_COMMAND=$(normalize_command_segment "$segment")
    if [[ -z "$NORMALIZED_COMMAND" ]]; then
        BLOCK_REASON="unclassified"
        break
    fi

    if [[ ! "$NORMALIZED_COMMAND" =~ ^codex([[:space:]]|$) ]] && has_redirection "$NORMALIZED_COMMAND"; then
        BLOCK_REASON="redirect"
        break
    fi

    if is_readonly_command "$NORMALIZED_COMMAND"; then
        continue
    fi

    if is_modifying_command "$NORMALIZED_COMMAND"; then
        BLOCK_REASON="modify"
        break
    fi

    BLOCK_REASON="unclassified"
    break
done <<< "$COMMAND_SEGMENTS"

if [[ -n "$BLOCK_REASON" ]]; then
    case "$BLOCK_REASON" in
        redirect)
            cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: $EXECUTOR - ファイル書き込みはブロックされました
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は $EXECUTOR が担当です。
  Claude Code による直接のファイル書き込み（>）は許可されていません。

  ブロックされたコマンド:
    $COMMAND

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

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
            exit 2
            ;;
        modify)
            cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: $EXECUTOR - 変更系コマンドはブロックされました
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は $EXECUTOR が担当です。
  Claude Code による直接の変更系コマンドは許可されていません。

  ブロックされたコマンド:
    $COMMAND

  【1. 推奨: codex-delegate SubAgent】
    Task(subagent_type='codex-delegate', prompt='...')

  【2. MCP タイムアウト時: CLI フォールバック】
    Bash: codex exec '...'

  【3. CLI 失敗時: ユーザー確認】
    AskUserQuestion を使用して以下を確認:
      - 再試行する
      - claudecode で代行（executor 変更必須）
      - 中止

  許可されるコマンド（読み取り系）:
    - cat, head, tail, ls, tree, find
    - grep, rg
    - git status, git log, git diff
    - npm test, npm run lint

  参照: docs/executor-fallback-policy.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
            exit 2
            ;;
        unclassified)
            cat >&2 << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ executor: $EXECUTOR - 未分類コマンドはブロックされました
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  この Phase は $EXECUTOR が担当です。
  判定できないコマンドは安全のためブロックします。

  ブロックされたコマンド:
    $COMMAND

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

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
            exit 2
            ;;
    esac
fi

exit 0
