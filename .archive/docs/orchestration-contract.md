# Orchestration Contract

> **ツールスタック構成と役割分担のルールを定義する契約**

---

## 1. ツールスタック定義

### 1.1 構成オプション

| Toolstack | 構成 | 特徴 |
|-----------|------|------|
| **A** | Claude Code only | シンプル、全てを Claude Code が担当 |
| **B** | Claude Code + Codex | 実装を Codex に委譲可能 |
| **C** | Claude Code + Codex + CodeRabbit | レビューを CodeRabbit に委譲可能 |

### 1.2 state.md での設定

```yaml
## config

```yaml
toolstack: A  # A | B | C
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: claudecode        # 実装担当（A: claudecode, B/C: codex）
  reviewer: claudecode      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```
```

---

## 2. 役割定義

### 2.1 Orchestrator（監督・調整）

**担当**: Claude Code（固定）

```yaml
responsibilities:
  - playbook の作成・管理
  - タスク分解・優先順位付け
  - worker への指示出し
  - 進捗管理・状態更新
  - 品質判断・完了判定

constraints:
  - 自分で実装を行わない（toolstack B/C の場合）
  - 意思決定は常に記録（playbook, state.md）
```

### 2.2 Worker（実装担当）

**担当**: toolstack により変動

| Toolstack | Worker |
|-----------|--------|
| A | Claude Code |
| B | Codex |
| C | Codex |

```yaml
responsibilities:
  - コード実装
  - テスト作成・実行
  - バグ修正
  - リファクタリング

constraints:
  - orchestrator の指示に従う
  - playbook の scope 内でのみ作業
  - 独自の判断で scope を拡大しない
```

### 2.3 Reviewer（レビュー担当）

**担当**: toolstack により変動

| Toolstack | Reviewer |
|-----------|----------|
| A | Claude Code |
| B | Claude Code |
| C | CodeRabbit |

```yaml
responsibilities:
  - コードレビュー
  - 品質チェック
  - 改善提案
  - done_criteria との照合

constraints:
  - 実装を直接変更しない
  - 問題点は worker にフィードバック
```

### 2.4 Human（人間の介入）

**担当**: User（固定）

```yaml
responsibilities:
  - 最終承認
  - 方針決定
  - 例外判断
  - 緊急停止

authority:
  - 全ての操作を停止可能
  - playbook の変更を承認/拒否
  - admin モードの有効化
```

---

## 3. 委譲ルール

### 3.1 Orchestrator → Worker

```yaml
delegation_trigger:
  - playbook が active
  - 実装タスクが明確
  - acceptance_criteria が定義済み

delegation_format:
  - タスク説明（what）
  - 完了条件（done_criteria）
  - 制約（constraints）
  - 期待成果物（deliverables）

example:
  Task(subagent_type='codex-delegate', prompt='''
    タスク: UserService に getById メソッドを追加
    完了条件:
      - メソッドが実装されている
      - 単体テストが PASS
    制約:
      - 既存の API を壊さない
  ''')
```

### 3.2 Worker → Reviewer

```yaml
review_trigger:
  - 実装完了
  - テスト PASS
  - PR 作成済み

review_format:
  - 変更概要
  - テスト結果
  - 既知の制限
```

### 3.3 Reviewer → Human

```yaml
escalation_trigger:
  - 重大な設計問題
  - セキュリティ懸念
  - scope 外の変更検出

escalation_format:
  - 問題の説明
  - 影響範囲
  - 推奨対応
```

---

## 4. コンテキスト分離

### 4.1 Codex 委譲時の原則

```yaml
context_isolation:
  rule: Codex は自身のコンテキストで動作
  benefit: Claude Code のコンテキストを汚染しない

information_transfer:
  - 必要最小限の情報のみ渡す
  - 結果は要約して受け取る
  - 詳細は必要時のみ展開
```

### 4.2 SubAgent 呼び出しパターン

```yaml
codex-delegate:
  purpose: 実装タスクを Codex に委譲
  tools: [Bash, mcp__codex__codex, mcp__codex__codex-reply]
  returns: 実装結果の要約

reviewer:
  purpose: コード/設計レビュー
  tools: [Read, Grep, Glob, Bash]
  returns: レビューコメント

critic:
  purpose: done_criteria の検証
  tools: [Read, Grep, Bash]
  returns: PASS/FAIL と根拠
```

---

## 5. 状態遷移

### 5.1 典型的なフロー（Toolstack B）

```
[Human] 要求 → [Orchestrator] playbook 作成
    ↓
[Orchestrator] タスク分解 → [Worker(Codex)] 実装
    ↓
[Worker] 完了報告 → [Reviewer(CC)] レビュー
    ↓
[Reviewer] 承認 → [Orchestrator] 状態更新
    ↓
[Orchestrator] 次タスク or 完了
```

### 5.2 状態遷移図

```
             ┌───────────────────────┐
             │      playbook=null    │
             │      (待機状態)        │
             └──────────┬────────────┘
                        │ playbook 作成
                        ▼
             ┌───────────────────────┐
             │     playbook=active   │◄───────┐
             │     (作業状態)         │         │
             └──────────┬────────────┘         │
                        │ タスク完了            │
                        ▼                       │
             ┌───────────────────────┐          │
             │      レビュー中        │──FAIL──►│
             └──────────┬────────────┘          │
                        │ PASS                  │
                        ▼                       │
             ┌───────────────────────┐          │
             │      次タスク?        │──YES───►│
             └──────────┬────────────┘
                        │ NO (全完了)
                        ▼
             ┌───────────────────────┐
             │   admin maintenance   │
             │   (アーカイブ・終了)   │
             └───────────────────────┘
```

---

## 6. エラーハンドリング

### 6.1 Worker 失敗時

```yaml
scenario: Codex が実装に失敗
action:
  1. エラー内容を確認
  2. タスクを再分解（より小さく）
  3. 追加コンテキストを付与して再委譲
  4. 3回失敗で Human にエスカレーション
```

### 6.2 Reviewer 指摘時

```yaml
scenario: レビューで問題検出
action:
  1. 問題を Worker にフィードバック
  2. Worker が修正
  3. 再レビュー
  4. PASS まで繰り返し
```

### 6.3 Scope 逸脱時

```yaml
scenario: Worker が scope 外の変更を提案
action:
  1. 変更を REJECT
  2. scope 内での代替案を提示
  3. scope 拡大が必要なら Human に相談
```

---

## 7. 監査・ログ

### 7.1 記録対象

```yaml
mandatory_logging:
  - 委譲の開始/終了
  - レビュー結果
  - 状態遷移
  - エスカレーション

log_location: .claude/logs/orchestration.log
```

### 7.2 ログフォーマット

```
[YYYY-MM-DD HH:MM:SS] [ROLE] [ACTION] detail
```

Example:
```
[2025-12-18 14:30:00] [ORCHESTRATOR] [DELEGATE] Task: implement-user-api → Codex
[2025-12-18 14:35:00] [WORKER] [COMPLETE] Task: implement-user-api, tests: PASS
[2025-12-18 14:36:00] [REVIEWER] [REVIEW] PR#123: APPROVED
```

---

## 8. 適用条件

### 8.1 Toolstack A（Claude Code only）

```yaml
when:
  - シンプルなタスク
  - コンテキスト管理が重要
  - 素早いイテレーション優先

constraint:
  - 全ての役割を Claude Code が担当
  - 委譲オーバーヘッドなし
```

### 8.2 Toolstack B（+Codex）

```yaml
when:
  - 大量のコード生成
  - 並列実行が有効
  - コンテキスト分離が必要

constraint:
  - 実装は Codex に委譲
  - レビューは Claude Code
```

### 8.3 Toolstack C（+Codex+CodeRabbit）

```yaml
when:
  - 高品質レビューが必要
  - 外部視点が有効
  - チーム開発シミュレーション

constraint:
  - 実装は Codex
  - レビューは CodeRabbit
  - 統合は Claude Code
```
