# CLAUDE.md

> **【即時実行】このファイルを読んだ直後、INIT セクションを実行せよ。[自認]出力までユーザーに応答するな。違反 → init-guard.sh がブロック（exit 2）。**

> **【三位一体】Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）。単独では機能しない。組み合わせて初めて強制力を持つ。**

> **【報酬詐欺防止】「完了」の自己判断禁止。critic SubAgent が PASS を返すまで done 不可。1回で終わらせようとする衝動に抗え。LOOP を回し続けよ。**

> **【自律 ≠ 勝手】project.md → playbook → Phase の連鎖から次を導出。待つな。しかしユーザーの意図を推測で補完するな。不明 → 質問。「確認」はするな。**

> **【タスク標準化】全タスク開始は pm SubAgent 経由必須。直接 playbook を作成するな。/task-start → pm → project.md 参照 → derives_from 設定 → playbook 作成。**

@CLAUDE-ref.md 

```yaml
# アクションベース Guards
制御点: Edit/Write ツール使用時のみ playbook チェック
許可: Read/Grep/WebSearch 等は playbook なしでも常に許可
設計思想: プロンプトの「意図」ではなく「アクション」を制御
```

---

## INIT（セッション開始時）【絶対ルール】

> **ユーザーのメッセージに応答する前に、以下を必ず完了せよ。スキップは許可されていない。**

```
【フェーズ 1: 必須読み込み】※ユーザー応答前に必須

  1. Read: state.md（現在地・goal・done_criteria）
  2. Read: plan/project.md（Macro 計画、存在する場合）
  3. Read: playbook（active_playbooks から特定、なければ null）

  ⚠️ Hook 出力を「見た」だけでは不十分。Read ツールで実際に読め。
  ⚠️ Read 未完了でユーザーに応答するな。

【フェーズ 2: git/branch 状態取得】

  4. Bash: `git rev-parse --abbrev-ref HEAD`
  5. Bash: `git status -sb`
  6. main ブランチ → ブランチを切る

【フェーズ 3: playbook 準備】★pm 経由必須

  7. playbook=null → pm SubAgent を呼び出す（/task-start）
     - pm が project.md を参照して playbook を作成
     - derives_from を必ず設定
     - ブランチ作成も pm が実行
     ⚠️ pm を経由せずに直接 playbook を作成することは禁止

【フェーズ 4: 宣言】

  8. [自認] を出力

【フェーズ 4.5: 合意プロセス（CONSENT）】★重要

  条件: playbook=null の場合のみ実行（計画がない = 新規タスク）

  9. ユーザープロンプトを「要件定義」として解釈
  10. [理解確認] を出力（構造化）
  11. ユーザー応答を待つ（★例外的に許可）
      - OK / 了解 → consent ファイル削除 → フェーズ 5 へ
      - 修正指示 → 再解釈 → [理解確認] 再出力
      - 却下 / やめて → 作業中止

  スキップ条件:
    - playbook が既に存在する（計画済み = 合意済み）
    - ユーザーが「スキップ」「すぐやって」等を指示
    - 調査・質問のみ（Edit/Write を使わない）

  ⚠️ [理解確認] なしで playbook 作成 → 禁止
  ⚠️ ユーザー OK なしで作業開始 → 禁止

【フェーズ 5: Macro チェック & 計画の導出】

  12. plan/project.md の存在を確認
  13. playbook=null かつ Macro が存在する場合:
      - project.md の not_achieved を確認
      - depends_on を分析し、着手可能な done_when を特定
      - decomposition を参照して playbook を作成（または pm を呼び出す）
      - 「Macro: {summary} / 次: {done_when.name} を進めます。」
  14. playbook がある場合:
      - 現在の Phase を確認し LOOP に入る
  15. Macro が存在しない場合（setup レイヤー）:
      - 「Macro は Phase 8 で生成されます。setup を進めます。」
      - playbook の Phase 0 から開始
  16. LOOP に入る（ユーザーが止めない限り進む）

  ⚠️ 禁止: 「よろしいですか？」と聞く（CONSENT 以外で）
  ⚠️ 禁止: 「何か続けますか？」と聞く
  ⚠️ 例外: フェーズ 4.5 ではユーザー応答を待つ
```

---

## [自認]（必ず最初に出力）

```
[自認]
what: {focus.current}
phase: {goal.phase}
branch: {現在のブランチ名}
macro_goal: {plan/project.md の summary | "Phase 8 で生成"}
remaining_tasks: {project.md の残タスク | playbook の残 Phase}
playbook: {active_playbooks.{focus.current}}
done_criteria: {goal.done_criteria を列挙}
git_status: {clean | modified | untracked}
last_critic: {null | PASS | FAIL}
```

> **根幹**: focus-state-playbook-branch は連動。不一致なら警告を出し、修正を実行。

---

## CORE（原則）

```yaml
pdca_autonomy:
  rule: playbook 完了 → 自動で次タスク開始
  禁止: ユーザープロンプトを待つ

tdd_first:
  rule: done_criteria = テスト仕様
  条件: 根拠 = ユーザー発言引用 | 検証可能指標
  禁止: 根拠なき done_criteria

validation:
  rule: critic は .claude/frameworks/ を参照
  禁止: 都度生成の評価基準

plan_based:
  条件: playbook=null で Edit/Write → ブロック（アクションベース Guards）

issue_context:
  rule: playbook.meta.issue に Issue 番号記載

git_branch_sync:
  rule: 1 playbook = 1 branch
```

---

## CONSENT（合意プロセス）

> **詳細: @.claude/skills/consent-process/skill.md**

playbook=null で新規タスク開始時、[理解確認] を出力してユーザー合意を取得。
Hook（consent-guard.sh）で合意ファイルの有無をチェック。

---

## LOOP

```
iteration = 0
max = playbook.phase.max_iterations || 10

while true:
  iteration++
  if iteration > max: break  # デッドロック検出

  0. 根拠なし → ユーザーに質問
  1. done_criteria を読む
  2. 証拠あり → PASS、なし → EXEC()
  3. 全 PASS → CRITIQUE()
     PASS → state.md 更新 → 自動コミット → 次 Phase
     FAIL → 修正 → continue
  4. 不明 → break

Phase 完了時の自動コミット★直接実行（git-ops.md 参照）:
  条件: critic PASS 後、state.md 更新後
  実行: 以下のコマンドを直接実行（git-ops 呼び出し不要）
  ```bash
  git add -A && git commit -m "$(cat <<'EOF'
  feat({phase}): {summary}

  done_criteria:
  - {criteria_1}
  - {criteria_2}

  critic: PASS
  playbook: {playbook_path}

  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  EOF
  )"
  ```
  スキップ: 未コミット変更がない場合（git status --porcelain で確認）

静的解析（git commit/add 時に自動発火）:
  Hook: lint-check.sh (PreToolUse:Bash)
  対象:
    - ESLint: package.json 存在時
    - ShellCheck: .claude/hooks/ 配下
    - Ruff: pyproject.toml 存在時
  結果: 警告表示（ブロックはしない）
  修正: pnpm lint --fix / ruff check --fix で自動修正可能
```

---

## POST_LOOP（playbook 完了後）

> **詳細: @.claude/skills/post-loop/skill.md**

playbook の全 Phase が done → 自動コミット → アーカイブ → **PR 作成** → **PR マージ** → 次タスク導出。

```yaml
フロー:
  0. 自動コミット（最終 Phase 分）
  0.5. playbook アーカイブ
  1. PR 作成（★自動化済み）
  2. PR マージ（★自動化済み）
  3. project.done_when 更新
  4. 次タスク導出（pm 経由）

PR 作成:
  Hook: .claude/hooks/create-pr-hook.sh（PostToolUse:Edit で自動発火）
  本体: .claude/hooks/create-pr.sh
  タイトル: feat({playbook}/{phase}): {goal summary}
  本文: done_when + done_criteria + completed phases
  条件分岐:
    成功: → PR マージへ進む
    PR 既存: スキップ
    失敗: エラーログ出力、手動対応を促す

PR マージ:
  スクリプト: .claude/hooks/merge-pr.sh
  コマンド: gh pr merge --merge --auto --delete-branch
  条件分岐:
    成功: ブランチ削除 → main 同期 → 次タスク導出へ
    Draft: エラー（gh pr ready で解除を促す）
    コンフリクト: エラー（手動解決を促す）
    必須チェック未完了: --auto で待機
    失敗: エラーログ出力、手動対応を促す

整合性チェック:
  check-coherence.sh:
    - state.md と playbook の連動確認
    - branch と playbook の一致確認
    - focus.current との整合性確認
```

禁止: 「報告して待つ」パターン、ユーザーに「次は何をしますか？」と聞く。

---

## ACTION_GUARDS（アクションベース制御）

> **プロンプトの「意図」ではなく「アクション」を制御する。**

```yaml
設計思想:
  - Edit/Write 時のみ playbook チェック
  - Read/Grep/WebSearch 等は常に許可
  - プロンプト分類（session）は廃止

制御の流れ:
  1. ユーザーがプロンプトを送信
  2. Claude が自由に調査（Read/Grep/WebSearch）
  3. Edit/Write を使おうとしたとき:
     - playbook あり → 許可
     - playbook なし → ブロック（playbook-guard.sh）

利点:
  - 「意図」の推測が不要
  - 「おはよう」も「調査して」も自由に対応可能
  - 実際にコードを変更するときだけ計画を要求

⚠️ playbook なしで Edit/Write → ブロック
⚠️ 調査・報告は playbook なしでも可能
```

---

## CRITIQUE

```yaml
条件: done 更新前に critic 必須
実行: Task(subagent_type="critic") | /crit
参照: .claude/frameworks/done-criteria-validation.md
PASS → done 更新可
FAIL → 修正 → 再実行
```

---

## SKILLS_CHAIN（Skills 呼び出し連鎖）

> **Skills は SubAgents 経由で呼び出される。直接呼び出しも可能だが、連鎖を通じて自動発火する。**

```yaml
# ========================================
# 連鎖構造
# ========================================

architecture: |
  ┌─────────────────────────────────────────────────────────────────┐
  │                 Skills 呼び出し連鎖                             │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                  │
  │  【Hooks】              【SubAgents】           【Skills】       │
  │                                                                  │
  │  playbook-guard.sh  ─→  pm               ─→  plan-management    │
  │        │                  │                                      │
  │        │                  └─→ Read: plan/template/*.md          │
  │        │                                                         │
  │  critic-guard.sh   ─→  critic            ─→  lint-checker       │
  │                          │               ─→  test-runner        │
  │                          │               ─→  deploy-checker     │
  │                          │                                       │
  │                          └─→ Read: .claude/frameworks/*.md      │
  │                                                                  │
  └─────────────────────────────────────────────────────────────────┘

# ========================================
# SubAgent → Skills 呼び出しルール
# ========================================

critic_skills:
  lint-checker:
    条件: 変更ファイルに .ts/.tsx/.js/.jsx/.sh が含まれる
    タイミング: done_criteria 評価の前
  test-runner:
    条件: 変更ファイルに *.test.* / *.spec.* が含まれる
    タイミング: done_criteria 評価の前
  deploy-checker:
    条件: done_criteria に「デプロイ」「本番」が含まれる
    タイミング: done_criteria 評価の前

pm_templates:
  playbook-format.md:
    条件: playbook 作成時（必須）
    目的: 最新のフォーマットと記述ルールを確認
  planning-rules.md:
    条件: 複雑な計画時
    目的: 計画の記述ルールを確認

# ========================================
# 全ファイルへのアクセス経路
# ========================================

access_routes:
  # 自動参照（INIT で読まれる）
  auto_init:
    - CLAUDE.md（Claude Code 起動時）
    - state.md（INIT 必須 Read）
    - plan/project.md（INIT 必須 Read）
    - playbook（active_playbooks から特定）

  # SubAgent 経由で参照
  via_subagents:
    critic:
      - .claude/frameworks/done-criteria-validation.md
      - .claude/skills/lint-checker/skill.md
      - .claude/skills/test-runner/skill.md
      - .claude/skills/deploy-checker/skill.md
    pm:
      - plan/template/playbook-format.md
      - plan/template/planning-rules.md
      - setup/CATALOG.md
    coherence:
      - state.md
      - playbook

  # Hook 経由で参照
  via_hooks:
    - .claude/protected-files.txt（check-protected-edit.sh）
    - state.md（各種 guard）

  # アーカイブ系（限定的参照）
  archive:
    - docs/*（明示的参照時のみ）
    - .claude/logs/*（記録用、learning Skill で参照可能）
    - .archive/*（過去の playbook、learning Skill で参照可能）

# ========================================
# Skills 直接呼び出し
# ========================================

direct_call:
  方法: Skill ツールを使用
  例: Skill: "lint-checker"
  用途: SubAgent を経由せず直接呼び出したい場合
```

---

## CONTEXT_EXTERNALIZATION（コンテキスト外部化）

> **詳細: @.claude/skills/context-externalization/skill.md**

Phase 完了時に .claude/logs/context-log.md へ記録。チャット履歴に依存しない状態管理。

---

## PROTECTED（保護対象ファイル）

> **実際の保護設定は `.claude/protected-files.txt` によって決まる。**

```yaml
保護レベル:
  HARD_BLOCK: 絶対守護（developer モード以外では常にブロック）
  BLOCK: strict でブロック、trusted で WARN
  WARN: 警告のみ

BLOCK ファイルを編集したい場合:
  1. 変更案をテキストで提示
  2. ユーザーが明示的に許可した場合のみ編集
```

---

## 禁止事項

```
❌ 確認を求める、許可を求める、選ばせる（安全上の例外を除く）
❌ done_criteria 確認なしで「完了しました」
❌ 保護対象ファイルを無断で編集
❌ playbook=null で Edit/Write を実行
❌ main ブランチで直接作業
❌ critic なしで Phase/layer を done にする（絶対禁止）
❌ forbidden 遷移を実行する
❌ focus.current と異なるレイヤーのファイルを無断で編集
❌ ユーザーに聞かずに done_criteria を推測で定義する【報酬詐欺】
❌ 「計画を立てる」こと自体を目的にする【計画のための計画】
❌ Hook を回避する行為（consent/pending ファイルの削除等）【構造破壊】
❌ Hook の警告を無視してユーザープロンプトに引っ張られる【mission 逸脱】
❌ pm SubAgent を経由せずに直接 playbook を作成する【タスク標準化違反】
```

---

## CONTEXT（コンテキスト管理）

> **コンテキストが膨らんだらルールが効かなくなる。外部ファイルを真実源とし、積極的にリセットせよ。**

```yaml
真実源:
  - state.md / project.md / playbook が唯一の真実
  - チャット履歴に依存しない

いつ /clear するか:
  - Phase が 1 つ完了したとき
  - コンテキスト使用率が 80% を超えたとき（/context で確認）

/clear 後の必須行動:
  1. INIT を最初からやり直す
  2. [自認] を再宣言する

/compact の活用:
  /compact 以下を優先して保持: done_criteria, 現在の Phase, 禁止事項

自己監視（コンテキスト怪しいセンサー）:
  - ルールと矛盾する行動をしている気がする → /context で確認
  - 80% 超過なら /clear を提案

MCP の使い分け:
  - context7: 外部ライブラリの公式ドキュメントが必要な場合のみ
  - 「とりあえず context7」は避ける
```

---

## 変更履歴

> 詳細な履歴: `.claude/context/claude-md-history.md`

| 日時 | 内容 |
|------|------|
| 2025-12-10 | V6.0: コンテキスト・アーキテクチャ再設計。CONSENT/POST_LOOP/CONTEXT_EXTERNALIZATION を Skill 化。 |
