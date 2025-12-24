#!/bin/bash
# contract.sh - Contract Validation Core
#
# 全ての契約判定を集約。Hooks はこのスクリプトを呼び出すだけ。
#
# Usage:
#   source scripts/contract.sh
#   contract_check_edit "/path/to/file"   # Edit/Write 用
#   contract_check_bash "command string"  # Bash 用
#
# Exit codes:
#   0 - ALLOW
#   1 - WARN (許可だが警告)
#   2 - BLOCK

# set -euo pipefail  # Disabled to allow sourcing in test scripts

# ==============================================================================
# 定数定義
# ==============================================================================

STATE_FILE="${STATE_FILE:-state.md}"

# HARD_BLOCK ファイル（admin でも回避不可）
HARD_BLOCK_FILES=(
    "CLAUDE.md"
    ".claude/protected-files.txt"
    ".claude/hooks/init-guard.sh"
    ".claude/hooks/critic-guard.sh"
    ".claude/hooks/scope-guard.sh"
    ".claude/hooks/executor-guard.sh"
    ".claude/hooks/playbook-guard.sh"
)

# Maintenance ホワイトリスト（admin + playbook=null で許可）
MAINTENANCE_WHITELIST=(
    "state.md"
    "plan/playbook-*.md"
    "plan/archive/*"
)

# 変更系 Git コマンド（read-only の status/diff/log/show/branch/remote -v 等は除外）
GIT_MUTATION_CMDS='add|commit|push|pull|fetch|reset|checkout|clean|rebase|cherry-pick|revert|stash|apply|am|tag|branch[[:space:]]+-[dDmM]'

# 変更系 Bash パターン（リダイレクトは has_file_redirect で別途検出）
# 注意: このパターンは normalize_command() で前処理された後に適用される
MUTATION_PATTERNS="tee[[:space:]]|sed[[:space:]]+-i|git[[:space:]]+(${GIT_MUTATION_CMDS})|mkdir[[:space:]]|touch[[:space:]]|mv[[:space:]]|cp[[:space:]]|rm[[:space:]]"

# 複合コマンド検出パターン（admin maintenance でも禁止）
COMPOUND_PATTERNS='&&|;|\|\||[|]'

# ==============================================================================
# ヘルパー関数
# ==============================================================================

# コマンドを正規化（誤検出防止）
# /dev/null へのリダイレクトと FD リダイレクト（2>&1, 1>&2）のみを除去
normalize_command() {
    local cmd="$1"
    # /dev/null へのリダイレクトのみ除去（絶対パスは残す）
    # 2>/dev/null, 1>/dev/null, >/dev/null, &>/dev/null, &>>/dev/null
    cmd=$(echo "$cmd" | sed 's/[0-9]*>[[:space:]]*\/dev\/null//g')
    cmd=$(echo "$cmd" | sed 's/&>>[[:space:]]*\/dev\/null//g')
    cmd=$(echo "$cmd" | sed 's/&>[[:space:]]*\/dev\/null//g')
    # FD リダイレクト（2>&1, 1>&2 等）は無害なので除去
    cmd=$(echo "$cmd" | sed 's/[0-9]*>&[0-9]*//g')
    echo "$cmd"
}

# 複合コマンドか判定（&&, ;, ||, | を含む）
is_compound_command() {
    local cmd="$1"
    # パイプ（|）、AND（&&）、OR（||）、セミコロン（;）を検出
    # 注意: 文字列リテラル内の | は誤検出するが、安全側に倒す
    [[ "$cmd" =~ \&\& ]] && return 0
    [[ "$cmd" =~ \|\| ]] && return 0
    [[ "$cmd" == *";"* ]] && return 0
    [[ "$cmd" == *"|"* ]] && return 0
    return 1
}

# ファイルへのリダイレクトがあるか判定（/dev/null以外）
# >, >>, &>, &>> でファイルに書き込む場合を検出
has_file_redirect() {
    local cmd="$1"
    # まず /dev/null へのリダイレクトを除去
    local normalized
    normalized=$(normalize_command "$cmd")
    # 残ったリダイレクト（>, >>, &>, &>>）があれば書き込み
    # パターン: 数字?>、数字?>>、&>、&>>
    if [[ "$normalized" =~ [0-9]*\>[^\>] ]] || \
       [[ "$normalized" =~ [0-9]*\>\> ]] || \
       [[ "$normalized" =~ \&\>[^\>] ]] || \
       [[ "$normalized" =~ \&\>\> ]]; then
        return 0
    fi
    return 1
}

# ==============================================================================
# 状態取得関数
# ==============================================================================

# state.md から値を取得
get_state_value() {
    local key="$1"
    local default="${2:-}"

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "$default"
        return
    fi

    case "$key" in
        playbook)
            grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | \
                grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' '
            ;;
        security)
            grep -A3 "^## config" "$STATE_FILE" 2>/dev/null | \
                grep "security:" | head -1 | sed 's/security: *//' | tr -d ' '
            ;;
        *)
            echo "$default"
            ;;
    esac
}

# ==============================================================================
# 判定関数
# ==============================================================================

# パスが HARD_BLOCK か判定
is_hard_block() {
    local path="$1"
    local relative_path="${path#$PWD/}"

    for blocked in "${HARD_BLOCK_FILES[@]}"; do
        if [[ "$relative_path" == "$blocked" ]]; then
            return 0
        fi
    done
    return 1
}

# パスが Maintenance ホワイトリスト内か判定
is_maintenance_allowed() {
    local path="$1"
    local relative_path="${path#$PWD/}"

    for pattern in "${MAINTENANCE_WHITELIST[@]}"; do
        # shellcheck disable=SC2053
        if [[ "$relative_path" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# パスが playbook ファイルか判定（Bootstrap 例外）
# 注: plan/active/ は廃止済み（2025-12-25）、plan/ 直下のみ許可
is_playbook_file() {
    local path="$1"
    [[ "$path" == *"plan/playbook-"*.md ]]
}

# パスが state.md か判定
is_state_file() {
    local path="$1"
    [[ "$path" == *"state.md" ]]
}

# ==============================================================================
# メイン判定関数
# ==============================================================================

# Edit/Write の契約チェック
# Returns: 0=ALLOW, 1=WARN, 2=BLOCK
# Outputs: エラー/警告メッセージを stderr に出力
contract_check_edit() {
    local file_path="$1"
    local relative_path="${file_path#$PWD/}"

    # Fail-closed: state.md が存在しない場合
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "[FAIL-CLOSED] state.md not found" >&2
        return 2
    fi

    local playbook
    local security
    playbook=$(get_state_value "playbook" "null")
    security=$(get_state_value "security" "strict")

    # 1. HARD_BLOCK チェック（最優先、admin でも回避不可）
    if is_hard_block "$file_path"; then
        cat >&2 <<EOF
========================================
  [HARD_BLOCK] 絶対守護ファイル
========================================

  ファイル: $relative_path

  このファイルは security モードに関係なく
  常に保護されています。

  編集するには直接手動で編集してください。

========================================
EOF
        return 2
    fi

    # 2. Bootstrap 例外: state.md は常に許可
    if is_state_file "$file_path"; then
        return 0
    fi

    # 3. Bootstrap 例外: playbook ファイルは常に許可
    if is_playbook_file "$file_path"; then
        return 0
    fi

    # 4. playbook=null の場合
    if [[ -z "$playbook" || "$playbook" == "null" ]]; then
        # 4a. admin モードで Maintenance ホワイトリスト内なら許可
        if [[ "$security" == "admin" ]] && is_maintenance_allowed "$file_path"; then
            echo "[ADMIN-MAINTENANCE] 許可: $relative_path" >&2
            return 0
        fi

        # 4b. それ以外はブロック
        cat >&2 <<EOF
========================================
  [BLOCK] playbook 必須
========================================

  ファイル: $relative_path
  playbook: null
  security: $security

  playbook=null の状態では編集できません。

  対処法:
    Task(subagent_type='pm', prompt='playbook を作成')

========================================
EOF
        return 2
    fi

    # 5. playbook=active なら許可
    return 0
}

# Admin Maintenance 許可パターン（全体一致 ^...$ で判定）
# 注意: 複合コマンドは Bootstrap 例外チェックで別途処理
ADMIN_MAINTENANCE_PATTERNS=(
    # mkdir -p plan/archive（オプション付きも許可）
    '^mkdir[[:space:]]+(-p[[:space:]]+)?plan/archive/?$'
    # mv plan/playbook-*.md plan/archive/（1ファイルのみ）
    '^mv[[:space:]]+plan/playbook-[^[:space:]]+\.md[[:space:]]+plan/archive/?$'
    # git add state.md（単独）
    '^git[[:space:]]+add[[:space:]]+state\.md$'
    # git add plan/archive/（単独またはファイル指定）
    '^git[[:space:]]+add[[:space:]]+plan/archive(/[^[:space:]]*)?$'
    # git add state.md plan/archive/（2つ同時）
    '^git[[:space:]]+add[[:space:]]+state\.md[[:space:]]+plan/archive/?$'
    # git commit -m "..." (maintenance メッセージ)
    '^git[[:space:]]+commit[[:space:]]+-m[[:space:]]+'
)

# Bootstrap 例外: 複合コマンドでも許可するパターン
# playbook アーカイブ後の最終コミット用
BOOTSTRAP_COMPOUND_PATTERNS=(
    # git add state.md && git commit -m "..."
    '^git[[:space:]]+add[[:space:]]+state\.md[[:space:]]+&&[[:space:]]+git[[:space:]]+commit'
    # git add state.md && git status (確認用)
    '^git[[:space:]]+add[[:space:]]+state\.md[[:space:]]+&&[[:space:]]+git[[:space:]]+status'
)

# Bootstrap 例外: 単独コマンドでも許可（playbook=null + admin）
# 注意: 安全のため、許可する git 操作を明示的にリスト
BOOTSTRAP_SINGLE_PATTERNS=(
    # 読み取り専用 git 操作
    '^git[[:space:]]+(status|diff|log|show|branch|remote|fetch|pull)'
    # git push（main へのマージ完了後に必要）
    '^git[[:space:]]+push'
    # git commit（メンテナンスコミット用）
    '^git[[:space:]]+commit'
    # git merge（PR マージ用）
    '^git[[:space:]]+merge'
    # git checkout（ブランチ切り替え用）
    '^git[[:space:]]+checkout'
    # gh pr create（PR 作成用）
    '^gh[[:space:]]+pr[[:space:]]+create'
    # gh pr merge（PR マージ用）
    '^gh[[:space:]]+pr[[:space:]]+merge'
)

# Admin Maintenance allowlist に一致するか判定
is_admin_maintenance_allowed() {
    local cmd="$1"
    for pattern in "${ADMIN_MAINTENANCE_PATTERNS[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Bootstrap 単独コマンド allowlist に一致するか判定
is_bootstrap_single_allowed() {
    local cmd="$1"
    for pattern in "${BOOTSTRAP_SINGLE_PATTERNS[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Bash コマンドの契約チェック
# Returns: 0=ALLOW, 1=WARN, 2=BLOCK
contract_check_bash() {
    local command="$1"

    # Fail-closed: state.md が存在しない場合
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "[FAIL-CLOSED] state.md not found" >&2
        return 2
    fi

    local playbook
    local security
    playbook=$(get_state_value "playbook" "null")
    security=$(get_state_value "security" "strict")

    # 1. HARD_BLOCK ファイルへの書き込みチェック
    for blocked in "${HARD_BLOCK_FILES[@]}"; do
        if [[ "$command" == *"$blocked"* ]]; then
            # 書き込みパターンを含むか確認
            if [[ "$command" =~ (sed\ -i|>|tee|rm\ ) ]]; then
                cat >&2 <<EOF
========================================
  [HARD_BLOCK] Bash による絶対守護ファイルへの書き込み
========================================

  コマンド: $command
  保護ファイル: $blocked

  HARD_BLOCK ファイルは Bash からも保護されています。

========================================
EOF
                return 2
            fi
        fi
    done

    # 2. コマンドを正規化（誤検出防止）
    local normalized_cmd
    normalized_cmd=$(normalize_command "$command")

    # 3. ファイルへのリダイレクト検出（/dev/null 以外）
    local has_redirect=false
    if has_file_redirect "$command"; then
        has_redirect=true
    fi

    # 4. 変更系コマンドでない、かつリダイレクトもない場合は許可
    if ! [[ "$normalized_cmd" =~ $MUTATION_PATTERNS ]] && [[ "$has_redirect" == "false" ]]; then
        return 0
    fi

    # 5. playbook=null の場合
    if [[ -z "$playbook" || "$playbook" == "null" ]]; then
        # 5a. 複合コマンドは admin でも禁止（注入対策）
        # ただし Bootstrap 例外: state.md と plan/ のみの git 操作は許可
        if is_compound_command "$command"; then
            # Bootstrap 例外チェック: 複合コマンドパターンに一致するか
            if [[ "$security" == "admin" ]]; then
                for pattern in "${BOOTSTRAP_COMPOUND_PATTERNS[@]}"; do
                    if [[ "$command" =~ $pattern ]]; then
                        echo "[ADMIN-MAINTENANCE] 複合コマンド許可（Bootstrap 例外）" >&2
                        return 0
                    fi
                done
            fi

            cat >&2 <<EOF
========================================
  [BLOCK] 複合コマンド禁止
========================================

  コマンド: $command

  &&, ;, ||, | を含むコマンドは
  playbook=null では許可されません。
  （admin モードでも禁止）

  対処法:
    コマンドを分割して個別に実行するか、
    playbook を作成してください。

========================================
EOF
            return 2
        fi

        # 5b. ファイルリダイレクト（/dev/null 以外）は admin でも禁止
        if [[ "$has_redirect" == "true" ]]; then
            cat >&2 <<EOF
========================================
  [BLOCK] ファイルリダイレクト禁止
========================================

  コマンド: $command

  ファイルへの書き込みリダイレクト（>, >>）は
  playbook=null では許可されません。
  （/dev/null へのリダイレクトは許可）

  対処法:
    playbook を作成してください。

========================================
EOF
            return 2
        fi

        # 5c. admin + Maintenance allowlist なら許可
        if [[ "$security" == "admin" ]]; then
            if is_admin_maintenance_allowed "$command"; then
                echo "[ADMIN-MAINTENANCE] 許可: $command" >&2
                return 0
            fi
            # 5c-2. Bootstrap 単独パターン（git push, gh pr 等）も許可
            if is_bootstrap_single_allowed "$command"; then
                echo "[BOOTSTRAP] 許可: $command" >&2
                return 0
            fi
        fi

        # 5d. それ以外はブロック
        cat >&2 <<EOF
========================================
  [BLOCK] playbook=null で変更系 Bash をブロック
========================================

  コマンド: $command
  playbook: null
  security: $security

  playbook=null の状態では変更系コマンドは実行できません。

  対処法:
    Task(subagent_type='pm', prompt='playbook を作成')

========================================
EOF
        return 2
    fi

    # 6. playbook=active なら許可
    return 0
}

# ==============================================================================
# エクスポート（source された場合に使用可能にする）
# ==============================================================================

export -f normalize_command
export -f is_compound_command
export -f has_file_redirect
export -f get_state_value
export -f is_hard_block
export -f is_maintenance_allowed
export -f is_playbook_file
export -f is_state_file
export -f is_admin_maintenance_allowed
export -f is_bootstrap_single_allowed
export -f contract_check_edit
export -f contract_check_bash
