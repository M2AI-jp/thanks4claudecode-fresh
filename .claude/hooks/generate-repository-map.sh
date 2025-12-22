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

# エンコーディング設定（sed/grep の互換性のため LC_ALL=C を使用）
# 注: 日本語文字が含まれるファイルの description は正しく抽出されない可能性あり
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
    "tmp"
    "*.log"
    "*.tmp"
    ".DS_Store"
)

# ==============================================================================
# ユーティリティ関数
# ==============================================================================

# ファイルから description を抽出（100文字まで、マルチバイト対応）
extract_description() {
    local file="$1"
    local ext="${file##*.}"
    local desc=""
    local MAX_CHARS=100  # 文字数（バイト数ではない）

    case "$ext" in
        sh)
            # シェルスクリプト: 最初の # コメント行から抽出
            desc=$(grep -m1 "^# .*- " "$file" 2>/dev/null | sed 's/^# //' || echo "")
            ;;
        md)
            # Markdown: > ブロックまたは最初の段落から抽出
            desc=$(grep -m1 "^>" "$file" 2>/dev/null | sed 's/^> \*\*//' | sed 's/\*\*.*//' || echo "")
            if [[ -z "$desc" ]]; then
                desc=$(sed -n '3p' "$file" 2>/dev/null || echo "")
            fi
            ;;
        yaml|yml|json)
            # YAML/JSON: description フィールドから抽出
            desc=$(grep -m1 "description:" "$file" 2>/dev/null | sed 's/.*description: *//' | sed 's/"//g' || echo "")
            ;;
        *)
            desc=""
            ;;
    esac

    # マルチバイト対応で文字数を制限（awk で UTF-8 対応切り詰め）
    # 特殊文字をエスケープし、改行を削除
    echo "$desc" | tr -d '\n' | awk -v max="$MAX_CHARS" '{print substr($0, 1, max)}' | sed 's/"/\\"/g'
}

# settings.json から Hook のトリガー情報を取得
get_hook_trigger() {
    local hook_name="$1"
    local settings_file="$PROJECT_ROOT/.claude/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        echo "unknown"
        return
    fi

    # jq がある場合は使用
    if command -v jq &> /dev/null; then
        local result
        result=$(jq -r --arg name "$hook_name" '
            .hooks | to_entries[] |
            .value[] |
            select(.hooks != null) |
            .hooks[] |
            select(.command | contains($name)) |
            empty
        ' "$settings_file" 2>/dev/null)

        # フォールバック: 直接マッチング
        if [[ -z "$result" ]]; then
            # PreToolUse チェック
            if jq -e --arg name "$hook_name" '.hooks.PreToolUse[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                local matcher
                matcher=$(jq -r --arg name "$hook_name" '
                    .hooks.PreToolUse[] |
                    select(.hooks[]?.command | contains($name)) |
                    .matcher
                ' "$settings_file" 2>/dev/null | head -1)
                echo "PreToolUse:${matcher:-*}"
                return
            fi
            # PostToolUse チェック
            if jq -e --arg name "$hook_name" '.hooks.PostToolUse[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                local matcher
                matcher=$(jq -r --arg name "$hook_name" '
                    .hooks.PostToolUse[] |
                    select(.hooks[]?.command | contains($name)) |
                    .matcher
                ' "$settings_file" 2>/dev/null | head -1)
                echo "PostToolUse:${matcher:-*}"
                return
            fi
            # SessionStart チェック
            if jq -e --arg name "$hook_name" '.hooks.SessionStart[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "SessionStart:*"
                return
            fi
            # UserPromptSubmit チェック
            if jq -e --arg name "$hook_name" '.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "UserPromptSubmit:*"
                return
            fi
            # SessionEnd チェック
            if jq -e --arg name "$hook_name" '.hooks.SessionEnd[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "SessionEnd:*"
                return
            fi
            # Stop チェック
            if jq -e --arg name "$hook_name" '.hooks.Stop[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "Stop:*"
                return
            fi
            # PreCompact チェック
            if jq -e --arg name "$hook_name" '.hooks.PreCompact[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "PreCompact:*"
                return
            fi
        fi
        echo "utility"
    else
        # jq がない場合は grep で簡易抽出
        local event
        event=$(grep -B10 "$hook_name" "$settings_file" 2>/dev/null | grep -oE '"(PreToolUse|PostToolUse|SessionStart|UserPromptSubmit|SessionEnd|Stop|PreCompact)"' | tr -d '"' | tail -1 || echo "")
        if [[ -n "$event" ]]; then
            echo "$event:*"
        else
            echo "utility"
        fi
    fi
}

# ファイル数をカウント
count_files() {
    local dir="$1"
    local pattern="$2"
    find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | wc -l | tr -d ' '
}

# ==============================================================================
# M027: hook_trigger_sequence 生成関数
# ==============================================================================

# 公式トリガー順序（https://code.claude.com/docs/ja/hooks）
TRIGGER_ORDER=("SessionStart" "UserPromptSubmit" "PreToolUse" "PostToolUse" "Stop" "PreCompact" "SessionEnd")

# 指定トリガーの Hook 一覧を取得（詳細付き）
get_hooks_for_trigger() {
    local trigger="$1"
    local settings_file="$PROJECT_ROOT/.claude/settings.json"

    if [[ ! -f "$settings_file" ]] || ! command -v jq &> /dev/null; then
        return
    fi

    # トリガー配下の Hook を取得
    jq -r --arg trigger "$trigger" '
        .hooks[$trigger][]? |
        {matcher: .matcher, hooks: .hooks} |
        .hooks[]? |
        {matcher: .matcher, command: .command, timeout: .timeout}
    ' "$settings_file" 2>/dev/null | jq -s '.' 2>/dev/null
}

# hook_trigger_sequence セクションを生成
generate_hook_trigger_sequence() {
    local settings_file="$PROJECT_ROOT/.claude/settings.json"

    cat >> "$TEMP_FILE" << 'HTS_HEADER'

# ==============================================================================
# Hook Trigger Sequence (M027)
# 公式ドキュメント準拠の発火順序
# https://code.claude.com/docs/ja/hooks
# ==============================================================================

hook_trigger_sequence:
  description: "Hook の発火順序（公式ドキュメント準拠）"
  order_reference: "SessionStart → UserPromptSubmit → PreToolUse → PostToolUse → Stop → PreCompact → SessionEnd"
  triggers:
HTS_HEADER

    for trigger in "${TRIGGER_ORDER[@]}"; do
        # トリガーの存在チェック
        local has_hooks
        has_hooks=$(jq -r --arg t "$trigger" '.hooks[$t] | length' "$settings_file" 2>/dev/null || echo "0")

        if [[ "$has_hooks" -gt 0 ]]; then
            cat >> "$TEMP_FILE" << EOF
    - trigger: "$trigger"
      description: "$(get_trigger_description "$trigger")"
      matchers:
EOF
            # matcher ごとに Hook を出力（glob 展開を防ぐ）
            set -f  # glob 展開を無効化
            local matchers
            matchers=$(jq -r --arg t "$trigger" '.hooks[$t][]? | "\(.matcher)"' "$settings_file" 2>/dev/null | sort -u)
            while IFS= read -r matcher; do
                [[ -z "$matcher" ]] && continue
                cat >> "$TEMP_FILE" << EOF
        - matcher: "$matcher"
          hooks:
EOF
                # 該当 matcher の Hook 一覧
                jq -r --arg t "$trigger" --arg m "$matcher" '
                    .hooks[$t][]? |
                    select(.matcher == $m) |
                    .hooks[]? |
                    select(.command != null) |
                    .command | split("/") | .[-1]
                ' "$settings_file" 2>/dev/null | while IFS= read -r hook_script; do
                    [[ -z "$hook_script" ]] && continue
                    local hook_desc
                    hook_desc=$(extract_description "$HOOKS_DIR/$hook_script" 2>/dev/null | head -c 100 || echo "")
                    cat >> "$TEMP_FILE" << EOF
            - script: "$hook_script"
              description: "$hook_desc"
EOF
                done
            done <<< "$matchers"
            set +f  # glob 展開を再有効化
        fi
    done
}

# トリガーの説明を取得
get_trigger_description() {
    local trigger="$1"
    case "$trigger" in
        SessionStart)    echo "セッション開始時に発火" ;;
        UserPromptSubmit) echo "ユーザープロンプト送信時に発火" ;;
        PreToolUse)      echo "ツール実行前に発火（matcher でフィルタ可能）" ;;
        PostToolUse)     echo "ツール実行後に発火（matcher でフィルタ可能）" ;;
        Stop)            echo "セッション中断時（Ctrl+C, /stop）に発火" ;;
        PreCompact)      echo "コンテキスト圧縮前に発火" ;;
        SessionEnd)      echo "セッション終了時に発火" ;;
        *)               echo "不明なトリガー" ;;
    esac
}

# ==============================================================================
# M027: workflows セクション生成関数
# ==============================================================================

generate_workflows() {
    cat >> "$TEMP_FILE" << 'WORKFLOWS_HEADER'

# ==============================================================================
# Workflows (M027)
# 組み合わせモジュール単位でシステム構造を整理
# ==============================================================================

workflows:
  description: "複数コンポーネントが連携して1つの機能を実現する組み合わせモジュール"
  modules:

    - id: init_flow
      name: "INIT"
      why: |
        LLM は状態を保持しないため、毎セッション開始時に現在地を再認識する必要がある。
        state.md/project.md/playbook の強制読み込みにより、コンテキストを確実に復元する。
      when: "SessionStart 発火時"
      input:
        - "ユーザーの最初のプロンプト"
        - "state.md（focus, playbook, goal）"
        - "plan/project.md（milestones）"
        - "playbook（active な場合）"
      process:
        hooks:
          - "session-start.sh: pending 作成、失敗パターン表示"
          - "init-guard.sh: 必須ファイル Read 強制"
          - "check-main-branch.sh: main ブランチ禁止"
        subagents: []
        skills: []
        claude_md: "INIT セクション → [自認] 出力"
      output:
        - "[自認] ブロック（what, milestone, phase, branch...）"
        - "pending ファイル削除"
      references:
        - ".claude/hooks/session-start.sh"
        - ".claude/hooks/init-guard.sh"
        - ".claude/hooks/check-main-branch.sh"
        - "CLAUDE.md"
        - "state.md"
        - "plan/project.md"

    - id: work_loop
      name: "LOOP"
      why: |
        playbook の phase を順次実行し、done_criteria を満たすまで反復する。
        critic による検証で報酬詐欺を防止し、確実な品質を保証する。
      when: "INIT 完了後、playbook が存在する場合"
      input:
        - "playbook（current phase, done_criteria）"
        - "subtasks（criterion, executor, test_command）"
      process:
        hooks:
          - "playbook-guard.sh: playbook 存在確認"
          - "scope-guard.sh: スコープ制限"
          - "executor-guard.sh: executor 整合性"
          - "critic-guard.sh: critic 未実行チェック"
        subagents:
          - "critic: PASS/FAIL 判定"
        skills:
          - "test-runner: テスト実行"
        claude_md: "LOOP セクション → subtask 実行"
      output:
        - "ファイル変更（Edit/Write）"
        - "test_command 結果"
        - "critic 判定（PASS/FAIL）"
        - "phase.status = done（PASS の場合）"
      references:
        - ".claude/hooks/playbook-guard.sh"
        - ".claude/hooks/scope-guard.sh"
        - ".claude/hooks/executor-guard.sh"
        - ".claude/hooks/critic-guard.sh"
        - ".claude/agents/critic.md"
        - "CLAUDE.md"

    - id: post_loop
      name: "POST_LOOP"
      why: |
        playbook 完了時に自動でアーカイブ、project.milestone 更新、次 playbook 作成を行う。
        手動操作なしで継続的な進捗を実現する。
      when: "playbook の全 phase が done"
      input:
        - "playbook（全 phase done）"
        - "project.md（milestone）"
      process:
        hooks:
          - "archive-playbook.sh: アーカイブ提案"
          - "cleanup-hook.sh: tmp/ クリーンアップ"
          - "create-pr-hook.sh: PR 作成トリガー"
        subagents:
          - "pm: 次 playbook 作成"
        skills:
          - "post-loop: 完了処理"
        claude_md: "POST_LOOP セクション → milestone 更新"
      output:
        - "playbook アーカイブ（plan/archive/）"
        - "state.md 更新（playbook.active = null）"
        - "project.md 更新（milestone.status = achieved）"
        - "次 playbook（存在する場合）"
        - "/clear 推奨アナウンス"
      references:
        - ".claude/hooks/archive-playbook.sh"
        - ".claude/hooks/cleanup-hook.sh"
        - ".claude/hooks/create-pr-hook.sh"
        - ".claude/agents/pm.md"
        - ".claude/skills/post-loop/"
        - "CLAUDE.md"
        - "plan/project.md"

    - id: critique_process
      name: "CRITIQUE"
      why: |
        「完了」の自己判断を禁止し、critic SubAgent による客観的検証で報酬詐欺を防止。
        done_criteria の達成を証拠付きで確認。
      when: "phase 完了申告時"
      input:
        - "phase.done_criteria"
        - "test_command 実行結果"
        - "変更内容"
      process:
        hooks:
          - "critic-guard.sh: critic 実行チェック"
        subagents:
          - "critic: done_criteria 検証"
        skills: []
        claude_md: "CRITIQUE セクション参照"
      output:
        - "critic 判定（PASS/FAIL）"
        - "根拠（evidence）"
        - "修正指示（FAIL の場合）"
      references:
        - ".claude/hooks/critic-guard.sh"
        - ".claude/agents/critic.md"
        - ".claude/frameworks/done-criteria-validation.md"
        - "CLAUDE.md"

    - id: project_complete
      name: "PROJECT_COMPLETE"
      why: |
        全 milestone 達成時に feature ブランチを main にマージし、GitHub にプッシュ。
        state.md を neutral 状態にリセットして次の作業に備える。
      when: "全 milestone が status: achieved"
      input:
        - "project.md（全 milestone の status）"
        - "現在の feature ブランチ"
        - "state.md"
      process:
        hooks:
          - "merge-pr.sh: main マージ"
        subagents:
          - "pm: 全 milestone 達成を検出"
        skills:
          - "post-loop: 完了処理"
        claude_md: "POST_LOOP#PROJECT_COMPLETE"
      output:
        - "main ブランチにマージ"
        - "GitHub にプッシュ"
        - "state.md neutral 状態"
        - "PROJECT 完了アナウンス"
        - "/clear 推奨"
      references:
        - "plan/project.md"
        - "CLAUDE.md"
        - ".claude/hooks/merge-pr.sh"
WORKFLOWS_HEADER
}

# ==============================================================================
# M025: system_specification 生成関数
# M027 MECE: init_flow/loop_flow/post_loop_flow は workflows セクションに統一
# ==============================================================================

# CLAUDE.md から禁止事項を抽出
extract_behavior_rules() {
    local claude_md="$PROJECT_ROOT/CLAUDE.md"
    if [[ ! -f "$claude_md" ]]; then
        echo "      - playbook=null で Edit/Write 禁止"
        return
    fi

    # 禁止事項セクションから抽出
    grep -A20 "^## 禁止事項" "$claude_md" 2>/dev/null | \
        grep "^❌" | \
        sed 's/❌ /      - /' | \
        head -10 || echo "      - (抽出失敗)"
}

# system_specification セクションを生成（M027 MECE: behavior_rules のみ）
generate_system_specification() {
    cat >> "$TEMP_FILE" << 'SPEC_HEADER'

# ==============================================================================
# System Specification (M025)
# Claude の行動ルールの Single Source of Truth
# 注: フロー詳細は workflows セクション参照（M027 MECE 統一）
# ==============================================================================

system_specification:
  description: "Claude の行動ルールの Single Source of Truth"
  note: "init_flow/loop_flow/post_loop_flow は workflows セクションに統一（MECE）"

  behavior_rules:
    description: "CLAUDE.md から抽出した行動ルール"
    core_principles:
      - "pdca_autonomy: playbook 完了 → milestone 更新 → 次 playbook 自動作成"
      - "tdd_first: done_criteria = テスト仕様、根拠必須"
      - "validation: critic は frameworks/ を参照"
      - "plan_based: playbook=null で Edit/Write → ブロック"
      - "git_branch_sync: 1 playbook = 1 branch"
    mandatory_outputs:
      - "[自認]: セッション開始時"
    prohibited_actions:
SPEC_HEADER
    extract_behavior_rules >> "$TEMP_FILE"
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
    # M027 MECE: name のみ出力（trigger/description は hook_trigger_sequence 参照）
    for hook in "$HOOKS_DIR"/*.sh; do
        [[ -f "$hook" ]] || continue
        name=$(basename "$hook")
        echo "    - name: \"$name\"" >> "$TEMP_FILE"
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
  invocation: "Claude が文脈から自動検出して Skill ツールで呼び出す"
  usage: "プロンプトにマッチしたら発火。モデル主導で判断。"
  auto_invoke: true
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
# Frameworks - REMOVED (M027 MECE: ディレクトリ不存在のため削除)
# ==============================================================================
# 注: .claude/rules/frameworks/ は存在しない
FRAMEWORKS_COUNT=0

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
  invocation: "ユーザーが /command で明示的に呼び出す（例: /test, /lint）"
  usage: "即座に実行される CLI 機能。ユーザーの意図を明確に反映。"
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
# 統計サマリー - REMOVED (M027 MECE: 各セクションの count と重複)
# ==============================================================================
# 注: summary セクションは各セクションの count の再掲のため削除

# ==============================================================================
# System Specification (M025)
# ==============================================================================
echo "  Generating system specification..."
generate_system_specification

# ==============================================================================
# Hook Trigger Sequence (M027)
# ==============================================================================
echo "  Generating hook trigger sequence..."
generate_hook_trigger_sequence

# ==============================================================================
# Workflows (M027)
# ==============================================================================
echo "  Generating workflows..."
generate_workflows

cat >> "$TEMP_FILE" << EOF

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
