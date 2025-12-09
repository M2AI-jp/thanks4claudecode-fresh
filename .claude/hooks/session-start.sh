#!/bin/bash
# session-start.sh - LLMの自己認識を形成し、LOOPを開始させる
#
# 設計方針（8.5 Hooks 設計ガイドライン準拠）:
#   - 軽量な出力のみ（1KB 目標）
#   - state.md, project.md, playbook は LLM に Read させる
#   - OOM 防止のため全文出力は禁止
#
# 自動更新機能:
#   - state.md の session_tracking.last_start を自動更新
#   - LLM の行動に依存しない

set -e

# === state.md の session_tracking を自動更新 ===
if [ -f "state.md" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # last_start を更新（sed -i はmacOSでは -i '' が必要）
    if grep -q "last_start:" state.md; then
        sed -i '' "s/last_start: .*/last_start: $TIMESTAMP/" state.md 2>/dev/null || \
        sed -i "s/last_start: .*/last_start: $TIMESTAMP/" state.md 2>/dev/null || true
    fi

    # 前回 last_end が null でないか確認（正常終了判定）
    LAST_END=$(grep "last_end:" state.md | head -1 | sed 's/.*last_end: *//' | sed 's/ *#.*//')
    if [ "$LAST_END" = "null" ] || [ -z "$LAST_END" ]; then
        # 前回のセッションが正常終了していない可能性
        PREV_START=$(grep "last_start:" state.md | head -1 | sed 's/.*last_start: *//' | sed 's/ *#.*//')
        if [ "$PREV_START" != "null" ] && [ -n "$PREV_START" ]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  ⚠️ 前回のセッションが正常終了していません"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  last_start: $PREV_START"
            echo "  last_end: (未設定)"
            echo ""
            echo "  → 前回の作業状態を確認してください"
            echo ""
        fi
    fi
fi

# === 共通変数 ===
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
WS="$(pwd)"

# === 初期化ペンディングフラグの設定 ===
# init-guard.sh が必須ファイル Read 完了まで他ツールをブロックするために使用
# consent-guard.sh が [理解確認] 完了まで Edit/Write をブロックするために使用
INIT_DIR=".claude/.session-init"
rm -rf "$INIT_DIR" 2>/dev/null || true
mkdir -p "$INIT_DIR"
touch "$INIT_DIR/pending"
touch "$INIT_DIR/consent"  # consent-guard.sh 用 - [理解確認] 完了で削除

# === state.md から情報抽出 ===
[ ! -f "state.md" ] && echo "[WARN] state.md not found" && exit 0

FOCUS=$(grep -A5 "## focus" state.md | grep "current:" | sed 's/.*: *//' | sed 's/ *#.*//')
PHASE=$(grep -A5 "## goal" state.md | grep "phase:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//')
CRITERIA=$(awk '/## goal/,/^## [^g]/' state.md | grep -A20 "done_criteria:" | grep "^  -" | head -6)
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# playbook 取得
[ -n "$FOCUS" ] && PLAYBOOK=$(awk "/## layer: $FOCUS/,/^## [^l]/" state.md | grep "playbook:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//')
[ -z "$PLAYBOOK" ] && PLAYBOOK="null"

# init-guard.sh 用に playbook パスを記録
echo "$PLAYBOOK" > "$INIT_DIR/required_playbook"

# roadmap 取得（workspace レイヤー用）
ROADMAP=$(grep -A10 "## plan_hierarchy" state.md 2>/dev/null | grep "roadmap:" | sed 's/.*: *//' | sed 's/ *#.*//')
# null または空の場合はデフォルト値を使用
[ -z "$ROADMAP" ] || [ "$ROADMAP" = "null" ] && ROADMAP="plan/roadmap.md"
MILESTONE=$(grep -A10 "## plan_hierarchy" state.md 2>/dev/null | grep "current_milestone:" | sed 's/.*: *//' | sed 's/ *#.*//')

# project_context 取得（setup/product レイヤー用）
PROJECT_GENERATED=$(grep -A10 "## project_context" state.md 2>/dev/null | grep "generated:" | sed 's/.*: *//' | sed 's/ *#.*//')
PROJECT_PLAN=$(grep -A10 "## project_context" state.md 2>/dev/null | grep "project_plan:" | sed 's/.*: *//' | sed 's/ *#.*//')

# === 警告出力（条件付き）===
echo ""

# 未コミット変更警告（state-plan-git-branch 4つ組連動の担保）
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    cat <<EOF
$SEP
  ⚠️ 未コミット変更が ${UNCOMMITTED} 件あります
$SEP
  前回のセッションで変更がコミットされていません。
  作業開始前に確認してください:
    git status
    git add -A && git commit -m "..."

EOF
fi

# main ブランチ警告（workspace のみ - setup/product は main で作業可能）
if [ "$BRANCH" = "main" ] && [ "$FOCUS" = "workspace" ]; then
    cat <<EOF
$SEP
  🚨 main ブランチで作業中（禁止）
$SEP
  git checkout -b {fix|feat|refactor}/{description}

EOF
fi

# playbook/branch 不一致警告（branch: null は除外）
if [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
    EXP_BR=$(grep -E "^branch:" "$PLAYBOOK" 2>/dev/null | head -1 | sed 's/branch: *//' | sed 's/ *#.*//')
    if [ -n "$EXP_BR" ] && [ "$EXP_BR" != "null" ] && [ "$BRANCH" != "$EXP_BR" ]; then
        cat <<EOF
$SEP
  ⚠️ ブランチ不一致: 期待=$EXP_BR / 現在=$BRANCH
$SEP
  git checkout $EXP_BR

EOF
    fi
fi

# playbook 未作成警告（setup レイヤーでは抑制）
if [ "$PLAYBOOK" = "null" ] && [ "$FOCUS" != "setup" ]; then
    cat <<EOF
$SEP
  🚨 PLAYBOOK 未作成
$SEP
  1. Read: plan/template/playbook-format.md
  2. plan/active/playbook-{name}.md を作成
  3. state.md の playbook: を更新

EOF
fi

# === CORE ===
cat <<EOF
$SEP
  🧠 CORE
$SEP
  pdca: playbook完了 → 自動次タスク
  tdd: done_criteria = テスト仕様（根拠必須）
  validation: critic → .claude/frameworks/
  plan: Edit/Write → playbook必須（アクションベース）
  git: 1 playbook = 1 branch

EOF

# === 必須 Read 指示（focus 別分岐）===
cat <<EOF
$SEP
  📖 【必須】Read 完了まで作業禁止
$SEP
EOF

case "$FOCUS" in
    setup)
        # setup レイヤー: playbook-setup.md のみ読めば完結
        echo "  1. Read: $WS/state.md"
        echo "  2. Read: $WS/setup/playbook-setup.md"
        echo ""
        echo "  → Phase 0 から開始（ルート選択）"
        echo "  → CATALOG.md は必要な時だけ参照"
        ;;
    product)
        # product レイヤー: plan/project.md を参照して開発
        echo "  1. Read: $WS/state.md"
        if [ "$PROJECT_GENERATED" = "true" ] && [ -n "$PROJECT_PLAN" ] && [ "$PROJECT_PLAN" != "null" ] && [ -f "$PROJECT_PLAN" ]; then
            echo "  2. Read: $WS/$PROJECT_PLAN"
        else
            echo "  ⚠️ plan/project.md が未生成（setup 未完了？）"
        fi
        [ "$PLAYBOOK" != "null" ] && echo "  3. Read: $WS/$PLAYBOOK" || echo "  3. /playbook-init を実行"
        ;;
    workspace)
        # workspace レイヤー: roadmap を参照して開発
        echo "  1. Read: $WS/state.md"
        [ -f "$ROADMAP" ] && echo "  2. Read: $WS/$ROADMAP"
        [ "$PLAYBOOK" != "null" ] && echo "  3. Read: $WS/$PLAYBOOK" || echo "  3. /playbook-init を実行"
        ;;
    plan-template)
        # plan-template レイヤー: テンプレート開発
        echo "  1. Read: $WS/state.md"
        [ "$PLAYBOOK" != "null" ] && echo "  2. Read: $WS/$PLAYBOOK"
        ;;
    *)
        # 不明な focus
        echo "  1. Read: $WS/state.md"
        ;;
esac

cat <<EOF

  → [自認] 宣言 → main なら branch 作成 → LOOP 開始

EOF

# === state.md 抜粋（focus + goal のみ）===
cat <<EOF
$SEP
  📍 state.md 抜粋
$SEP
EOF
awk '/^## focus/,/^## [^f]/' state.md | head -8
awk '/^## goal/,/^## [^g]/' state.md | head -15

# === 上位計画書抜粋（focus 別）===
case "$FOCUS" in
    workspace)
        # workspace: roadmap.md を表示
        if [ -f "$ROADMAP" ]; then
            cat <<EOF

$SEP
  🗺️ 上位計画書（$ROADMAP）
$SEP
EOF
            awk '/^## current_focus/,/^## [^c]/' "$ROADMAP" | head -15
            echo ""
            echo "📋 next_actions:"
            awk '/^## current_focus/,/^## [^c]/' "$ROADMAP" | grep -A10 "next_actions:" | grep "^  -" | head -5
        fi
        ;;
    product)
        # product: project.md を表示（存在する場合）
        if [ "$PROJECT_GENERATED" = "true" ] && [ -n "$PROJECT_PLAN" ] && [ -f "$PROJECT_PLAN" ]; then
            cat <<EOF

$SEP
  📋 プロジェクト計画（$PROJECT_PLAN）
$SEP
EOF
            awk '/^## vision/,/^## [^v]/' "$PROJECT_PLAN" 2>/dev/null | head -10
        fi
        ;;
    setup)
        # setup: セットアップフロー概要を表示
        cat <<EOF

$SEP
  🚀 セットアップフロー
$SEP
Phase 0: ルート選択（チュートリアル or 本番開発）
Phase 1-6: 環境構築
Phase 7: 完了確認
Phase 8: plan/project.md 生成 → product レイヤーへ

$SEP
  💬 Phase 0 発話テンプレート
$SEP
こんにちは！Mac の開発環境セットアップをお手伝いします。

最初に1つだけ教えてください：

【今日の目的は？】

A: まずプログラミングを体験してみたい（チュートリアル）
   → 費用ゼロ、10分で AI チャットが動きます

B: 実際に使うアプリやサービスを作りたい（本番開発）
   → 作りたいものに合わせた本格的な環境を構築します

どちらですか？（A または B）
EOF
        ;;
esac

# === Playbook in_progress Phase 抽出 ===
if [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
    # in_progress の phase を抽出（name, goal, done_criteria を表示）
    IN_PROGRESS=$(grep -n "status: in_progress" "$PLAYBOOK" 2>/dev/null | head -1 | cut -d: -f1)
    if [ -n "$IN_PROGRESS" ]; then
        cat <<EOF

$SEP
  🎯 現在の Phase（in_progress）
$SEP
EOF
        # in_progress 行の前後を抽出して name, goal, done_criteria を表示
        awk -v line="$IN_PROGRESS" 'NR>=line-10 && NR<=line+15' "$PLAYBOOK" | grep -E "^\s*(- id:|name:|goal:|done_criteria:|  - )" | head -12
        echo ""
        echo "→ done_criteria を「テスト」として扱い、証拠を集めてから完了判定"
    fi
fi

# === [自認] テンプレート（focus 別）===
cat <<EOF

$SEP
  🏷️ [自認] テンプレート
$SEP
what: $FOCUS
phase: $PHASE
branch: $BRANCH
EOF

# focus 別の追加フィールド
case "$FOCUS" in
    workspace)
        echo "milestone: $MILESTONE"
        ;;
    product)
        echo "project: $PROJECT_PLAN"
        ;;
    setup)
        # playbook は共通出力（下の cat <<EOF）で表示されるため省略
        ;;
esac

cat <<EOF
playbook: $PLAYBOOK
done_criteria:
$CRITERIA

⚠️ 敬語必須。タメ口禁止。
EOF

# === 利用可能機能（簡潔版）===
if [ -f "spec.yaml" ]; then
    echo ""
    echo "$SEP"
    echo "  📦 利用可能機能"
    echo "$SEP"

    # Agents
    printf "Agents: "
    [ -d ".claude/agents" ] && ls .claude/agents/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ' ' || echo -n "(none)"
    echo ""

    # Commands
    printf "Commands: "
    ls .claude/commands/*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/\//' | tr '\n' ' '
    echo ""

    # Skills
    printf "Skills: "
    ls -d .claude/skills/*/ 2>/dev/null | xargs -I{} basename {} | tr '\n' ' '
    echo ""
fi

exit 0
