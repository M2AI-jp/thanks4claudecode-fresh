#!/bin/bash
# ==============================================================================
# generate-implementation-doc.sh - current-implementation.md 自動生成
# ==============================================================================
#
# 目的:
#   - .claude/ 配下の実装状況を自動的にスキャンして current-implementation.md を生成
#   - 手動更新に依存しない Single Source of Truth の維持
#
# 使用方法:
#   bash .claude/hooks/generate-implementation-doc.sh
#
# ==============================================================================

set -e

OUTPUT_FILE="docs/current-implementation.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ==============================================================================
# 1. ヘッダー生成
# ==============================================================================

cat > "$OUTPUT_FILE" << 'EOF'
# current-implementation.md

> **現在の実装状況 - Single Source of Truth**
>
> このファイルは `generate-implementation-doc.sh` によって自動生成されます。
> 手動編集は上書きされる可能性があります。

---

EOF

echo "最終更新: $TIMESTAMP" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# ==============================================================================
# 2. Hooks セクション
# ==============================================================================

cat >> "$OUTPUT_FILE" << 'EOF'
## Hooks

| Hook | トリガー | 役割 |
|------|----------|------|
EOF

# settings.json から Hook 情報を抽出
if [ -f ".claude/settings.json" ]; then
    # SessionStart hooks
    jq -r '.hooks.SessionStart[]?.hooks[]?.command // empty' .claude/settings.json 2>/dev/null | while read cmd; do
        hook_file=$(echo "$cmd" | grep -oE '[^ ]+\.sh' | head -1)
        hook_name=$(basename "$hook_file" .sh 2>/dev/null || echo "$hook_file")
        # Hook ファイルから役割を抽出（コメントの2行目）
        if [ -f "$hook_file" ]; then
            role=$(head -5 "$hook_file" | grep -E "^#.*-" | head -1 | sed 's/^#[^-]*- //' || echo "")
            echo "| $hook_name | SessionStart | $role |" >> "$OUTPUT_FILE"
        fi
    done

    # PreToolUse hooks
    jq -r '.hooks.PreToolUse[]? | "\(.matcher)|\(.hooks[]?.command // empty)"' .claude/settings.json 2>/dev/null | while IFS='|' read matcher cmd; do
        hook_file=$(echo "$cmd" | grep -oE '[^ ]+\.sh' | head -1)
        hook_name=$(basename "$hook_file" .sh 2>/dev/null || echo "$hook_file")
        if [ -f "$hook_file" ]; then
            role=$(head -5 "$hook_file" | grep -E "^#.*-" | head -1 | sed 's/^#[^-]*- //' || echo "")
            echo "| $hook_name | PreToolUse:$matcher | $role |" >> "$OUTPUT_FILE"
        fi
    done

    # PostToolUse hooks
    jq -r '.hooks.PostToolUse[]? | "\(.matcher)|\(.hooks[]?.command // empty)"' .claude/settings.json 2>/dev/null | while IFS='|' read matcher cmd; do
        hook_file=$(echo "$cmd" | grep -oE '[^ ]+\.sh' | head -1)
        hook_name=$(basename "$hook_file" .sh 2>/dev/null || echo "$hook_file")
        if [ -f "$hook_file" ]; then
            role=$(head -5 "$hook_file" | grep -E "^#.*-" | head -1 | sed 's/^#[^-]*- //' || echo "")
            echo "| $hook_name | PostToolUse:$matcher | $role |" >> "$OUTPUT_FILE"
        fi
    done

    # PreCompact hooks
    jq -r '.hooks.PreCompact[]?.hooks[]?.command // empty' .claude/settings.json 2>/dev/null | while read cmd; do
        hook_file=$(echo "$cmd" | grep -oE '[^ ]+\.sh' | head -1)
        hook_name=$(basename "$hook_file" .sh 2>/dev/null || echo "$hook_file")
        if [ -f "$hook_file" ]; then
            role=$(head -5 "$hook_file" | grep -E "^#.*-" | head -1 | sed 's/^#[^-]*- //' || echo "")
            echo "| $hook_name | PreCompact | $role |" >> "$OUTPUT_FILE"
        fi
    done

    # Stop hooks
    jq -r '.hooks.Stop[]?.hooks[]?.command // empty' .claude/settings.json 2>/dev/null | while read cmd; do
        hook_file=$(echo "$cmd" | grep -oE '[^ ]+\.sh' | head -1)
        hook_name=$(basename "$hook_file" .sh 2>/dev/null || echo "$hook_file")
        if [ -f "$hook_file" ]; then
            role=$(head -5 "$hook_file" | grep -E "^#.*-" | head -1 | sed 's/^#[^-]*- //' || echo "")
            echo "| $hook_name | Stop | $role |" >> "$OUTPUT_FILE"
        fi
    done
fi

echo "" >> "$OUTPUT_FILE"

# ==============================================================================
# 3. SubAgents セクション
# ==============================================================================

cat >> "$OUTPUT_FILE" << 'EOF'
---

## SubAgents

| SubAgent | 役割 |
|----------|------|
EOF

if [ -d ".claude/agents" ]; then
    for agent_file in .claude/agents/*.md; do
        if [ -f "$agent_file" ] && [ "$(basename "$agent_file")" != "CLAUDE.md" ]; then
            agent_name=$(basename "$agent_file" .md)
            # ファイルから役割を抽出（最初の > 行）
            role=$(grep -m1 "^>" "$agent_file" 2>/dev/null | sed 's/^> *//' | head -c 80 || echo "")
            echo "| $agent_name | $role |" >> "$OUTPUT_FILE"
        fi
    done
fi

echo "" >> "$OUTPUT_FILE"

# ==============================================================================
# 4. Skills セクション
# ==============================================================================

cat >> "$OUTPUT_FILE" << 'EOF'
---

## Skills

| Skill | 役割 |
|-------|------|
EOF

if [ -d ".claude/skills" ]; then
    for skill_dir in .claude/skills/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            skill_file="${skill_dir}skill.md"
            if [ -f "$skill_file" ]; then
                role=$(grep -m1 "^>" "$skill_file" 2>/dev/null | sed 's/^> *//' | head -c 80 || echo "")
                echo "| $skill_name | $role |" >> "$OUTPUT_FILE"
            fi
        fi
    done
fi

echo "" >> "$OUTPUT_FILE"

# ==============================================================================
# 5. Frameworks セクション
# ==============================================================================

cat >> "$OUTPUT_FILE" << 'EOF'
---

## Frameworks

| Framework | 役割 |
|-----------|------|
EOF

if [ -d ".claude/frameworks" ]; then
    for framework_file in .claude/frameworks/*.md; do
        if [ -f "$framework_file" ] && [ "$(basename "$framework_file")" != "CLAUDE.md" ]; then
            framework_name=$(basename "$framework_file" .md)
            role=$(grep -m1 "^>" "$framework_file" 2>/dev/null | sed 's/^> *//' | head -c 80 || echo "")
            echo "| $framework_name | $role |" >> "$OUTPUT_FILE"
        fi
    done
fi

echo "" >> "$OUTPUT_FILE"

# ==============================================================================
# 6. 設定ファイル情報
# ==============================================================================

cat >> "$OUTPUT_FILE" << 'EOF'
---

## 設定ファイル

| ファイル | 役割 |
|----------|------|
| .claude/settings.json | Hook 登録、権限設定 |
| .claude/protected-files.txt | 保護対象ファイル一覧 |
| state.md | 現在の状態（focus, playbook, goal） |
| plan/project.md | Macro 計画 |

EOF

# ==============================================================================
# 7. 統計情報
# ==============================================================================

HOOK_COUNT=$(ls .claude/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ')
AGENT_COUNT=$(ls .claude/agents/*.md 2>/dev/null | grep -v CLAUDE.md | wc -l | tr -d ' ')
SKILL_COUNT=$(ls -d .claude/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
FRAMEWORK_COUNT=$(ls .claude/frameworks/*.md 2>/dev/null | grep -v CLAUDE.md | wc -l | tr -d ' ')

cat >> "$OUTPUT_FILE" << EOF
---

## 統計

- Hooks: $HOOK_COUNT 個
- SubAgents: $AGENT_COUNT 個
- Skills: $SKILL_COUNT 個
- Frameworks: $FRAMEWORK_COUNT 個

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| $TIMESTAMP | 自動生成 |
EOF

echo "Generated: $OUTPUT_FILE"
