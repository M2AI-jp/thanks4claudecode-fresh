# project.md

> **Macro 計画: LLM 自律制御システム - 三位一体アーキテクチャ**
>
> Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）= 統合制御
> 単独では機能しない。組み合わせて初めて強制力を持つ。

---

## vision

```yaml
summary: 仕組みの完成と実証 - LLM自律制御システム

goal: |
  どんなユーザープロンプトが入力されても、
  同一のワークフローが発火し、
  入力→処理→出力が明確に連鎖する仕組みを構築する。

why:
  問題: Claude Code は強力だが、計画なしで動くと暴走する
  解決: 三位一体アーキテクチャによる多層防御

三位一体:
  Hooks: 構造的強制（exit 2 でブロック）
  SubAgents: 検証（critic/pm/coherence）
  CLAUDE.md: 思考制御（ガイドライン遵守）

核心:
  - 「単独では機能しない」が設計思想
  - Hooks だけでは「いつ発火するか」しか制御できない
  - CLAUDE.md だけでは「読んでも無視できる」
  - 両方が連携して初めて「強制力」を持つ
```

---

## universal_workflow

> **確認事項 #1, #2 対応: どんなプロンプトでも同一ワークフローが発火**

```yaml
# ========================================
# 普遍的ワークフロー（Universal Workflow）
# ========================================
# どんなプロンプトでも → このフローを通過

trigger: ユーザープロンプト受信

flow:
  layer_1_session_start:
    hook: session-start.sh (SessionStart)
    action: |
      1. pending ファイル作成 → init-guard.sh が他ツールをブロック
      2. state.md の session_tracking を更新
      3. 必須 Read を強制
    claude_md: INIT セクション参照を強制

  layer_2_init_guard:
    hook: init-guard.sh (PreToolUse:*)
    action: |
      - pending ファイルが存在 → ブロック（exit 2）
      - 必須ファイル Read 完了 → pending 削除 → 通過
    claude_md: Read 完了まで [自認] を出力しない

  layer_3_prompt_guard:
    hook: prompt-guard.sh (UserPromptSubmit)
    action: |
      - スコープ外リクエスト → exit 2 でブロック
      - 開発関連リクエスト → 通過
    claude_md: playbook と照合、スコープ外は警告

  layer_4_playbook_guard:
    hook: playbook-guard.sh (PreToolUse:Edit/Write)
    action: |
      - playbook=null → exit 2 でブロック
      - playbook あり → 通過
    claude_md: pm を呼び出して playbook 作成

  layer_5_execution:
    hook: scope-guard.sh (PreToolUse:Edit/Write)
    action: スコープ外変更を警告
    claude_md: LOOP を回し続ける

  layer_6_critic_guard:
    hook: critic-guard.sh (PreToolUse:Edit)
    action: |
      - state: done への変更 + self_complete=false → exit 2 でブロック
    claude_md: critic SubAgent を呼び出し PASS を取得

  layer_7_stop:
    hook: stop-summary.sh (Stop)
    action: Phase 状態サマリーを出力
    claude_md: POST_LOOP で次タスク導出

# ========================================
# 連鎖の証明
# ========================================
chain_evidence:
  - session-start.sh → pending 作成 → init-guard.sh 発火
  - init-guard.sh → Read 強制 → INIT 完了
  - prompt-guard.sh → スコープ確認 → playbook 照合
  - playbook-guard.sh → playbook 必須 → pm 呼び出し
  - scope-guard.sh → スコープ内作業 → LOOP 継続
  - critic-guard.sh → done 判定 → critic 必須
  - stop-summary.sh → Phase サマリー → POST_LOOP
```

---

## tdd_and_fraud_prevention

> **確認事項 #7 対応: TDD と報酬詐欺防止（最重要）**

```yaml
# ========================================
# TDD（テスト駆動）の構造的実装
# ========================================

done_criteria_as_test:
  定義: done_criteria = テスト仕様
  構造: |
    playbook の各 Phase に done_criteria を定義
    done_criteria の各項目は「検証可能な条件」
    証拠なき done_criteria → critic FAIL

test_loop:
  while true:
    1. done_criteria を読む
    2. 証拠あり → PASS
    3. 証拠なし → 実行 → 証拠収集
    4. 全 PASS → critic 呼び出し
    5. critic PASS → Phase 完了
    6. critic FAIL → 修正 → 再試行

# ========================================
# 報酬詐欺防止の多層防御
# ========================================

layer_1_hook:
  名前: critic-guard.sh
  発火: PreToolUse:Edit
  条件: new_string に "state: done" を含む
  チェック: self_complete=true か?
  結果: false → exit 2 でブロック

layer_2_subagent:
  名前: critic SubAgent
  参照: .claude/frameworks/done-criteria-validation.md
  チェック:
    - 全 done_criteria に証拠があるか
    - 証拠は「コマンド出力」または「ファイル引用」か
    - 「〇〇のはず」「〇〇と思う」は証拠ではない
  結果: PASS → self_complete=true, FAIL → 修正要求

layer_3_claude_md:
  セクション: LOOP, CRITIQUE
  ルール:
    - 「1回で終わらせようとする衝動に抗え」
    - 「critic PASS なしで done 禁止」
    - 「証拠なき done は自己報酬詐欺」

# ========================================
# 検出パターン
# ========================================

fraud_signals:
  言語パターン:
    - 「〇〇した」だけで証拠なし
    - 「〇〇のはず」「〇〇と思う」
    - 「シミュレーションでは...」（実行なし）
    - 「設計上は...」（動作確認なし）
  行動パターン:
    - done_criteria の一部のみ確認
    - critic を呼び出さずに done 判定
    - test_method を実行せずに PASS
```

---

## playbook_doubt_ability

> **確認事項 #8 対応: playbook を疑う能力**

```yaml
# ========================================
# playbook を疑うタイミング
# ========================================

triggers:
  - Phase が行き詰まったとき
  - critic FAIL が連続したとき
  - done_criteria が達成不可能に見えるとき
  - ユーザーの意図と乖離しているとき

# ========================================
# 疑う手順
# ========================================

doubt_procedure:
  1. 現在の Phase の done_criteria を再確認
  2. done_criteria は「検証可能」か?
  3. done_criteria は「ユーザーの意図」に合致しているか?
  4. 合致しない場合:
     - playbook を修正（pm を呼び出す）
     - または ユーザーに確認（質問は可、確認は不可）
  5. .archive/plan/ の過去 playbook を参照:
     - 類似タスクの教訓を取得
     - 成功/失敗パターンを学習

# ========================================
# 過去 playbook 参照（learning Skill）
# ========================================

archive_reference:
  location: .archive/plan/
  contents:
    - 完了/中断した playbook
    - 過去の evidence / known_issues
  参照タイミング:
    - Phase が行き詰まったとき
    - 同種のタスクを開始するとき
  出力:
    - 成功パターン: 何が効果的だったか
    - 失敗パターン: 何を避けるべきか

# ========================================
# playbook 構造要件
# ========================================

playbook_structure:
  チェックボックス式: true
  各タスクの担当:
    - claude_code: Claude Code が実行
    - codex: OpenAI Codex に委譲
    - coderabbit: CodeRabbit でレビュー
    - user: ユーザーが実行
  TDD 必須: 各 Phase に test_method を定義
```

---

## phase_completion_output

> **確認事項 #9 対応: Phase 終了時の構造的出力**

```yaml
# ========================================
# Phase 完了サマリー（Stop Hook）
# ========================================

hook: stop-summary.sh (Stop)

output_structure:
  ┌─────────────────────────────────────────────────────────────┐
  │                    Phase 状態サマリー                       │
  ├─────────────────────────────────────────────────────────────┤
  │  Focus: {focus.current}                                    │
  │  Current Phase: {playbook.phase.name}                      │
  │  self_complete: {verification.self_complete}               │
  └─────────────────────────────────────────────────────────────┘

# ========================================
# ログの構造的記録
# ========================================

logging:
  location: .claude/logs/
  files:
    - subagent-dispatch.log: SubAgent 発火記録
    - failures.log: 失敗パターン記録（learning Skill）
  format: JSONL（1行1レコード）
  retention: 最新 100 件

log_entry:
  timestamp: ISO8601
  phase: {current_phase}
  playbook: {playbook_path}
  user_prompt: {original_prompt}
  action: {what_was_done}
  result: {PASS | FAIL | PARTIAL}
```

---

## project_playbook_sync

> **確認事項 #5 対応: project.md と playbook の相互監視**

```yaml
# ========================================
# 相互監視構造
# ========================================

sync_mechanism:
  project_to_playbook:
    - project.md の done_when → playbook の derives_from
    - playbook 完了 → project.md の done_when.status を achieved に
  playbook_to_project:
    - playbook の evidence → project.md の検証材料
    - playbook の known_issues → project.md に反映

# ========================================
# 乖離検出
# ========================================

coherence_check:
  hook: check-coherence.sh（settings.json 登録済み - PreToolUse:Bash）
  発火: git commit 前に自動発火
  タイミング:
    - git commit 前
    - state.md 編集後

# ========================================
# project.md を疑う
# ========================================

doubt_project:
  条件:
    - playbook と現在の進行が乖離
    - ユーザープロンプトと計画が乖離
  行動:
    1. project.md の done_when を再確認
    2. ユーザーの意図と照合
    3. 必要なら project.md を修正（pm を呼び出す）
```

---

## hooks_subagents_claude_md_integration

> **確認事項 #11 対応: すべての入力処理出力が明確につながっているか**

```yaml
# ========================================
# 統合アーキテクチャ図
# ========================================

architecture: |
  ┌──────────────────────────────────────────────────────────────────┐
  │                    三位一体アーキテクチャ                         │
  ├──────────────────────────────────────────────────────────────────┤
  │                                                                   │
  │  【Layer 1: Hooks（構造的強制）】                                 │
  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
  │   │session-start│→│ init-guard  │→│playbook-guard│→ ...         │
  │   └─────────────┘  └─────────────┘  └─────────────┘              │
  │        │                 │                │                       │
  │        ▼                 ▼                ▼                       │
  │   【Layer 2: CLAUDE.md（思考制御）】                              │
  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
  │   │    INIT     │  │    LOOP     │  │  POST_LOOP  │              │
  │   └─────────────┘  └─────────────┘  └─────────────┘              │
  │        │                 │                │                       │
  │        ▼                 ▼                ▼                       │
  │   【Layer 3: SubAgents（検証）】                                  │
  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
  │   │   pm        │  │   critic    │  │  coherence  │              │
  │   └─────────────┘  └─────────────┘  └─────────────┘              │
  │                                                                   │
  └──────────────────────────────────────────────────────────────────┘

# ========================================
# 入力→処理→出力の連鎖
# ========================================

chain:
  input:
    - ユーザープロンプト
    - session-start.sh の pending 作成
  process:
    - init-guard.sh → Read 強制
    - INIT → [自認] 出力
    - playbook-guard.sh → playbook 確認
    - LOOP → done_criteria 検証
    - critic → 証拠検証
  output:
    - Phase 完了サマリー（stop-summary.sh）
    - state.md 更新
    - POST_LOOP → 次タスク導出

# ========================================
# 連携マトリクス
# ========================================

matrix:
  session-start.sh:
    連携先: init-guard.sh
    CLAUDE.md: INIT セクション
    SubAgent: null

  init-guard.sh:
    連携先: playbook-guard.sh
    CLAUDE.md: INIT の Read 強制
    SubAgent: null

  playbook-guard.sh:
    連携先: scope-guard.sh
    CLAUDE.md: plan_based ルール
    SubAgent: pm

  scope-guard.sh:
    連携先: critic-guard.sh
    CLAUDE.md: LOOP
    SubAgent: null

  critic-guard.sh:
    連携先: stop-summary.sh
    CLAUDE.md: CRITIQUE
    SubAgent: critic

  stop-summary.sh:
    連携先: session-start.sh（次セッション）
    CLAUDE.md: POST_LOOP
    SubAgent: null
```

---

## consent_protocol

> **確認事項 #12 対応: ユーザープロンプトの誤解釈防止**

```yaml
# ========================================
# 合意プロセス（Consent Protocol）設計
# ========================================

problem: |
  Claude がユーザープロンプトを「良かれと思って省略」し、
  意図しない大規模変更や方向性のずれが発生する問題。

solution: |
  「入力→LLM処理→出力」ではなく、
  「LLM処理結果の構造化出力 → 合意 → 出力」という流れを強制。

# ========================================
# [理解確認] ブロック フォーマット
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
# ユーザー応答
# ========================================

user_response:
  OK: 作業開始を許可
  修正: 「〇〇ではなく△△です」→ 再理解 → 再出力
  却下: 作業中止

# ========================================
# Hook 設計
# ========================================

hook:
  name: consent-guard.sh
  trigger: PreToolUse:Edit/Write
  check: .claude/.session-init/consent ファイルの存在
  behavior:
    consent_absent: exit 2 でブロック
    consent_present: 通過

integration:
  session_start: pending + consent ファイルを両方作成
  consent_granted: ユーザー OK → consent ファイル削除
  workflow: init-guard → [理解確認] → consent-guard → playbook-guard

# ========================================
# 実装状態
# ========================================

status: implemented
implementation:
  consent_guard_sh: created (.claude/hooks/consent-guard.sh)
  settings_json: REGISTERED (PreToolUse:Edit/Write)
  session_start_sh: INTEGRATED (consent ファイル作成機能追加)
  claude_md: PROPOSAL_CREATED (BLOCK ファイル、ユーザー承認待ち)
  test_executed: true (pending 方式でネガティブ/ポジティブテスト完了)

known_issues:
  - CLAUDE.md への追加はユーザー許可が必要（BLOCK ファイル）
  - [理解確認] 自動出力は CLAUDE.md 追加後に完成
  - 現在は手動で consent ファイル削除が必要
```

---

## current_state

```yaml
phase: システム改善完了

completed:
  - 三位一体アーキテクチャ設計
  - 普遍的ワークフロー定義
  - TDD と報酬詐欺防止の多層構造
  - playbook を疑う能力の設計
  - Phase 完了出力の構造化
  - project.md と playbook の相互監視設計
  - 入力→処理→出力の連鎖設計
  - playbook-system-improvements 全10Phase完了:
    - check-coherence.sh 登録
    - depends-check.sh 実装
    - consent-guard.sh 統合
    - scope-guard.sh STRICT_MODE
    - check-main-branch.sh 検証
    - archive-playbook.sh 実装
    - executor_design 設計
    - learning_skill_design 設計
    - CLAUDE.md CONSENT 提案

in_progress: []

next:
  - (オプション) CLAUDE.md CONSENT セクション追加（ユーザー承認後）
  - 新規ユーザー向けテンプレート検証
```

---

## executor_design

> **将来の executor 拡張に向けた設計（設計のみ、実装は将来）**

```yaml
# ========================================
# 複数 Executor アーキテクチャ
# ========================================

concept: |
  playbook の各 Phase に executor を指定し、
  適切なツール/サービスにタスクを委譲する。

executors:
  claude_code:
    description: Claude Code（デフォルト）
    use_case: 一般的なコーディング、ファイル操作、分析
    trigger: executor: claude_code または指定なし

  codex:
    description: OpenAI Codex（大規模コード生成）
    use_case: |
      - 大量のボイラープレートコード生成
      - 複数ファイルの一括生成
      - 定型パターンの展開
    trigger: executor: codex
    integration: MCP server (mcp__codex__codex)
    status: designed

  coderabbit:
    description: CodeRabbit（コードレビュー）
    use_case: |
      - PR レビュー
      - コード品質チェック
      - セキュリティスキャン
    trigger: executor: coderabbit
    integration: GitHub App or MCP server
    status: designed

  user:
    description: ユーザー手動実行
    use_case: |
      - 手動テスト
      - 外部サービス操作
      - 機密情報を扱う操作
    trigger: executor: user
    behavior: Claude がガイダンスを出力、ユーザーが実行

# ========================================
# 実装計画
# ========================================

implementation_plan:
  phase_1:
    name: executor-guard.sh 拡張
    description: executor フィールドを解析し、適切な処理を振り分け
    status: future

  phase_2:
    name: Codex MCP 統合
    description: mcp__codex__codex を活用した大規模生成
    status: future

  phase_3:
    name: CodeRabbit 統合
    description: PR 作成時に自動レビュー依頼
    status: future
```

---

## learning_skill_design

> **失敗パターン自動学習の設計（設計のみ、実装は将来）**

```yaml
# ========================================
# Learning Skill 強化設計
# ========================================

concept: |
  critic FAIL や playbook の known_issues を自動記録し、
  類似タスク開始時に過去の教訓を自動参照する。

components:
  failure_recorder:
    trigger: critic FAIL 時
    action: |
      1. 失敗パターンを .claude/logs/failures.log に記録
      2. JSONL 形式: {timestamp, phase, playbook, criteria, reason}
      3. 最新 100 件を保持

  lesson_retriever:
    trigger: 新 playbook 作成時
    action: |
      1. playbook のキーワードを抽出
      2. failures.log から類似パターンを検索
      3. 関連する教訓を提示

  archive_analyzer:
    trigger: Phase 開始時（オプション）
    action: |
      1. .archive/plan/ の完了 playbook を参照
      2. 類似 Phase の evidence/known_issues を抽出
      3. 成功/失敗パターンを提示

# ========================================
# 実装計画
# ========================================

implementation_plan:
  phase_1:
    name: failures.log 自動記録
    description: critic FAIL 時に自動記録する Hook
    status: future

  phase_2:
    name: 類似パターン検索
    description: キーワードマッチングで過去の失敗を検索
    status: future

  phase_3:
    name: 自動提示
    description: Phase 開始時に関連教訓を自動表示
    status: future
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | executor_design, learning_skill_design セクション追加（設計のみ）。 |
| 2025-12-09 | 三位一体アーキテクチャとして再設計。ユーザー確認事項 #1,#2,#5,#7,#8,#9,#11 に対応。 |
| 2025-12-09 | 0から再設計。「整合性確認」から「動作実証」へ転換。13テストケースを定義。 |
| 2025-12-08 | ディスカッション用に全面改訂。ユーザー視点の done_when を追加。 |
| 2025-12-08 | 全タスク完了。13件の機能実装を終了。 |
| 2025-12-08 | 初版作成。MECE 分析の残タスク 13件を登録。 |
