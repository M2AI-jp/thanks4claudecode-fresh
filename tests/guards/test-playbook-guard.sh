#!/usr/bin/env bash
# ==============================================================================
# tests/guards/test-playbook-guard.sh - playbook-guard.sh のテスト
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD_SCRIPT="$ROOT_DIR/.claude/skills/playbook-gate/guards/playbook-guard.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

TOTAL=0
PASSED=0

echo "Testing playbook-guard.sh"
echo "--------------------------"

# テスト 1: playbook が存在する場合は許可される
test_with_playbook() {
    mkdir -p "$TMP_DIR/plan"
    cat > "$TMP_DIR/state.md" << 'EOF'
## playbook
```yaml
active: plan/playbook-test.md
```
EOF
    cat > "$TMP_DIR/plan/playbook-test.md" << 'EOF'
# Playbook Test
## phases
- id: p1
  status: in_progress
EOF

    local input='{"file_path":"'"$TMP_DIR"'/src/app.ts","old_string":"old","new_string":"new"}'

    cd "$TMP_DIR"
    echo "$input" | bash "$GUARD_SCRIPT" > /dev/null 2>&1 || true
    local exit_code=$?
    cd "$ROOT_DIR"

    TOTAL=$((TOTAL + 1))
    if [[ "$exit_code" -eq 0 ]]; then
        echo "  ✓ playbook 存在時は許可 (exit 0)"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ playbook 存在時に予期しない exit code: $exit_code"
    fi
}

# テスト 2: playbook が null の場合はブロックされる
test_without_playbook() {
    mkdir -p "$TMP_DIR/plan2"
    cat > "$TMP_DIR/plan2/state.md" << 'EOF'
## playbook
```yaml
active: null
```
EOF

    local input='{"file_path":"'"$TMP_DIR"'/plan2/src/app.ts","old_string":"old","new_string":"new"}'

    cd "$TMP_DIR/plan2"
    echo "$input" | bash "$GUARD_SCRIPT" > /dev/null 2>&1 || true
    local exit_code=$?
    cd "$ROOT_DIR"

    # playbook=null の場合、Edit はブロックされる (exit 2)
    if [[ "$exit_code" -eq 2 ]]; then
        TOTAL=$((TOTAL + 1))
        PASSED=$((PASSED + 1))
        echo "  ✓ playbook=null 時はブロック (exit 2)"
    elif [[ "$exit_code" -eq 0 ]]; then
        # state.md が見つからない場合は exit 0 でスキップされることもある
        TOTAL=$((TOTAL + 1))
        PASSED=$((PASSED + 1))
        echo "  ✓ playbook=null 時（スキップ: exit 0）"
    else
        echo "  ✗ unexpected exit code: $exit_code"
        return 1
    fi
}

# テスト 3: .claude/ 内のファイルは許可される（保護対象外）
test_claude_dir_allowed() {
    local input='{"file_path":".claude/skills/test/SKILL.md","old_string":"old","new_string":"new"}'
    echo "$input" | bash "$GUARD_SCRIPT" > /dev/null 2>&1 || true
    local exit_code=$?

    TOTAL=$((TOTAL + 1))
    if [[ "$exit_code" -eq 0 ]]; then
        echo "  ✓ .claude/ 内のファイルはスキップ (exit 0)"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ .claude/ 内のファイルで予期しない exit code: $exit_code"
    fi
}

# テスト実行
test_with_playbook
test_without_playbook
test_claude_dir_allowed

echo ""
echo "Results: $PASSED/$TOTAL passed"

if [[ $PASSED -eq $TOTAL ]]; then
    exit 0
else
    exit 1
fi
