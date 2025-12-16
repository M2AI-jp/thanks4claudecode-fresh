# Toolstack Patterns

> **3 つのツールスタックパターンと設定ガイド**

---

## 概要

Claude Code は 3 つの Toolstack パターンをサポートしています。
ユーザーの環境と要件に応じて最適なパターンを選択してください。

---

## パターン一覧

| パターン | 構成 | 推奨ユースケース |
|----------|------|------------------|
| **A** | Claude Code のみ | シンプルさ重視、初心者 |
| **B** | Claude Code + Codex | 大規模コード生成、パフォーマンス重視 |
| **C** | Claude Code + Codex + CodeRabbit | フルスタック、品質重視 |

---

## パターン A: Claude Code のみ

### 概要

```yaml
ツール:
  - Claude Code（コード作成・レビュー）

設定不要:
  - .mcp.json は context7 のみ
  - 追加の API キー不要

executor 許可:
  - claudecode
  - user
```

### 推奨ユースケース

- 初めて Claude Code を使う
- シンプルな設定を好む
- 外部サービスとの連携を避けたい
- コンテキスト消費を最小限にしたい

### 設定方法

```yaml
# state.md
config:
  security: admin
  toolstack: A
```

```json
// .mcp.json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

---

## パターン B: Claude Code + Codex

### 概要

```yaml
ツール:
  - Claude Code（設計・小規模コード・レビュー）
  - Codex（大規模コード生成）

必要な設定:
  - .mcp.json に codex を追加
  - OpenAI API キー（Codex 用）

executor 許可:
  - claudecode
  - codex
  - user
```

### 推奨ユースケース

- 大規模なコード生成が必要
- Claude Code のコンテキストを節約したい
- レビューは Claude Code で十分

### 設定方法

```yaml
# state.md
config:
  security: admin
  toolstack: B
```

```json
// .mcp.json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "codex": {
      "command": "npx",
      "args": ["-y", "codex-mcp-server"]
    }
  }
}
```

### Codex の使用方法

```yaml
直接呼び出し（非推奨）:
  mcp__codex__codex(prompt='実装内容')
  ⚠️ コンテキストが膨張する可能性

SubAgent 経由（推奨）:
  Task(subagent_type='codex-delegate', prompt='実装内容')
  ✓ 結果が要約され、コンテキスト膨張を防止
```

---

## パターン C: Claude Code + Codex + CodeRabbit

### 概要

```yaml
ツール:
  - Claude Code（設計・小規模コード）
  - Codex（大規模コード生成）
  - CodeRabbit（自動コードレビュー）

必要な設定:
  - .mcp.json に codex を追加
  - OpenAI API キー（Codex 用）
  - CodeRabbit GitHub App インストール

executor 許可:
  - claudecode
  - codex
  - coderabbit
  - user
```

### 推奨ユースケース

- チーム開発で品質を重視
- PR ごとに自動レビューが欲しい
- 複数の AI を組み合わせて使いたい

### 設定方法

```yaml
# state.md
config:
  security: admin
  toolstack: C
```

```json
// .mcp.json（パターン B と同じ）
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "codex": {
      "command": "npx",
      "args": ["-y", "codex-mcp-server"]
    }
  }
}
```

### CodeRabbit 設定

```yaml
1. GitHub App インストール:
   - https://github.com/apps/coderabbit-ai にアクセス
   - リポジトリにインストール

2. 設定ファイル（オプション）:
   - .coderabbit.yaml をリポジトリルートに配置
   - レビュールールをカスタマイズ

3. 動作確認:
   - PR を作成すると自動でレビューコメントが付く
```

---

## パターン選択ガイド

```
┌─────────────────────────────────────────────────────────┐
│ Q1: 外部 API の設定は問題ありませんか？                    │
│                                                         │
│   NO  ──────────────────────────> パターン A             │
│   YES                                                   │
│    ↓                                                    │
│ Q2: 大規模コード生成が必要ですか？                        │
│                                                         │
│   NO  ──────────────────────────> パターン A             │
│   YES                                                   │
│    ↓                                                    │
│ Q3: PR ごとに自動レビューが欲しいですか？                 │
│                                                         │
│   NO  ──────────────────────────> パターン B             │
│   YES ─────────────────────────> パターン C             │
└─────────────────────────────────────────────────────────┘
```

---

## Toolstack の変更方法

```yaml
1. state.md を編集:
   config:
     toolstack: B  # A, B, C のいずれか

2. .mcp.json を更新（B または C の場合）:
   - codex MCP サーバーを追加

3. CodeRabbit を設定（C の場合）:
   - GitHub App をインストール
```

---

## コンテキスト消費の比較

| パターン | 直接呼び出し | SubAgent 経由 |
|----------|-------------|---------------|
| A | 最小 | - |
| B | 大（Codex 結果） | 小（要約） |
| C | 大（Codex 結果） | 小（要約） |

**推奨**: パターン B/C では `codex-delegate` SubAgent を経由してください。

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成（M053） |
