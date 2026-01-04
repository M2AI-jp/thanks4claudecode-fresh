#!/bin/bash
# chain.sh - event unit: post-tool-edit
# Current: wrapper for archive/cleanup/PR workflow.

set -euo pipefail

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$EVENT_DIR/../.." && pwd)"
SKILLS_DIR="$CLAUDE_DIR/skills"

INPUT=$(cat)

invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        echo "$INPUT" | bash "$path" || true
    fi
}

# playbook 完了チェック・アーカイブ
invoke_skill "playbook-gate" "workflow/archive-playbook.sh"
# クリーンアップ
invoke_skill "playbook-gate" "workflow/cleanup.sh"
# PR 作成提案
invoke_skill "git-workflow" "handlers/create-pr-hook.sh"

exit 0
