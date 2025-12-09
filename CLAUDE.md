# CLAUDE.md

> **【即時実行】このファイルを読んだ直後、INIT セクションを実行せよ。[自認]出力までユーザーに応答するな。違反 → init-guard.sh がブロック（exit 2）。**

> **【三位一体】Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）。単独では機能しない。組み合わせて初めて強制力を持つ。**

> **【報酬詐欺防止】「完了」の自己判断禁止。critic SubAgent が PASS を返すまで done 不可。1回で終わらせようとする衝動に抗え。LOOP を回し続けよ。**

> **【自律 ≠ 勝手】project.md → playbook → Phase の連鎖から次を導出。待つな。しかしユーザーの意図を推測で補完するな。不明 → 質問。「確認」はするな。**

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

【フェーズ 3: playbook 準備】

  7. playbook=null → /playbook-init を実行（Edit/Write 時にブロックされる前に）

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

> **ユーザープロンプトの誤解釈防止。「入力→LLM処理→出力」ではなく「LLM処理→構造化出力→合意→出力」を強制。**

```yaml
# ========================================
# 問題
# ========================================

problem: |
  Claude がユーザープロンプトを「良かれと思って省略」し、
  意図しない大規模変更や方向性のずれが発生する。

# ========================================
# 解決: [理解確認] ブロック
# ========================================

solution: |
  Edit/Write 前に処理結果を構造化出力し、ユーザー合意を取得。
  Hook（consent-guard.sh）で合意ファイルの有無をチェック。

# ========================================
# [理解確認] フォーマット
# ========================================

format: |
  [理解確認]
  what: 「〇〇をすること」と理解しました
  why: 目的は「△△」と推測します
  how: 以下の手順で進めます
    1. ...
    2. ...
    3. ...
  scope: 変更対象ファイル
    - file1.ts
    - file2.ts
  exclusions: 以下は変更しません
    - config.json
    - CLAUDE.md

# ========================================
# ユーザー応答フロー
# ========================================

user_response:
  OK: |
    「了解」または「OK」→ Claude がファイルを削除（.claude/.session-init/consent）→ 処理開始
  修正: |
    「〇〇ではなく△△です」→ Claude が [理解確認] を再出力 → 再合意
  却下: |
    「やめて」または「キャンセル」→ 処理中止

# ========================================
# Hook 統合
# ========================================

hook_integration:
  hook_name: consent-guard.sh
  trigger: PreToolUse:Edit/Write
  location: .claude/hooks/consent-guard.sh

  workflow: |
    1. session-start.sh:
       → .claude/.session-init/pending 作成
       → .claude/.session-init/consent 作成

    2. init-guard.sh:
       → pending 存在 → Read 強制
       → Read 完了 → pending 削除

    3. [理解確認]:
       → Claude が処理結果を構造化出力
       → ユーザー応答待機

    4. consent-guard.sh:
       → consent ファイル存在?
       → YES（ユーザー OK) → ファイル削除 → 通過 → Edit/Write 実行
       → NO（未承認） → exit 2 ブロック → [理解確認] 再表示

    5. playbook-guard.sh:
       → playbook チェック → 通過

    6. LOOP:
       → done_criteria 検証 → 実行

file_locations:
  pending: .claude/.session-init/pending
  consent: .claude/.session-init/consent

# ========================================
# 実装状態
# ========================================

status: implemented

components:
  consent_guard_sh:
    file: .claude/hooks/consent-guard.sh
    status: created
    functionality: consent ファイルの有無を確認、exit 2 でブロック

  settings_json:
    file: .claude/settings.json
    status: REGISTERED
    hook: PreToolUse:Edit/Write
    script: consent-guard.sh

  session_start_sh:
    file: .claude/hooks/session-start.sh
    status: INTEGRATED
    new_functionality: consent ファイル作成機能追加

  claude_md:
    file: CLAUDE.md
    section: CONSENT
    status: DOCUMENTED
    purpose: workflow および Hook 統合を記載

# ========================================
# 禁止パターン
# ========================================

forbidden:
  - [理解確認] なしで Edit/Write 実行
  - ユーザー応答なしで consent ファイル削除
  - consent ファイル作成後、[理解確認] を出力しない
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
  1. project.done_when の更新:
     - derives_from で紐づく done_when.status を achieved に
  2. 次タスクの導出（計画の連鎖）:
     - project.md の not_achieved を確認
     - depends_on を分析し、着手可能な done_when を特定
     - decomposition を参照して新 playbook を作成
  3. 残タスクあり:
     - 新ブランチ作成: git checkout -b feat/{next-task}
     - 新 playbook 作成: plan/active/playbook-{next-task}.md
     - state.md 更新: active_playbooks.product を更新
     - 即座に LOOP に入る
  4. 残タスクなし:
     - 「全タスク完了。次の指示を待ちます。」

禁止:
  - 「報告して待つ」パターン（残タスクがあるのに止まる）
  - ユーザーに「次は何をしますか？」と聞く
```

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
| 2025-12-09 | V5.2: 合意プロセス（CONSENT）。INIT に フェーズ 4.5 追加。playbook=null 時に [理解確認] を強制。ユーザー応答待ちを例外許可。 |
| 2025-12-08 | V5.1: 計画の連鎖（Plan Derivation）。project.done_when → playbook の自動導出。INIT/POST_LOOP 更新。 |
| 2025-12-08 | V5.0: アクションベース Guards。session 分類廃止。Edit/Write 時のみ playbook チェック。意図推測不要に。 |
| 2025-12-08 | V4.1: 構造的強制。Hook が session を TASK にリセット → NLU で判断 → 安全側フォール。キーワード判定完全廃止。 |
| 2025-12-08 | V4.0: session 自動判定システム。prompt-validator.sh がキーワード判定 → state.md 自動更新。Claude 依存を排除。 |
| 2025-12-08 | V3.4: PROMPT_VALIDATION 追加。全プロンプトを project.md と照合。ROADMAP_CHECK を置換。 |
| 2025-12-08 | V3.3: CONTEXT.md 廃止。state.md/project.md/playbook を真実源に。INIT 簡素化。 |
| 2025-12-08 | V3.2: 報酬詐欺防止強化。LOOP に根拠確認、CRITIQUE に検証項目追加。 |
| 2025-12-02 | V3.1: 複数階層 plan 運用（roadmap）対応。 |
| 2025-12-02 | V3.0: 二層構造化。core を 200 行以下に最小化。 |
| 2025-12-02 | V2.1: CONTEXT セクション追加。 |
| 2025-12-02 | V2.0: メタ認知強化版。 |
| 2025-12-01 | V1.0: 初版。 |
