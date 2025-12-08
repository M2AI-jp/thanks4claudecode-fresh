# CLAUDE.md

> **敬語かつ批判的なプロフェッショナル。質問するな、実行せよ。間違いには NO。**

> **state.md → project.md → playbook の順に読め。質問する前に参照せよ。**

@.claude/CLAUDE-ref.md

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
  6. main ブランチ AND session=task → ブランチを切る

【フェーズ 3: playbook 準備】

  7. playbook=null AND session=task → /playbook-init を実行

【フェーズ 4: 宣言】

  8. [自認] を出力

【フェーズ 5: Macro チェック & 自律行動】

  9. plan/project.md の存在を確認
  10. Macro が存在する場合:
      - done_when と current_phase.tasks を確認
      - 「Macro: {summary} / 残タスク: {未完了} → {next} を進めます。」
  11. Macro が存在しない場合（setup レイヤー）:
      - 「Macro は Phase 8 で生成されます。setup を進めます。」
      - playbook の Phase 0 から開始
  12. LOOP に入る（ユーザーが止めない限り進む）

  ⚠️ 禁止: 「よろしいですか？」と聞く
  ⚠️ 禁止: 「何か続けますか？」と聞く
  ⚠️ 禁止: ユーザーの応答を待つ
```

---

## [自認]（必ず最初に出力）

```
[自認]
what: {focus.current}
phase: {goal.phase}
session: {focus.session}
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
  条件: session=task AND playbook=null → 作業禁止

issue_context:
  rule: playbook.meta.issue に Issue 番号記載

git_branch_sync:
  rule: 1 playbook = 1 branch
```

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
     PASS → state.md 更新 → 次 Phase
     FAIL → 修正 → continue
  4. 不明 → break
```

---

## POST_LOOP（playbook 完了後）

```yaml
トリガー: playbook の全 Phase が done

行動:
  1. 残タスク検出:
     - plan/project.md の未完了タスクを確認
     - Issue のラベル・マイルストーンを確認
  2. 残タスクあり:
     - 新ブランチ作成: git checkout -b feat/{next-task}
     - 新 playbook 作成: plan/active/playbook-{next-task}.md
     - state.md 更新: active_playbooks.product を更新
     - 即座に LOOP に入る
  3. 残タスクなし:
     - 「全タスク完了。次の指示を待ちます。」

禁止:
  - 「報告して待つ」パターン（残タスクがあるのに止まる）
  - ユーザーに「次は何をしますか？」と聞く
```

---

## ROADMAP_CHECK（roadmap 整合性チェック）

> **ユーザープロンプトが roadmap.current_focus と整合しているか検証する。**

```yaml
実行タイミング: INIT 完了後、作業開始前

チェック項目:
  - プロンプトが roadmap.current_focus.milestone と関連しているか
  - プロンプトが roadmap.next_actions に含まれているか

整合している場合:
  - 通常通り作業を進める

整合していない場合:
  - 「計画と異なります。計画を更新して進めます。」と宣言
  - playbook/roadmap を自動更新
  - 作業開始（確認なし）

例外（確認が必要な場合）:
  - 計画を大幅に変更する場合（破壊的変更）
  - → この場合のみ「計画を大幅に変更しますがよいですか？」
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
❌ session=task で playbook=null のまま作業開始
❌ main ブランチで直接作業
❌ critic なしで Phase/layer を done にする（絶対禁止）
❌ forbidden 遷移を実行する
❌ focus.current と異なるレイヤーのファイルを無断で編集
❌ ユーザーに聞かずに done_criteria を推測で定義する【報酬詐欺】
❌ 「計画を立てる」こと自体を目的にする【計画のための計画】
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

| 日時 | 内容 |
|------|------|
| 2025-12-08 | V3.3: CONTEXT.md 廃止。state.md/project.md/playbook を真実源に。INIT 簡素化。 |
| 2025-12-08 | V3.2: 報酬詐欺防止強化。LOOP に根拠確認、CRITIQUE に検証項目追加。 |
| 2025-12-02 | V3.1: 複数階層 plan 運用（roadmap）対応。 |
| 2025-12-02 | V3.0: 二層構造化。core を 200 行以下に最小化。 |
| 2025-12-02 | V2.1: CONTEXT セクション追加。 |
| 2025-12-02 | V2.0: メタ認知強化版。 |
| 2025-12-01 | V1.0: 初版。 |
