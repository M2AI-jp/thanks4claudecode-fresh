# Executor Fallback Policy

> **executor のタイムアウト・エラー時のフォールバック手順**

---

## 概要

```yaml
purpose: |
  Codex MCP や CodeRabbit がタイムアウト・エラーを返した場合の
  代替手段と確認フローを定義する。

principle: fail-closed
  - 未分類のエラーはデフォルトでブロック
  - ユーザー確認なしに自動フォールバックしない
```

---

## フォールバックパターン

### 1. Codex MCP タイムアウト（-32001 AbortError）

```yaml
trigger: mcp__codex__codex が 120 秒以内に応答しない
symptoms:
  - "AbortError" または "-32001" を含むエラー
  - "timeout" を含むエラーメッセージ

action: ask_user
options:
  - label: "retry"
    description: "同じコマンドを再実行"
  - label: "fallback_to_cli"
    description: "codex exec コマンドで CLI 実行"
    command: |
      codex exec '...' --sandbox workspace-write
  - label: "fallback_to_claudecode"
    description: "Claude Code で直接実行"
  - label: "abort"
    description: "タスクを中止"

recommended: fallback_to_cli
reason: |
  MCP 経由より CLI 経由のほうがタイムアウトが発生しにくい。
  長文プロンプトや大量生成タスクは CLI 推奨。
```

### 2. Codex MCP エラー（その他）

```yaml
trigger: mcp__codex__codex が非タイムアウトエラーを返す
symptoms:
  - JSON パースエラー
  - 認証エラー
  - リソース不足エラー

action: ask_user
options:
  - label: "retry"
    description: "同じコマンドを再実行"
  - label: "fallback_to_claudecode"
    description: "Claude Code で直接実行"
  - label: "abort"
    description: "タスクを中止"

recommended: retry（1回まで）、その後 fallback_to_claudecode
```

### 3. CodeRabbit エラー

```yaml
trigger: CodeRabbit PR レビューが失敗
symptoms:
  - API エラー
  - レート制限
  - 接続エラー

action: ask_user
options:
  - label: "retry"
    description: "レビューを再実行"
  - label: "fallback_to_reviewer_subagent"
    description: "reviewer SubAgent でローカルレビュー"
  - label: "skip_review"
    description: "レビューをスキップ（非推奨）"
  - label: "abort"
    description: "タスクを中止"

recommended: fallback_to_reviewer_subagent
reason: |
  ローカルレビューでも品質チェックは可能。
  CodeRabbit 固有の機能（セキュリティスキャン等）は失われる。
```

---

## AskUserQuestion フロー

フォールバック時は必ず AskUserQuestion を使用して確認する:

```yaml
template:
  question: "{executor} でエラーが発生しました。どう対処しますか？"
  header: "Fallback"
  options:
    - label: "{option1}"
      description: "{description1}"
    - label: "{option2}"
      description: "{description2}"
    ...
  multiSelect: false

example:
  question: "Codex MCP がタイムアウトしました（120秒）。どう対処しますか？"
  header: "Fallback"
  options:
    - label: "CLI で再実行 (Recommended)"
      description: "codex exec コマンドで実行"
    - label: "再試行"
      description: "MCP 経由で再度実行"
    - label: "Claude Code で実行"
      description: "Codex を使わずに直接実行"
    - label: "中止"
      description: "このタスクを中止"
```

---

## 長文プロンプトの分割

Codex MCP でタイムアウトが頻発する場合:

```yaml
guidelines:
  max_prompt_length: 2000文字
  split_strategy:
    - タスクを小さなサブタスクに分割
    - 各サブタスクを順次実行
    - 結果を統合

example:
  before: "10ファイルを一度にリファクタリング"
  after:
    - "ファイル1-3をリファクタリング"
    - "ファイル4-6をリファクタリング"
    - "ファイル7-10をリファクタリング"
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| plan/template/playbook-format.md | executor_enforcement 定義 |
| .claude/skills/playbook-gate/guards/executor-guard.sh | executor 検証 |
| .claude/skills/golden-path/agents/codex-delegate.md | Codex MCP ラッパー |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-01 | 初版作成。playbook-ops-improvement で定義。 |
