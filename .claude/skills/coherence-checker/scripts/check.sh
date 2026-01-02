#!/usr/bin/env bash
# coherence-checker: ARCHITECTURE.md と実装の整合性チェック
# Usage: bash .claude/skills/coherence-checker/scripts/check.sh

set -euo pipefail

# 定数定義
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ARCHITECTURE_FILE="$REPO_ROOT/docs/ARCHITECTURE.md"
HOOKS_DIR="$REPO_ROOT/.claude/hooks"
SKILLS_DIR="$REPO_ROOT/.claude/skills"

# カウンター
VERIFIED=0
INCONSISTENT=0
MISSING=0

# 結果格納用配列
declare -a HOOK_RESULTS=()
declare -a SKILL_RESULTS=()
declare -a SUBAGENT_RESULTS=()
declare -a RECOMMENDATIONS=()

# ARCHITECTURE.md が存在するか確認
if [[ ! -f "$ARCHITECTURE_FILE" ]]; then
    echo "coherence_check:"
    echo "  error: \"ARCHITECTURE.md not found at $ARCHITECTURE_FILE\""
    exit 1
fi

# ARCHITECTURE.md の内容をキャッシュ
ARCH_CONTENT=$(cat "$ARCHITECTURE_FILE")

# === ユーティリティ関数 ===

# ファイル名を説明に変換（ハイフンをスペースに）
filename_to_description() {
    local filename="$1"
    echo "$filename" | tr '-' ' '
}

# === Severity 判定ロジック ===
# p5.1: severity 判定
#   missing（実装あり、ドキュメントなし）→ low（ドキュメント追記で解決）
#   inconsistent（ドキュメントあり、実装なし）→ medium/high（実装が必要）
get_severity() {
    local status="$1"
    local item_type="$2"  # hook, skill, subagent
    
    case "$status" in
        missing)
            echo "low"
            ;;
        inconsistent)
            # Skill/SubAgent は medium（影響範囲が広い可能性）
            # Hook は medium（単一ファイル）
            echo "medium"
            ;;
        *)
            echo "none"
            ;;
    esac
}

# === 自動修正提案生成 ===
# p5.2: severity: low の場合の auto_fix 生成
generate_auto_fix_hook() {
    local file_path="$1"
    local filename
    filename=$(basename "$file_path" .sh)
    local description
    description=$(filename_to_description "$filename")
    
    # ファイル名からセクション推測
    local section=""
    case "$filename" in
        session-start)
            section="Section 1. SessionStart"
            ;;
        generate-repository-map)
            section="Section 13. 補助モジュール"
            ;;
        *)
            section="Section 13. 補助モジュール"
            ;;
    esac
    
    echo "      auto_fix:"
    echo "        action: \"add_to_architecture\""
    echo "        section: \"$section\""
    echo "        content: |"
    echo "          ### $filename.sh"
    echo "          $description Hook の処理"
    echo "          "
    echo "          \`\`\`"
    echo "          .claude/hooks/$filename.sh"
    echo "          \`\`\`"
}

generate_auto_fix_skill() {
    local dir_path="$1"
    local dirname
    dirname=$(basename "$dir_path")
    
    echo "      auto_fix:"
    echo "        action: \"add_to_architecture\""
    echo "        section: \"Section 8. Skills 一覧と内部構成\""
    echo "        content: |"
    echo "          ### $dirname/"
    echo "          "
    echo "          - SKILL.md: $dirname Skill 定義"
}

generate_auto_fix_subagent() {
    local file_path="$1"
    local filename
    filename=$(basename "$file_path" .md)
    local skill_dir
    skill_dir=$(echo "$file_path" | sed 's|.claude/skills/\([^/]*\)/.*|\1|')
    
    echo "      auto_fix:"
    echo "        action: \"add_to_architecture\""
    echo "        section: \"Section 7. SubAgent 呼び出し\""
    echo "        content: |"
    echo "          ### $filename SubAgent"
    echo "          "
    echo "          - 定義: $file_path"
    echo "          - 親 Skill: $skill_dir"
}

# === 提案生成（severity: medium/high） ===
# p5.3: inconsistent の提案出力
generate_suggestion_hook() {
    local file_path="$1"
    local filename
    filename=$(basename "$file_path" .sh)
    
    echo "      suggestion:"
    echo "        problem: \"ARCHITECTURE.md に記載があるが実装が存在しない\""
    echo "        action: \"implement_or_remove_reference\""
    echo "        reason: \"ドキュメントと実装の整合性を保つために対応が必要\""
    echo "        options:"
    echo "          - \"$filename.sh を実装する\""
    echo "          - \"ARCHITECTURE.md から $file_path の参照を削除する\""
}

generate_suggestion_skill() {
    local dir_path="$1"
    local dirname
    dirname=$(basename "$dir_path")
    
    echo "      suggestion:"
    echo "        problem: \"ARCHITECTURE.md に記載があるがディレクトリが存在しない\""
    echo "        action: \"implement_or_remove_reference\""
    echo "        reason: \"ドキュメントと実装の整合性を保つために対応が必要\""
    echo "        options:"
    echo "          - \"$dirname Skill を実装する\""
    echo "          - \"ARCHITECTURE.md から $dir_path の参照を削除する\""
}

generate_suggestion_subagent() {
    local file_path="$1"
    local filename
    filename=$(basename "$file_path" .md)
    
    echo "      suggestion:"
    echo "        problem: \"ARCHITECTURE.md に記載があるがファイルが存在しない\""
    echo "        action: \"implement_or_remove_reference\""
    echo "        reason: \"ドキュメントと実装の整合性を保つために対応が必要\""
    echo "        options:"
    echo "          - \"$filename SubAgent を実装する\""
    echo "          - \"ARCHITECTURE.md から $file_path の参照を削除する\""
}

# === Hook 整合性チェック ===

# ARCHITECTURE.md から Hook ファイルパスを抽出
# パターン: .claude/hooks/*.sh
extract_hooks_from_arch() {
    echo "$ARCH_CONTENT" | grep -oE '\.claude/hooks/[a-zA-Z0-9_-]+\.sh' | sort -u
}

# 実際の Hook ファイル一覧
get_actual_hooks() {
    if [[ -d "$HOOKS_DIR" ]]; then
        find "$HOOKS_DIR" -maxdepth 1 -name "*.sh" -type f | sed "s|$REPO_ROOT/||" | sort -u
    fi
}

check_hooks() {
    local arch_hooks
    local actual_hooks
    
    arch_hooks=$(extract_hooks_from_arch)
    actual_hooks=$(get_actual_hooks)
    
    # ARCHITECTURE.md に記載されている Hook をチェック
    while IFS= read -r hook; do
        [[ -z "$hook" ]] && continue
        local full_path="$REPO_ROOT/$hook"
        if [[ -f "$full_path" ]]; then
            HOOK_RESULTS+=("    - file: \"$hook\"")
            HOOK_RESULTS+=("      status: verified")
            HOOK_RESULTS+=("      note: \"exists in both ARCHITECTURE.md and filesystem\"")
            ((VERIFIED++))
        else
            HOOK_RESULTS+=("    - file: \"$hook\"")
            HOOK_RESULTS+=("      status: inconsistent")
            HOOK_RESULTS+=("      note: \"documented in ARCHITECTURE.md but file does not exist\"")
            ((INCONSISTENT++))
            # p5.3: 提案生成
            RECOMMENDATIONS+=("    - severity: medium")
            RECOMMENDATIONS+=("      type: inconsistent")
            RECOMMENDATIONS+=("      target: \"$hook\"")
            while IFS= read -r line; do
                RECOMMENDATIONS+=("$line")
            done <<< "$(generate_suggestion_hook "$hook")"
        fi
    done <<< "$arch_hooks"
    
    # 実装にあるが ARCHITECTURE.md にない Hook をチェック
    while IFS= read -r hook; do
        [[ -z "$hook" ]] && continue
        if ! echo "$arch_hooks" | grep -qF "$hook"; then
            HOOK_RESULTS+=("    - file: \"$hook\"")
            HOOK_RESULTS+=("      status: missing")
            HOOK_RESULTS+=("      note: \"exists in filesystem but not documented in ARCHITECTURE.md\"")
            ((MISSING++))
            # p5.2: 自動修正提案生成
            RECOMMENDATIONS+=("    - severity: low")
            RECOMMENDATIONS+=("      type: missing")
            RECOMMENDATIONS+=("      target: \"$hook\"")
            while IFS= read -r line; do
                RECOMMENDATIONS+=("$line")
            done <<< "$(generate_auto_fix_hook "$hook")"
        fi
    done <<< "$actual_hooks"
}

# === Skill 整合性チェック ===

# ARCHITECTURE.md から Skill ディレクトリパスを抽出
# パターン: .claude/skills/xxx/ または Section 8 の見出し
extract_skills_from_arch() {
    # Section 8 の見出しパターン: ### xxx/
    echo "$ARCH_CONTENT" | grep -E '^### [a-zA-Z0-9_-]+/$' | sed 's/### //' | sed 's|/$||' | while read -r skill; do
        echo ".claude/skills/$skill"
    done
    # その他のパスパターンも抽出
    echo "$ARCH_CONTENT" | grep -oE '\.claude/skills/[a-zA-Z0-9_-]+/' | sed 's|/$||' | sort -u
}

# 実際の Skill ディレクトリ一覧
get_actual_skills() {
    if [[ -d "$SKILLS_DIR" ]]; then
        find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | sed "s|$REPO_ROOT/||" | sort -u
    fi
}

check_skills() {
    local arch_skills
    local actual_skills
    
    arch_skills=$(extract_skills_from_arch | sort -u)
    actual_skills=$(get_actual_skills)
    
    # ARCHITECTURE.md に記載されている Skill をチェック
    while IFS= read -r skill; do
        [[ -z "$skill" ]] && continue
        local full_path="$REPO_ROOT/$skill"
        local skill_md="$full_path/SKILL.md"
        if [[ -d "$full_path" ]]; then
            local has_skill_md="false"
            if [[ -f "$skill_md" ]]; then
                has_skill_md="true"
            fi
            SKILL_RESULTS+=("    - dir: \"$skill/\"")
            SKILL_RESULTS+=("      status: verified")
            SKILL_RESULTS+=("      has_skill_md: $has_skill_md")
            SKILL_RESULTS+=("      note: \"exists in both ARCHITECTURE.md and filesystem\"")
            ((VERIFIED++))
        else
            SKILL_RESULTS+=("    - dir: \"$skill/\"")
            SKILL_RESULTS+=("      status: inconsistent")
            SKILL_RESULTS+=("      has_skill_md: false")
            SKILL_RESULTS+=("      note: \"documented in ARCHITECTURE.md but directory does not exist\"")
            ((INCONSISTENT++))
            # p5.3: 提案生成
            RECOMMENDATIONS+=("    - severity: medium")
            RECOMMENDATIONS+=("      type: inconsistent")
            RECOMMENDATIONS+=("      target: \"$skill/\"")
            while IFS= read -r line; do
                RECOMMENDATIONS+=("$line")
            done <<< "$(generate_suggestion_skill "$skill")"
        fi
    done <<< "$arch_skills"
    
    # 実装にあるが ARCHITECTURE.md にない Skill をチェック
    while IFS= read -r skill; do
        [[ -z "$skill" ]] && continue
        if ! echo "$arch_skills" | grep -qF "$skill"; then
            local skill_md="$REPO_ROOT/$skill/SKILL.md"
            local has_skill_md="false"
            if [[ -f "$skill_md" ]]; then
                has_skill_md="true"
            fi
            SKILL_RESULTS+=("    - dir: \"$skill/\"")
            SKILL_RESULTS+=("      status: missing")
            SKILL_RESULTS+=("      has_skill_md: $has_skill_md")
            SKILL_RESULTS+=("      note: \"exists in filesystem but not documented in ARCHITECTURE.md\"")
            ((MISSING++))
            # p5.2: 自動修正提案生成
            RECOMMENDATIONS+=("    - severity: low")
            RECOMMENDATIONS+=("      type: missing")
            RECOMMENDATIONS+=("      target: \"$skill/\"")
            while IFS= read -r line; do
                RECOMMENDATIONS+=("$line")
            done <<< "$(generate_auto_fix_skill "$skill")"
        fi
    done <<< "$actual_skills"
}

# === SubAgent 整合性チェック ===

# ARCHITECTURE.md から SubAgent ファイルパスを抽出
# パターン: .claude/skills/*/agents/*.md
extract_subagents_from_arch() {
    echo "$ARCH_CONTENT" | grep -oE '\.claude/skills/[a-zA-Z0-9_-]+/agents/[a-zA-Z0-9_-]+\.md' | sort -u
}

# 実際の SubAgent ファイル一覧
get_actual_subagents() {
    find "$SKILLS_DIR" -path "*/agents/*.md" -type f 2>/dev/null | sed "s|$REPO_ROOT/||" | sort -u
}

check_subagents() {
    local arch_subagents
    local actual_subagents
    
    arch_subagents=$(extract_subagents_from_arch)
    actual_subagents=$(get_actual_subagents)
    
    # ARCHITECTURE.md に記載されている SubAgent をチェック
    while IFS= read -r subagent; do
        [[ -z "$subagent" ]] && continue
        local full_path="$REPO_ROOT/$subagent"
        if [[ -f "$full_path" ]]; then
            SUBAGENT_RESULTS+=("    - file: \"$subagent\"")
            SUBAGENT_RESULTS+=("      status: verified")
            SUBAGENT_RESULTS+=("      note: \"exists in both ARCHITECTURE.md and filesystem\"")
            ((VERIFIED++))
        else
            SUBAGENT_RESULTS+=("    - file: \"$subagent\"")
            SUBAGENT_RESULTS+=("      status: inconsistent")
            SUBAGENT_RESULTS+=("      note: \"documented in ARCHITECTURE.md but file does not exist\"")
            ((INCONSISTENT++))
            # p5.3: 提案生成
            RECOMMENDATIONS+=("    - severity: medium")
            RECOMMENDATIONS+=("      type: inconsistent")
            RECOMMENDATIONS+=("      target: \"$subagent\"")
            while IFS= read -r line; do
                RECOMMENDATIONS+=("$line")
            done <<< "$(generate_suggestion_subagent "$subagent")"
        fi
    done <<< "$arch_subagents"
    
    # 実装にあるが ARCHITECTURE.md にない SubAgent をチェック
    while IFS= read -r subagent; do
        [[ -z "$subagent" ]] && continue
        if ! echo "$arch_subagents" | grep -qF "$subagent"; then
            SUBAGENT_RESULTS+=("    - file: \"$subagent\"")
            SUBAGENT_RESULTS+=("      status: missing")
            SUBAGENT_RESULTS+=("      note: \"exists in filesystem but not documented in ARCHITECTURE.md\"")
            ((MISSING++))
            # p5.2: 自動修正提案生成
            RECOMMENDATIONS+=("    - severity: low")
            RECOMMENDATIONS+=("      type: missing")
            RECOMMENDATIONS+=("      target: \"$subagent\"")
            while IFS= read -r line; do
                RECOMMENDATIONS+=("$line")
            done <<< "$(generate_auto_fix_subagent "$subagent")"
        fi
    done <<< "$actual_subagents"
}

# === メイン処理 ===

check_hooks
check_skills
check_subagents

# YAML 出力
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "coherence_check:"
echo "  timestamp: \"$TIMESTAMP\""
echo "  summary:"
echo "    verified: $VERIFIED"
echo "    inconsistent: $INCONSISTENT"
echo "    missing: $MISSING"
echo "  hooks:"
if [[ ${#HOOK_RESULTS[@]} -eq 0 ]]; then
    echo "    []"
else
    for line in "${HOOK_RESULTS[@]}"; do
        echo "$line"
    done
fi
echo "  skills:"
if [[ ${#SKILL_RESULTS[@]} -eq 0 ]]; then
    echo "    []"
else
    for line in "${SKILL_RESULTS[@]}"; do
        echo "$line"
    done
fi
echo "  subagents:"
if [[ ${#SUBAGENT_RESULTS[@]} -eq 0 ]]; then
    echo "    []"
else
    for line in "${SUBAGENT_RESULTS[@]}"; do
        echo "$line"
    done
fi
echo "  recommendations:"
if [[ ${#RECOMMENDATIONS[@]} -eq 0 ]]; then
    echo "    []"
else
    for line in "${RECOMMENDATIONS[@]}"; do
        echo "$line"
    done
fi
