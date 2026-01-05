#!/bin/bash
# pre-tool.sh - PreToolUse(*) 導火線
# 適切な Skills を順次呼び出す

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
EVENTS_DIR="$SCRIPT_DIR/../events"
LIB_DIR="$SCRIPT_DIR/../lib"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTRACT_SCRIPT="$REPO_ROOT/scripts/contract.sh"
MARKER_FILE="$SCRIPT_DIR/../session-state/prompt-analyzer-called"
MARKER_DIR="$(dirname "$MARKER_FILE")"

# セッション状態ディレクトリを確保
mkdir -p "$MARKER_DIR"

# 共通ライブラリ読み込み
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

# 入力を読み込み
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# === prompt-analyzer 強制ガード ===
# マーカーがない場合、prompt-analyzer 以外をブロック（読み取り系は例外）
if [[ ! -f "$MARKER_FILE" ]]; then
    ALLOW_WITHOUT_ANALYZER=false
    BLOCK_DETAIL=""

    case "$TOOL_NAME" in
        Task)
            SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')
            BLOCK_DETAIL="subagent=$SUBAGENT_TYPE"
            if [[ "$SUBAGENT_TYPE" == "prompt-analyzer" ]]; then
                # prompt-analyzer → マーカー作成して許可
                touch "$MARKER_FILE"
                ALLOW_WITHOUT_ANALYZER=true
            fi
            ;;
        Skill)
            SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // .tool_input.name // .tool_input.skill_name // empty')
            BLOCK_DETAIL="skill=$SKILL_NAME"
            if [[ "$SKILL_NAME" == "prompt-analyzer" ]]; then
                # Skill(prompt-analyzer) → マーカー作成して許可
                touch "$MARKER_FILE"
                ALLOW_WITHOUT_ANALYZER=true
            elif [[ "$SKILL_NAME" == "playbook-init" ]]; then
                # playbook-init は prompt-analyzer を内包するため許可
                ALLOW_WITHOUT_ANALYZER=true
            fi
            ;;
        Read|Grep|Glob)
            ALLOW_WITHOUT_ANALYZER=true
            ;;
        Bash)
            # 変更系 Bash を防ぐため、契約チェックで read-only を判定
            COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
            if [[ -f "$CONTRACT_SCRIPT" ]]; then
                # shellcheck source=../../scripts/contract.sh
                source "$CONTRACT_SCRIPT"
                if contract_check_bash "$COMMAND"; then
                    ALLOW_WITHOUT_ANALYZER=true
                else
                    exit 2
                fi
            fi
            ;;
    esac

    if [[ "$ALLOW_WITHOUT_ANALYZER" != "true" ]]; then
        if [[ -n "$BLOCK_DETAIL" ]]; then
            echo "BLOCK: prompt-analyzer を先に呼び出してください (tool=$TOOL_NAME, $BLOCK_DETAIL)" >&2
        else
            echo "BLOCK: prompt-analyzer を先に呼び出してください (tool=$TOOL_NAME)" >&2
        fi
        exit 2
    fi
fi

# Skill を呼び出す関数
invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        echo "$INPUT" | bash "$path"
        return $?
    fi
    return 0
}

invoke_event_chain() {
    local unit="$1"
    local path="$EVENTS_DIR/$unit/chain.sh"
    if [[ -f "$path" ]]; then
        echo "$INPUT" | bash "$path"
        return $?
    fi
    return 0
}

# 1. session-manager: init-guard（全ツール共通）
invoke_skill "session-manager" "handlers/init-guard.sh" || exit $?

# 2. access-control: ブランチチェック
invoke_skill "access-control" "guards/main-branch.sh" || exit $?

case "$TOOL_NAME" in
    Edit|Write)
        invoke_event_chain "pre-tool-edit" || exit $?
        ;;
    Bash)
        invoke_event_chain "pre-tool-bash" || exit $?
        ;;
esac

exit 0
