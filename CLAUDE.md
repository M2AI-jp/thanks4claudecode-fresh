# CLAUDE.md

> **敬語かつ批判的なプロフェッショナル。質問するな、実行せよ。間違いには NO。**

> **CONTEXT.md を読め。質問する前に参照せよ。**

@.claude/CLAUDE-ref.md

---

## INIT（セッション開始時）【絶対ルール】

> **ユーザーのメッセージに応答する前に、以下を必ず完了せよ。スキップは許可されていない。**

```
【フェーズ 1: 5点読み込み】※ユーザー応答前に必須

  1. Read: CONTEXT.md
  2. Read: state.md
  3. Read: plan/roadmap.md（上位計画書）
  4. Read: playbook（active_playbooks から特定、なければ null）
  5. Read: plan/project.md（存在する場合のみ）

  ⚠️ Hook 出力を「見た」だけでは不十分。Read ツールで実際に読め。
  ⚠️ Read 未完了でユーザーに応答するな。

【フェーズ 2: git/branch 状態取得】

  6. Bash: `git rev-parse --abbrev-ref HEAD`
  7. Bash: `git status -sb`
  8. main ブランチ AND session=task → ブランチを切る

【フェーズ 3: playbook 準備】

  9. playbook=null AND session=task → /playbook-init を実行

【フェーズ 4: 宣言】

  10. [自認] を出力

【フェーズ 5: Macro チェック & 自律行動】

  11. plan/project.md の done_when を確認
  12. current_phase.tasks から未完了タスクを特定
  13. 宣言して作業開始:
      「Macro: {project.md の summary}
       残タスク: {未完了タスクのリスト}
       → {next_task} を進めます。」
  14. LOOP に入る（ユーザーが止めない限り進む）

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
macro_goal: {plan/project.md の summary}
remaining_tasks: {project.md の current_phase.tasks で未完了のもの}
playbook: {active_playbooks.{focus.current}}
done_criteria: {goal.done_criteria を列挙}
git_status: {clean | modified | untracked}
last_critic: {null | PASS | FAIL}
```

> **根幹**: focus-state-playbook-branch は連動。不一致なら警告を出し、修正を実行。

---

## LOOP（テスト駆動作業ループ）

```
while true:
  1. playbook の done_criteria を「テスト」として読む
  2. 各 done_criteria: 証拠がある→PASS、ない→EXEC()
  3. 全て PASS → CRITIQUE() を実行
     - CRITIQUE PASS → state.md 更新 → 次の Phase へ
     - CRITIQUE FAIL → 問題を修正 → continue
  4. 何をすべきかわからない → break
```

**証拠の例**: `ls` 出力、実行結果、該当箇所の引用

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

## CRITIQUE（自己批判ループ）【絶対ルール】

> **Phase/layer を done にする前に、必ず critic エージェントを実行せよ。**

```yaml
1. critic なしの done 更新は禁止
2. critic 実行: Task(subagent_type="critic") または /crit
3. critic PASS → done に更新してよい
4. critic FAIL → 修正 → 再度 critic
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
```

---

## CONTEXT（コンテキスト管理）

> **コンテキストが膨らんだらルールが効かなくなる。外部ファイルを真実源とし、積極的にリセットせよ。**

```yaml
真実源:
  - CONTEXT.md / state.md / roadmap / playbook が唯一の真実
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
| 2025-12-02 | V3.1: 複数階層 plan 運用（roadmap）対応。 |
| 2025-12-02 | V3.0: 二層構造化。core を 200 行以下に最小化。 |
| 2025-12-02 | V2.1: CONTEXT セクション追加。 |
| 2025-12-02 | V2.0: メタ認知強化版。 |
| 2025-12-01 | V1.0: 初版。 |
