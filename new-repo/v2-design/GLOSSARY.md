# 用語定義（Glossary）

> **文書の位置付け**: new-repo で使用する用語の定義
>
> **MECE 役割**: 用語定義の SSOT
>
> **作成日**: 2026-01-22

---

## A

### Agent（エージェント）
特定のタスクを自律的に実行する Claude Code の SubAgent。Task ツールで起動される。
- 例: pm, reviewer, critic, prompt-analyzer

### AUTO_FLOW
ユーザー確認をスキップして自動承認で進行するモード。
- 条件: `auto_approve=true` が設定されている場合

---

## C

### CLAUDE.md
Core Contract を定義するファイル。リポジトリのルート直下に配置。
- 役割: 非交渉ルールと参照先の定義
- 変更: PROMPT_CHANGELOG.md への記録が必須

### Codex モード
review スキルで 8 つの専門エキスパートを並列呼び出しするモード。
- エキスパート: Security, Accessibility, Performance, Quality, SEO, Architect, Plan Reviewer, Scope Analyst

### Context-0（コンテキスト0）
過去のチャット履歴を参照しない状態。新しい Claude Code セッションを開始した直後の状態。
- 用途: レビュー、テスト、ドキュメントの自己完結性検証

### Core Contract
Claude Code の動作を規定する基本契約。CLAUDE.md に定義される。
- 内容: Golden Path, playbook_gate, reward_fraud_prevention など

---

## D

### decisions.md
設計判断（Why）を記録するファイル。harness で採用されている状態管理パターン。
- 対比: patterns.md（How）

### done_criteria（完了基準）
タスクが完了したと判断するための基準。playbook の各 subtask に定義される。
- 検証: critic SubAgent が Evidence を検証して PASS/FAIL を判定

---

## E

### Escalation（エスカレーション）
自動処理を中断し、ユーザーに判断を委ねること。
- トリガー: 3回ルール（同一タスクで 3回失敗）

### Event Unit
Hook の発火タイミングを 1 ユニットとする設計単位。
- 内容: Validator, Context Injector, Guardrail, Telemetry, Recovery
- スコープ: ガード/テレメトリ/復旧補助のみ（ロジックは Workflow へ）

### Evidence（証拠）
タスク完了を証明するための根拠。3点検証で評価される。
- 3点: technical, consistency, completeness

---

## F

### Fork
セッションを分岐させて別の作業を開始すること。
- 対比: Resume（中断再開）

---

## G

### Golden Path
タスク依頼から完了までの標準フロー。
- 順序: prompt-analyzer → playbook-init → pm → reviewer → 実装 → critic

### Guardrail（ガードレール）
危険な操作を防ぐための仕組み。
- 例: playbook-gate, file-protector, quality-guard

---

## H

### Hook
Claude Code のイベントに応じて自動実行されるスクリプト。
- 種類: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop
- 役割: 最終防衛線（Layer 3）、検出・通知のみ

---

## I

### Issue codes
失敗を分類するためのコード（旧設計）。
- 例: I-RF-1（報酬詐欺）, I-DL-1（デッドライン）
- 問題: 複雑すぎて実装困難 → 3回ルールで置換

---

## L

### Layer（層）
3層防御戦略における防御の層。
- Layer 1: Rules（CLAUDE.md など）
- Layer 2: Skills（Skill 内のガードロジック）
- Layer 3: Hooks（技術的強制、最終手段）

### LOOP
playbook のタスクを実行するフェーズ。
- 内容: state.md と playbook を読み、タスクを実行し、検証し、次へ進む

---

## M

### Markdown ビュー
人間可読な形式で playbook を表示するファイル（PLAYBOOK.md）。
- 対比: plan.json（機械可読 SSOT）

---

## P

### patterns.md
実装パターン（How）を記録するファイル。harness で採用されている状態管理パターン。
- 対比: decisions.md（Why）

### Phase
playbook 内の作業単位。複数の subtask から構成される。
- 例: Phase 0（基盤）, Phase 1（状態管理）

### Plans.md
harness で採用されているタスク管理ファイル（Markdown 形式）。
- マーカー: cc:TODO, cc:WIP, cc:完了, pm:確認済

### playbook
タスク定義と進捗を管理するファイル群。
- 構成: plan.json + progress.json（+ PLAYBOOK.md）
- 場所: play/{id}/

### playbook-gate
playbook がない状態で Edit/Write をブロックするガード。
- 条件: state.md の playbook.active == null

### pm（SubAgent）
playbook の作成と管理を担当する SubAgent。
- 責務: plan.json 作成, reviewer 検証, state.md 更新

### POST_LOOP
playbook 完了後の後処理フェーズ。
- 内容: アーカイブ, 次タスク導出, /clear 案内

### prompt-analyzer（SubAgent）
ユーザープロンプトを分析する SubAgent。
- 出力: 5W1H, リスク, 曖昧さ, topic_type

---

## R

### Resume
中断したセッションを再開すること。
- 方法: session.json から状態を復元
- 対比: Fork（分岐）

### reviewer（SubAgent）
playbook をレビューする SubAgent。
- 出力: reviewed: true/false

### Reward Fraud（報酬詐欺）
タスクを完了していないのに完了を宣言すること。
- 防止: critic SubAgent の PASS が必須

---

## S

### Scenario Test（シナリオテスト）
E2E シナリオが期待通り動作するか検証するテスト。
- 例: scenario-01-basic-task.md

### Schema Test（スキーマテスト）
JSON/YAML がスキーマに準拠しているか検証するテスト。
- ツール: JSON Schema Validator

### session.events.jsonl
セッションのイベント履歴を記録するファイル。
- 用途: 状態復元, デバッグ

### session.json
セッションの実行時状態を記録するファイル。
- 内容: state, playbook, current_phase, retry_count

### Skill
特定の機能を提供するモジュール。.claude/skills/ に配置。
- 例: playbook-init, review, session-control

### SSOT（Single Source of Truth）
情報の唯一の真実源。
- 例: state.md（現在状態）, plan.json（playbook 定義）

### state.md
現在状態を記録するファイル。SSOT。
- 内容: playbook.active, goal, config

### Structure Test（構造テスト）
ファイル構造が仕様通りか検証するテスト。
- 例: 必須ファイルの存在確認

### subtask
Phase 内の個別タスク。done_criteria と validation_plan を持つ。

---

## T

### task-worker
harness で採用されている自己完結型エージェントパターン。
- フロー: implement → self-review → fix → build verify → test
- 制約: disallowedTools: [Task]（委譲禁止）

### Testability（テスト可能性）
仕様/実装がテスト可能かどうかの観点。
- レビュー5観点の一つ

### 3回ルール
同一タスクで 3回失敗したら必ずエスカレーションするルール。
- 用途: Issue codes の代替、シンプルで確実

### 3層防御戦略
Rules → Skills → Hooks の順で防御する戦略。
- harness で採用されている設計パターン

---

## V

### VibeCoder
非技術者がコーディングを行うユーザー像。
- 対応: 自然言語でのインタラクション、言い方例の提供

---

## W

### Workflow
Skill のオーケストレーションを定義する YAML ファイル。
- 場所: .claude/workflows/
- 内容: steps, condition, parallel, on_success, on_error

---

## 参照

- CLAUDE.md（Core Contract）
- ARCHITECTURE.md（アーキテクチャ設計）
- SPECIFICATION.md（仕様書）
