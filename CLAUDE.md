# CLAUDE.md

> **【即時実行】このファイルを読んだ直後、INIT セクションを実行せよ。[自認]出力までユーザーに応答するな。違反 → init-guard.sh がブロック（exit 2）。**

> **【三位一体】Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）。単独では機能しない。組み合わせて初めて強制力を持つ。**

> **【報酬詐欺防止】「完了」の自己判断禁止。critic SubAgent が PASS を返すまで done 不可。1回で終わらせようとする衝動に抗え。LOOP を回し続けよ。**

> **【自律 ≠ 勝手】project → playbook → phase の3層連鎖から次を導出。待つな。しかしユーザーの意図を推測で補完するな。不明 → 質問。「確認」はするな。**

> **【タスク標準化】全タスク開始は pm SubAgent 経由必須。直接 playbook を作成するな。pm → project.milestone 参照 → derives_from 設定 → playbook 作成。**

> **【3層自動運用】project（永続）→ playbook（一時）→ phase（作業単位）。Claude が主導管理。人間は意思決定とプロンプト提供のみ。**

---

## 3層構造

```yaml
project:
  定義: リポジトリ全体のビジョンと目標（永続）
  ファイル: plan/project.md
  子要素: milestone（中間目標）

milestone:
  定義: project の中間目標
  ID形式: M001, M002, ...
  紐付け: playbook.meta.derives_from で参照

playbook:
  定義: milestone を達成するための実行計画（一時的）
  ファイル: plan/active/playbook-{name}.md
  完了後: アーカイブ + project.milestone 自動更新
  子要素: phase

phase:
  定義: playbook 内の作業単位
  ID形式: p0, p1, p2, ...
  完了条件: done_criteria[]
```

---

## INIT（セッション開始時）【絶対ルール】

> **ユーザーのメッセージに応答する前に、以下を必ず完了せよ。スキップは許可されていない。**

```
【フェーズ 1: 必須読み込み】※ユーザー応答前に必須

  1. Read: state.md（現在地・goal・milestone）
  2. Read: plan/project.md（プロジェクト計画）
  3. Read: playbook（playbook.active から特定、なければ null）
  4. Read: docs/feature-map.md（機能マップ）

  ⚠️ Hook 出力を「見た」だけでは不十分。Read ツールで実際に読め。
  ⚠️ Read 未完了でユーザーに応答するな。

【フェーズ 2: git/branch 状態取得】

  5. Bash: `git rev-parse --abbrev-ref HEAD`
  6. Bash: `git status -sb`
  7. main ブランチ → ブランチを切る

【フェーズ 3: playbook 準備】★pm 経由必須

  8. playbook=null → pm SubAgent を呼び出す
     - pm が project.milestone を参照して playbook を作成
     - derives_from を必ず設定（milestone ID）
     - ブランチ作成も pm が実行
     ⚠️ pm を経由せずに直接 playbook を作成することは禁止

【フェーズ 4: 宣言】

  9. [自認] を出力

【フェーズ 4.5: 5W1H 自動構造化 & [理解確認]】★重要

  条件: playbook=null の場合のみ実行（計画がない = 新規タスク）

  10. ユーザープロンプトを自動的に 5W1H 形式で構造化
  11. [理解確認] を出力（5W1H形式）:

      ```
      [理解確認]
      What（何を）:
        「〇〇を実装/作成/修正すること」と理解しました

      Why（なぜ）:
        目的: 「△△という課題を解決するため」
        背景: 「□□という状況があるため」

      Who（誰が）:
        - claudecode: ファイル作成・編集
        - user: 外部サービス登録（該当する場合）

      When（いつまでに）:
        特に期限指定なし

      Where（どこに）:
        新規: docs/xxx.md
        更新: .claude/hooks/xxx.sh
        変更なし: CLAUDE.md

      How（どのように）:
        1. 〇〇を調査
        2. △△を設計
        3. □□を実装
      ```

  12. ユーザーが「OK」→ consent ファイル削除 → フェーズ 5 へ進む

  スキップ条件:
    - playbook が既に存在する（計画済み）
    - compact/resume トリガー（セッション継続）

【フェーズ 5: project チェック & 計画の導出】

  13. plan/project.md の存在を確認
  14. playbook=null かつ project が存在する場合:
      - project.milestones から not_started/in_progress を確認
      - depends_on を分析し、着手可能な milestone を特定
      - pm を呼び出して playbook を作成
      - 「project: {goal} / 次: {milestone.name} を進めます。」
  15. playbook がある場合:
      - 現在の phase を確認し LOOP に入る
  16. project が存在しない場合（setup）:
      - 「project は setup 完了後に生成されます。」
      - playbook の phase 0 から開始
  17. LOOP に入る（ユーザーが止めない限り進む）

  ⚠️ 禁止: 「よろしいですか？」と聞く
  ⚠️ 禁止: 「何か続けますか？」と聞く
```

---

## [自認]（必ず最初に出力）

```
[自認]
what: {focus.current}
milestone: {goal.milestone}
phase: {goal.phase}
branch: {現在のブランチ名}
project_summary: {plan/project.md の vision.goal}
remaining: {残りの milestone 数 | 残りの phase 数}
playbook: {playbook.active}
done_criteria: {現在の phase.done_criteria を列挙}
git_status: {clean | modified | untracked}
last_critic: {null | PASS | FAIL}
```

---

## CORE（原則）

```yaml
three_layer_system:
  rule: project → playbook → phase の3層で自動運用
  project: 永続（milestone で進捗管理）
  playbook: 一時（完了→アーカイブ→milestone更新）
  phase: 作業単位（critic PASS で完了）

pdca_autonomy:
  rule: playbook 完了 → milestone 更新 → 次 playbook 自動作成
  禁止: ユーザープロンプトを待つ

clear_timing:
  rule: playbook 完了時に /clear 推奨をアナウンス
  理由: コンテキスト汚染を防ぎ、動作を安定させる

tdd_first:
  rule: done_criteria = テスト仕様
  条件: 根拠 = ユーザー発言引用 | 検証可能指標
  禁止: 根拠なき done_criteria

validation:
  rule: critic は .claude/rules/frameworks/ を参照
  禁止: 都度生成の評価基準

plan_based:
  条件: playbook=null で Edit/Write → ブロック

git_branch_sync:
  rule: 1 playbook = 1 branch
```

---

## LOOP（V11: subtasks 構造対応）

```
iteration = 0
max = playbook.phase.max_iterations || 10

while true:
  iteration++
  if iteration > max: break  # デッドロック検出

  0. 根拠なし → ユーザーに質問
  1. subtasks を読む（criterion + executor + test_command）
  2. 各 subtask について:
     - executor: claudecode/codex → 自動実行
     - executor: coderabbit → レビュー実行
     - executor: user → ユーザー確認待ち（DEFERRED）
  3. test_command を実行して PASS/FAIL を判定
  4. 全 subtask PASS → CRITIQUE()
     - PASS → playbook 更新 → 自動コミット → 次 phase
     - FAIL → 修正 → continue
  5. 不明 → break

executor 選択ガイドライン:
  claudecode: ファイル作成、設計、軽量スクリプト
  codex: 本格的なコード実装
  coderabbit: コードレビュー
  user: 手動確認、外部操作

phase 完了時の自動コミット:
  条件: critic PASS 後
  実行:
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
```

---

## POST_LOOP（playbook 完了後）

> **詳細: @.claude/skills/post-loop/skill.md**

playbook の全 phase が done → 以下を自動実行:

```yaml
フロー:
  1. 自動コミット（最終 phase 分）
  2. playbook をアーカイブ
  3. project.milestone を自動更新
     - status = achieved
     - achieved_at = now()
     - playbooks[] に追記
  4. ★ /clear 推奨アナウンス ★
  5. 次の milestone を特定（depends_on 分析）
  6. pm で新 playbook を自動作成
  7. PR 作成・マージ（オプション）

/clear 推奨アナウンス:
  ┌────────────────────────────────────────────────┐
  │ 🎉 playbook 完了: {playbook_name}              │
  │                                                │
  │ 📊 project 進捗: {X}/{Y} milestones            │
  │                                                │
  │ ⚠️ /clear を実行してください                   │
  │    コンテキストがリフレッシュされ、            │
  │    動作が安定します。                          │
  └────────────────────────────────────────────────┘

禁止: 「報告して待つ」パターン
```

---

## ACTION_GUARDS（アクションベース制御）

```yaml
設計思想:
  - Edit/Write 時のみ playbook チェック
  - Read/Grep/WebSearch 等は常に許可
  - プロンプトの「意図」ではなく「アクション」を制御

⚠️ playbook なしで Edit/Write → ブロック
⚠️ 調査・報告は playbook なしでも可能
```

---

## CRITIQUE

```yaml
条件: phase 完了前に critic 必須
実行: Task(subagent_type="critic")
参照: .claude/rules/frameworks/done-criteria-validation.md
PASS → phase.status = done
FAIL → 修正 → 再実行
```

---

## CONTEXT（コンテキスト管理）

```yaml
真実源:
  - state.md / project.md / playbook が唯一の真実
  - チャット履歴に依存しない

いつ /clear するか:
  - playbook が完了したとき（★推奨★）
  - コンテキスト使用率が 80% を超えたとき

/clear 後の必須行動:
  1. INIT を最初からやり直す
  2. [自認] を再宣言する
```

---

## 禁止事項

```
❌ 確認を求める、許可を求める、選ばせる（安全上の例外を除く）
❌ done_criteria 確認なしで「完了しました」
❌ 保護対象ファイルを無断で編集
❌ playbook=null で Edit/Write を実行
❌ main ブランチで直接作業
❌ critic なしで phase を done にする（絶対禁止）
❌ ユーザーに聞かずに done_criteria を推測で定義する【報酬詐欺】
❌ pm SubAgent を経由せずに直接 playbook を作成する
❌ playbook 完了時に /clear を案内せずに次に進む
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | V11: subtasks 構造対応。LOOP に executor 選択ガイドライン追加。旧形式（done_criteria リスト）との互換性維持。 |
| 2025-12-13 | V7.0: 3層構造（project→playbook→phase）の自動運用。用語統一（Macro廃止, layer廃止）。/clear タイミング明示。 |
| 2025-12-10 | V6.0: コンテキスト・アーキテクチャ再設計。 |
