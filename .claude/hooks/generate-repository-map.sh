#!/bin/bash
# ==============================================================================
# generate-repository-map.sh - 全ファイル自動マッピングシステム
# ==============================================================================
#
# 目的:
#   - リポジトリ内の全ファイルをスキャンしてマッピング
#   - カテゴリ・役割を自動抽出
#   - docs/repository-map.yaml として出力
#
# 実行タイミング:
#   - playbook 完了時（cleanup-hook.sh から呼び出し）
#   - 手動実行: bash .claude/hooks/generate-repository-map.sh
#
# 抽出ルール:
#   - .sh ファイル: 先頭コメントから description を抽出
#   - .md ファイル: 最初の > ブロックまたは # の次の行から抽出
#   - settings.json: Hooks のトリガー情報を抽出
#
# ==============================================================================

set -euo pipefail

# 日本語文字列処理のためのエンコーディング設定
export LC_ALL=C
export LANG=C

# ==============================================================================
# 設定
# ==============================================================================
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
OUTPUT_FILE="$PROJECT_ROOT/docs/repository-map.yaml"
TEMP_FILE="$OUTPUT_FILE.tmp"

# 除外パターン
EXCLUDE_PATTERNS=(
    ".git"
    "node_modules"
    ".archive"
    "*.log"
    "*.tmp"
    ".DS_Store"
)

# ==============================================================================
# ユーティリティ関数
# ==============================================================================

# ファイルから description を抽出
extract_description() {
    local file="$1"
    local ext="${file##*.}"
    local desc=""

    case "$ext" in
        sh)
            # シェルスクリプト: 最初の # コメント行から抽出
            desc=$(grep -m1 "^# .*- " "$file" 2>/dev/null | sed 's/^# //' | head -c 80 || echo "")
            ;;
        md)
            # Markdown: > ブロックまたは最初の段落から抽出
            desc=$(grep -m1 "^>" "$file" 2>/dev/null | sed 's/^> \*\*//' | sed 's/\*\*.*//' | head -c 80 || echo "")
            if [[ -z "$desc" ]]; then
                desc=$(sed -n '3p' "$file" 2>/dev/null | head -c 80 || echo "")
            fi
            ;;
        yaml|yml|json)
            # YAML/JSON: description フィールドから抽出
            desc=$(grep -m1 "description:" "$file" 2>/dev/null | sed 's/.*description: *//' | sed 's/"//g' | head -c 80 || echo "")
            ;;
        *)
            desc=""
            ;;
    esac

    # 特殊文字をエスケープ
    echo "$desc" | sed 's/"/\\"/g' | tr -d '\n'
}

# settings.json から Hook のトリガー情報を取得
get_hook_trigger() {
    local hook_name="$1"
    local settings_file="$PROJECT_ROOT/.claude/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        echo ""
        return
    fi

    # jq がある場合は使用
    if command -v jq &> /dev/null; then
        jq -r --arg name "$hook_name" '
            .hooks | to_entries[] |
            select(.value[]?.command | contains($name)) |
            .key + ":" + (.value[] | select(.command | contains($name)) | .matcher // "*")
        ' "$settings_file" 2>/dev/null | head -1 || echo ""
    else
        # jq がない場合は grep で簡易抽出
        grep -B5 "$hook_name" "$settings_file" 2>/dev/null | grep -oE '"(PreToolUse|PostToolUse|SessionStart|Stop|PreCompact)"' | tr -d '"' | head -1 || echo ""
    fi
}

# ファイル数をカウント
count_files() {
    local dir="$1"
    local pattern="$2"
    find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | wc -l | tr -d ' '
}

# ==============================================================================
# メイン処理
# ==============================================================================

echo "Generating repository map..."

# 出力開始
cat > "$TEMP_FILE" << 'HEADER'
# Repository Map
#
# リポジトリ内の全ファイルマッピング（自動生成）
#
# 生成スクリプト: .claude/hooks/generate-repository-map.sh
# 更新タイミング: playbook 完了時
#
# このファイルは自動生成されます。手動編集は上書きされます。

HEADER

# メタ情報
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TOTAL_FILES=$(find "$PROJECT_ROOT" -type f \
    ! -path "*/.git/*" \
    ! -path "*/.archive/*" \
    ! -path "*/node_modules/*" \
    ! -name "*.log" \
    ! -name ".DS_Store" \
    2>/dev/null | wc -l | tr -d ' ')

cat >> "$TEMP_FILE" << EOF
meta:
  generated: "$TIMESTAMP"
  generator: ".claude/hooks/generate-repository-map.sh"
  total_files: $TOTAL_FILES

EOF

# ==============================================================================
# Hooks
# ==============================================================================
echo "  Scanning hooks..."
HOOKS_DIR="$PROJECT_ROOT/.claude/hooks"
HOOKS_COUNT=$(count_files "$HOOKS_DIR" "*.sh")

cat >> "$TEMP_FILE" << EOF
hooks:
  directory: .claude/hooks/
  count: $HOOKS_COUNT
  files:
EOF

if [[ -d "$HOOKS_DIR" ]]; then
    for hook in "$HOOKS_DIR"/*.sh; do
        [[ -f "$hook" ]] || continue
        name=$(basename "$hook")
        desc=$(extract_description "$hook")
        trigger=$(get_hook_trigger "$name")

        cat >> "$TEMP_FILE" << EOF
    - name: "$name"
      trigger: "${trigger:-unknown}"
      description: "$desc"
EOF
    done
fi

# ==============================================================================
# SubAgents
# ==============================================================================
echo "  Scanning agents..."
AGENTS_DIR="$PROJECT_ROOT/.claude/agents"
AGENTS_COUNT=$(count_files "$AGENTS_DIR" "*.md")

cat >> "$TEMP_FILE" << EOF

agents:
  directory: .claude/agents/
  count: $AGENTS_COUNT
  files:
EOF

if [[ -d "$AGENTS_DIR" ]]; then
    for agent in "$AGENTS_DIR"/*.md; do
        [[ -f "$agent" ]] || continue
        name=$(basename "$agent" .md)
        [[ "$name" == "CLAUDE" ]] && continue  # CLAUDE.md は除外
        desc=$(extract_description "$agent")

        cat >> "$TEMP_FILE" << EOF
    - name: "$name"
      description: "$desc"
EOF
    done
fi

# ==============================================================================
# Skills
# ==============================================================================
echo "  Scanning skills..."
SKILLS_DIR="$PROJECT_ROOT/.claude/skills"
SKILLS_COUNT=0

cat >> "$TEMP_FILE" << EOF

skills:
  directory: .claude/skills/
EOF

if [[ -d "$SKILLS_DIR" ]]; then
    skills_list=()
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        skill_name=$(basename "$skill_dir")
        skill_file=""

        # SKILL.md または skill.md を探す
        if [[ -f "$skill_dir/SKILL.md" ]]; then
            skill_file="$skill_dir/SKILL.md"
        elif [[ -f "$skill_dir/skill.md" ]]; then
            skill_file="$skill_dir/skill.md"
        fi

        if [[ -n "$skill_file" ]]; then
            ((SKILLS_COUNT++))
            desc=$(extract_description "$skill_file")
            skills_list+=("    - name: \"$skill_name\"\n      description: \"$desc\"")
        fi
    done

    echo "  count: $SKILLS_COUNT" >> "$TEMP_FILE"
    echo "  files:" >> "$TEMP_FILE"
    for item in "${skills_list[@]}"; do
        echo -e "$item" >> "$TEMP_FILE"
    done
fi

# ==============================================================================
# Frameworks
# ==============================================================================
echo "  Scanning frameworks..."
FRAMEWORKS_DIR="$PROJECT_ROOT/.claude/rules/frameworks"
FRAMEWORKS_COUNT=0

cat >> "$TEMP_FILE" << EOF

frameworks:
  directory: .claude/rules/frameworks/
EOF

if [[ -d "$FRAMEWORKS_DIR" ]]; then
    FRAMEWORKS_COUNT=$(count_files "$FRAMEWORKS_DIR" "*.md")
    echo "  count: $FRAMEWORKS_COUNT" >> "$TEMP_FILE"
    echo "  files:" >> "$TEMP_FILE"

    for fw in "$FRAMEWORKS_DIR"/*.md; do
        [[ -f "$fw" ]] || continue
        name=$(basename "$fw" .md)
        [[ "$name" == "CLAUDE" ]] && continue
        desc=$(extract_description "$fw")

        cat >> "$TEMP_FILE" << EOF
    - name: "$name"
      description: "$desc"
EOF
    done
else
    echo "  count: 0" >> "$TEMP_FILE"
    echo "  files: []" >> "$TEMP_FILE"
fi

# ==============================================================================
# Commands
# ==============================================================================
echo "  Scanning commands..."
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
COMMANDS_COUNT=$(count_files "$COMMANDS_DIR" "*.md")

cat >> "$TEMP_FILE" << EOF

commands:
  directory: .claude/commands/
  count: $COMMANDS_COUNT
  files:
EOF

if [[ -d "$COMMANDS_DIR" ]]; then
    for cmd in "$COMMANDS_DIR"/*.md; do
        [[ -f "$cmd" ]] || continue
        name=$(basename "$cmd" .md)
        desc=$(extract_description "$cmd")

        cat >> "$TEMP_FILE" << EOF
    - name: "/$name"
      description: "$desc"
EOF
    done
fi

# ==============================================================================
# Docs
# ==============================================================================
echo "  Scanning docs..."
DOCS_DIR="$PROJECT_ROOT/docs"
DOCS_COUNT=$(count_files "$DOCS_DIR" "*.md")
DOCS_YAML_COUNT=$(count_files "$DOCS_DIR" "*.yaml")
DOCS_TOTAL=$((DOCS_COUNT + DOCS_YAML_COUNT))

cat >> "$TEMP_FILE" << EOF

docs:
  directory: docs/
  count: $DOCS_TOTAL
  files:
EOF

if [[ -d "$DOCS_DIR" ]]; then
    for doc in "$DOCS_DIR"/*.md "$DOCS_DIR"/*.yaml; do
        [[ -f "$doc" ]] || continue
        name=$(basename "$doc")
        [[ "$name" == "repository-map.yaml" ]] && continue  # 自身は除外
        desc=$(extract_description "$doc")

        cat >> "$TEMP_FILE" << EOF
    - name: "$name"
      description: "$desc"
EOF
    done
fi

# ==============================================================================
# Plan
# ==============================================================================
echo "  Scanning plan..."
PLAN_DIR="$PROJECT_ROOT/plan"

cat >> "$TEMP_FILE" << EOF

plan:
  directory: plan/
  subdirectories:
    active:
      description: "進行中の playbook"
EOF

ACTIVE_COUNT=$(find "$PLAN_DIR/active" -maxdepth 1 -name "playbook-*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "      count: $ACTIVE_COUNT" >> "$TEMP_FILE"

cat >> "$TEMP_FILE" << EOF
    archive:
      description: "完了した playbook のアーカイブ"
EOF

ARCHIVE_COUNT=$(find "$PLAN_DIR/archive" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "      count: $ARCHIVE_COUNT" >> "$TEMP_FILE"

cat >> "$TEMP_FILE" << EOF
    template:
      description: "playbook テンプレート"
EOF

TEMPLATE_COUNT=$(count_files "$PLAN_DIR/template" "*.md")
echo "      count: $TEMPLATE_COUNT" >> "$TEMP_FILE"

# ==============================================================================
# Root Files
# ==============================================================================
echo "  Scanning root files..."

cat >> "$TEMP_FILE" << EOF

root:
  description: "ルートディレクトリの主要ファイル"
  files:
EOF

for root_file in CLAUDE.md AGENTS.md README.md state.md .gitignore .mcp.json; do
    if [[ -f "$PROJECT_ROOT/$root_file" ]]; then
        desc=$(extract_description "$PROJECT_ROOT/$root_file")
        cat >> "$TEMP_FILE" << EOF
    - name: "$root_file"
      description: "$desc"
EOF
    fi
done

# ==============================================================================
# 統計サマリー
# ==============================================================================
cat >> "$TEMP_FILE" << EOF

summary:
  hooks: $HOOKS_COUNT
  agents: $AGENTS_COUNT
  skills: $SKILLS_COUNT
  frameworks: $FRAMEWORKS_COUNT
  commands: $COMMANDS_COUNT
  docs: $DOCS_TOTAL
  plan_active: $ACTIVE_COUNT
  plan_archive: $ARCHIVE_COUNT
  plan_template: $TEMPLATE_COUNT
  total: $TOTAL_FILES

# ==============================================================================
# 変更履歴
# ==============================================================================
changelog:
  - date: "$TIMESTAMP"
    action: "auto-generated"
    description: "playbook 完了時に自動生成"
EOF

# 出力ファイルを更新
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "Repository map generated: $OUTPUT_FILE"
echo "  Total files: $TOTAL_FILES"
echo "  Hooks: $HOOKS_COUNT | Agents: $AGENTS_COUNT | Skills: $SKILLS_COUNT"
