# CLAUDE-ref.md（リファレンス）

> **詳細なルールと手順。CLAUDE.md から @import で参照される。**

---

## NEW_TASK（新タスク開始時の再初期化）

> **以下のいずれかに該当するとき、「新タスク開始」とみなす。**

```yaml
トリガー条件:
  - ユーザーが「新しい機能」「別のタスク」「別のブランチでやりたい」などと言った
  - git checkout / git switch でブランチを変更した
  - playbook 内で別の Phase を in_progress に変更する
  - focus.current を切り替えた（/focus または state-mgr の結果）
  - 現在の playbook の全 Phase が done になった

行動ルール:
  新タスク開始と判断した場合、必ず INIT を最初からやり直す:
    1. Read: state.md, plan/project.md, playbook
    2. git branch / status の再取得
    3. [自認] の再宣言
    4. LOOP に入る

⚠️ 同一セッション内でも、タスクが切り替わったら INIT 再実行は必須。
```

---

## EXPLAIN（非エンジニア向け説明）

```
重要タイミングで一言説明を添える:
- セッション開始: 「ブランチ＝下書き用の作業スペースです」
- ブランチ作成: 「失敗しても本線（main）に影響しません」
- コミット: 「コミット＝セーブポイントです」
- マージ: 「作業を本番に統合します」

原則: 専門用語→比喩で言い換え、1-2文で短く
```

---

## EXEC（作業実行詳細）

### コード編集後の必須チェック

```yaml
直近の変更ファイル取得:
  Bash: `git diff --name-only` または `git status -sb`

1. TypeScript / JavaScript 変更時:
   条件: 変更ファイルに .ts / .tsx / .js / .jsx が含まれる
   行動: Skill: "lint-checker" を必ず呼び出す

2. テストファイル変更時:
   条件: 変更ファイルに *.test.* / *.spec.* / test/ 配下が含まれる
   行動: Skill: "test-runner" を必ず呼び出す

3. デプロイ関連の Phase 完了時:
   条件: done_criteria に「デプロイ」が含まれる
   行動: Skill: "deploy-checker" を必ず呼び出す
```

### FOCUS と編集範囲の整合性チェック

```yaml
ファイル編集前の必須手順:
  1. state.md を再度 Read し、最新の focus.current を取得
  2. rules.{focus.current}.editable を確認
  3. 編集対象ファイルが editable に含まれているか判定

不一致時の行動:
  - 原則: 編集しない
  - 必要な場合:
    - state-mgr エージェントまたは /focus を用いて focus.current を切り替える
    - なぜ cross-layer 編集が必要かを短く説明する
```

---

## TEST_VERIFICATION（テスト検証ルール）

> **テスト完了を報告する前に、必ず出力を精査し引用すること。**

```yaml
禁止:
  - EXIT:0 だけで「PASS」と報告
  - 出力を読まずに「テストが通った」と主張
  - 「何もしなかった」と「成功した」を混同

必須:
  - テスト出力を精査した証拠を示す
  - 期待通りの出力があったことを引用で証明
  - 問題があれば修正してから再テスト

テスト報告フォーマット:
  1. テスト実行コマンドを示す
  2. 出力の関連部分を引用
  3. 期待値との比較を明記
  4. EXIT code を確認

例（正しい報告）:
  出力: `━━ [依存関係] state.md ━━ → 現在のactive_playbook`
  期待: 依存ファイルが表示される
  判定: ✓ 一致
  EXIT: 0

例（誤った報告）:
  ✗ EXIT:0 だったので PASS です
  ✗ テストを実行しました。問題ありません。
```

---

## STATE MACHINE（state.md 更新ルール）

> **state.md を編集するとき、必ず以下の手順を踏む。**

```yaml
1. 変更前の state 取得:
   - Read: state.md
   - 各 layer の current state を控える

2. forbidden 遷移の確認:
   - state.md の transitions.forbidden を参照
   - 禁止リスト:
     - [pending, implementing]     # designing をスキップ
     - [pending, done]             # 全てをスキップ
     - [designing, done]           # implementing をスキップ
     - [implementing, done]        # state_update をスキップ
     - [reviewing, done]           # state_update をスキップ

3. 変更計画のチェック:
   - 自分が行おうとしている遷移（from → to）が forbidden か確認
   - forbidden に該当する場合:
     - その変更を行ってはならない
     - 正しい中間 state を踏むように playbook/state を修正
     - または「この遷移は forbidden なので別の段階を踏みます」と説明

4. 実際の編集:
   - forbidden でないことを確認してから Edit を実行
```

---

## state.md セクション分類

> **state.md 内のセクションは「動的」と「静的」に分類される。**

```yaml
動的セクション（毎セッション更新される）:
  - focus, security, active_playbooks
  - context, plan_hierarchy, project_context
  - layer.*.state / sub / playbook
  - goal（phase, done_criteria）
  - verification（self_complete, user_verified）
  - session_tracking（Hooks が自動更新）

静的セクション（変更禁止）:
  - ## states（状態遷移ルール）
  - ## rules（編集権限定義）

禁止事項:
  - 静的セクションを編集してはならない
  - 静的セクションは state.md 内で定義されている

動的セクションの編集タイミング:
  - セッション開始時: session_tracking（自動）
  - 作業開始時: goal.phase
  - 作業完了時: layer.*.state, verification.self_complete
  - Phase 変更時: goal.done_criteria, active_playbooks
```

---

## /playbook-init（playbook 初期化コマンド）

> **現在のブランチと 1:1 に紐づく playbook を作成するコマンド。**

```yaml
役割:
  - plan/active/ 以下に新しい playbook を作成
  - state.md の active_playbooks を更新
  - ブランチと playbook の 1:1 対応を確立

実行前チェック:
  1. 現在のブランチに対応する playbook が既に存在するか確認
  2. 存在する場合の方針決定:
     - 推奨: 「新しいタスクなので、新ブランチ + 新 playbook を作成します」
     - または: 「既存 playbook を拡張します」
     - 理由を述べてから実行する

意味の説明（初回実行時に宣言）:
  - 「/playbook-init は、このブランチ専用の playbook（計画書）を作成します。」
  - 「既存の playbook を破壊したり、Claude 本体の初期化をするものではありません。」

実行後:
  - 作成した playbook を Read
  - [自認] の playbook / done_criteria を更新
  - state.md の active_playbooks に追記
```

---

## BEFORE_ASK（質問判定）

```
基本ルール:
  1. state.md / project.md / playbook を再読
  2. 答えがあるか? → YES なら質問するな、即実行

質問してはいけない例:
  - 「これでよいですか?」（確認求め）
  - 「〇〇しますか?」（するに決まっている）
  - 「A と B、どちらにしますか?」（自分で判断すべき）
```

### 安全上の例外（確認を行うべきケース）

```yaml
以下のケースでは「例外的に確認・説明を行ってよい」:

1. BLOCK 指定された保護ファイルの編集提案:
   - 対象: CLAUDE.md, .claude/hooks/*.sh など
   - 行動: 直接編集せず、変更案をテキストで提示
   - 説明: 「適用するかどうかはユーザーの判断が必要です」

2. 破壊的・取り返しのつかない操作:
   - 対象: データ削除、履歴書き換え（git push --force 等）
   - 行動: 実行前に「こういうリスクがあります」と説明
   - 判断はユーザーに委ねる

3. playbook の上書き・再生成:
   - 対象: /playbook-init による既存 playbook の無効化/再作成
   - 行動: やろうとしていることと影響を説明

⚠️ これらは「確認禁止ルールの例外」であり、通常の確認求めとは区別する。
```

---

## BRANCH（Git 運用詳細）

```yaml
四つ組の連動:
  - focus.current + layer.state + playbook + branch
  - playbook.branch = 現在のブランチ（1:1 対応）

ブランチ命名: fix|feat|refactor|docs|test/{description}

AUTO_MERGE 条件:
  - 全 Phase done + critic PASS + coherence PASS
  - 条件を満たしたら自律的にマージ実行
```

---

## SECURITY（セキュリティ詳細）

```yaml
bypassPermissions モード有効:
  - 許可不要: git操作, Edit, Write, 許可リストの Bash
  - 確認必要: sudo, rm -rf /, git push --force

外部URL:
  - 公式ドキュメントのみ（*.dev, docs.*, github.com公式）
  - 個人ブログ/StackOverflow/Q&Aサイト禁止
  - ユーザー指定URLは例外

MCP: context7 を活用（ライブラリの公式ドキュメント取得）
```

---

## 許可事項

```
✅ state.md / project.md から読み取れないことだけ質問（BEFORE_ASK必須）
✅ done_criteria を満たしたら次のPhaseに進む
✅ 問題発見 → 即座に修正（許可不要）
✅ 複数の選択肢 → 最適なものを自分で選んで実行
✅ CRITIQUE で問題発見 → 即座に修正 → 作業続行
✅ 安全上の例外に該当する場合のみ確認を行う
```

---

## END（LOOP終了条件）

```
1. state.md / project.md を読んでも次に何をすべきかわからない
2. 全てのPhaseが完了した（CRITIQUE経由、critic PASS 必須）
3. ユーザーからの新しい指示を待つ必要がある
```

---

## DISPATCH（エージェント起動条件）

> **発動率 100% のための具体的トリガー例。該当したら必ず Task ツールを使用。**

---

### plan-guard【必須・最優先・自己実行】

> **注**: plan-guard は SubAgent ではなく、LLM が参照する設計ドキュメント。
> `.claude/agents/plan-guard.md` を読み、そのロジックに従って自己判断を行う。

**セッション開始時（ユーザー入力前）:**
- INIT 完了後、[自認] 宣言の直後
- `.claude/agents/plan-guard.md` を Read
- 3層計画（Macro/Medium/Micro）を確認・提示
- 「今日は〇〇をやります。よろしいですか？」と提示

**ユーザープロンプト受信時:**
- 要求と現在の playbook の整合性をチェック
- 計画外の要求には警告を出す

**シナリオ別の判断（plan-guard.md 参照）:**
- S0: PLAN_PRESENTED（計画提示）
- S1: PLAN_REQUIRED（計画なし→作成強制）
- S2: PLAN_MISMATCH（計画外→確認）
- S3: PLAN_ALIGNED（計画内→続行）
- S4: MACRO_REQUIRED（Macro なし→作成強制）
- S5: MEDIUM_REQUIRED（Medium なし→作成強制）

❌ **plan-guard ロジックを無視した作業開始は禁止**
❌ **ユーザープロンプトを無条件に実行してはならない**

---

### critic【必須】

以下の状況では、**必ず** `Task(subagent_type='critic')` を使用すること：

- 「Phase X が完了した」「done にする」と判断したとき
- 「全ての done_criteria を満たした」と判断したとき
- state.md の `layer.*.state` を `done` に変更しようとしているとき
- 「完了」「終わり」「達成」などの言葉を出力しようとしているとき

❌ **critic PASS なしでの done 更新は禁止**
手動: `/crit`

---

### pm【必須】

以下のユーザー発言を検出したら、**必ず** `Task(subagent_type='pm')` を使用すること：

**新機能リクエスト（playbook 作成が必要）:**
- 「〇〇を作って」「〇〇を実装して」「〇〇を追加して」
- 「TODOアプリ作りたい」「チャットアプリ作って」「認証機能を追加して」
- 「新しい機能を追加したい」「リファクタリングしたい」

**スコープ外の判定が必要:**
- 「ついでに〇〇も」「ちょっと〇〇を変えて」「ここも直して」
- 現在の playbook にない作業をしようとしているとき

**playbook=null エラー:**
- Edit/Write 時に playbook が null のとき（playbook-guard がブロック）

❌ **pm を呼ばずに新 playbook を作成してはならない**
❌ **スコープ外には NO と言う**

---

### coherence【自動・Hook】

整合性チェックは **check-coherence.sh Hook** が自動実行します。

- **自動発火**: git commit 前（PreToolUse:Bash）
- **手動実行**: `bash .claude/hooks/check-coherence.sh`

SubAgent は削除されました（Hook で十分なため）。

---

### state 管理【Skill】

state.md の管理は **state Skill** が提供します。

- **場所**: .claude/skills/state/skill.md
- **用途**: focus 切り替え、state.md の構造理解
- **呼び出し**: `Skill: "state"`

SubAgent は削除されました（Skill で十分なため）。

---

### setup-guide【自動】

以下の状況では、**必ず** `Task(subagent_type='setup-guide')` を使用すること：

- focus.current = setup のとき
- 新規ユーザーがフォークしてきたとき

---

### beginner-advisor【Skill】

初学者向け説明は **beginner-advisor Skill** が提供します。

- **場所**: .claude/skills/beginner-advisor/skill.md
- **自動発火**: state.md の learning_mode.expertise = beginner 時
- **呼び出し**: `Skill: "beginner-advisor"`

SubAgent は削除されました（Skill で十分なため）。

---

### 発動ログ記録（全エージェント共通）

```yaml
発動時: .claude/logs/subagent-dispatch.log に記録
フォーマット: "ISO8601 | AGENT_NAME | TRIGGER | RESULT"
例: "2025-12-03T18:30:00+09:00 | critic | Phase完了前 | PASS"
```

---

## CODEX_HANDOFF（Codex へのタスク委譲）

```yaml
トリガー: Phase.executor = "codex" AND status = "in_progress"

行動:
  1. MCP ツール mcp__codex__* で Codex にタスク送信
  2. 渡す情報:
     - Phase.goal / done_criteria
     - AGENTS.md（コーディングルール）
     - 関連ファイルパス
  3. 渡さない情報:
     - state.md 全体（不要）
     - playbook 全体（該当 Phase のみ）
  4. Codex 完了後、done_criteria で検証
  5. 問題あれば修正指示を再送

安全ルール:
  - commit/push は Claude Code が実行（Codex は編集のみ）
  - 保護ファイルは渡さない
```

---

## 参照

| ファイル | 内容 |
|----------|------|
| state.md | 現在地、goal、done_criteria |
| plan/project.md | Macro 計画（最終目標） |
| playbook | タスク管理、Phase定義 |

**他のドキュメントを参照するな。新規作成するな。**

---

## done 判定前チェック（詳細）

```yaml
evidence_check:
  - [ ] done_criteria の全項目に「証拠」を示せるか?
  - [ ] 証拠は「コマンド実行結果」または「ファイル引用」か?
  - [ ] 「満たしている気がする」で判定していないか?
  - [ ] 「設定した」ではなく「動作確認した」か?

critic_check:
  - [ ] critic エージェントを呼び出したか?
  - [ ] critic が PASS を返したか?
  - [ ] critic が指摘した問題を全て解決したか?

test_execution:
  - [ ] playbook の test_method を実際に実行したか?
  - [ ] test_method の期待結果と一致したか?

⚠️ 証拠なしの done は禁止
⚠️ 「設定した」≠「動く」（必ず実行して確認）
```

### 自己報酬詐欺の検出パターン

```yaml
言語パターン（危険信号）:
  - 「〇〇した」だけで証拠なし
  - 「〇〇のはず」「〇〇だと思う」
  - 「シミュレーションでは...」（実行なし）
  - 「設計上は...」（動作確認なし）

行動パターン（危険信号）:
  - done_criteria の一部のみ確認
  - critic を呼び出さずに done 判定
  - test_method を実行せずに PASS
  - 机上の検討のみで実装完了と主張

検出時の行動:
  1. 即座に critic エージェントを呼び出す
  2. 不足している証拠を収集
  3. 問題を修正してから再判定
```
