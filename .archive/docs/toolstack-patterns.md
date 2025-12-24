# Toolstack Patterns

> **3 つのツールスタックパターンと設定ガイド**

---

## 概要

Claude Code は 3 つの Toolstack パターンをサポートしています。
ユーザーの環境と要件に応じて最適なパターンを選択してください。

**全ツールは CLI で呼び出します。**

---

## パターン一覧

| パターン | 構成 | 推奨ユースケース |
|----------|------|------------------|
| **A** | Claude Code のみ | シンプルさ重視、初心者 |
| **B** | Claude Code + Codex CLI | 大規模コード生成、パフォーマンス重視 |
| **C** | Claude Code + Codex CLI + CodeRabbit CLI | フルスタック、品質重視 |

---

## CLI ツール一覧

| ツール | コマンド | 用途 |
|--------|---------|------|
| Codex CLI | `codex exec "プロンプト"` | 大規模コード生成 |
| Codex CLI | `codex review` | コードレビュー |
| CodeRabbit CLI | `coderabbit review` | AI コードレビュー |

---

## パターン A: Claude Code のみ

### 概要

```yaml
ツール:
  - Claude Code（コード作成・レビュー）

設定不要:
  - 追加の CLI ツール不要
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

---

## パターン B: Claude Code + Codex CLI

### 概要

```yaml
ツール:
  - Claude Code（設計・小規模コード・レビュー）
  - Codex CLI（大規模コード生成）

必要な設定:
  - Codex CLI インストール済み
  - OpenAI API キー（OPENAI_API_KEY 環境変数）

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

### Codex CLI の使用方法

```bash
# 非インタラクティブ実行（推奨）
codex exec "ユーザー認証機能を実装してください"

# コードレビュー
codex review

# モデル指定
codex exec -m o3 "複雑なアルゴリズムを実装"

# インタラクティブモード（対話式）
codex "何か作りたいものを教えてください"
```

### SubAgent 経由の使用（推奨）

```yaml
呼び出し方:
  Task(subagent_type='codex-delegate', prompt='実装内容を説明')

効果:
  - SubAgent として別コンテキストで実行
  - 結果が要約され、コンテキスト膨張を防止
  - Bash で CLI を呼び出し
```

---

## パターン C: Claude Code + Codex CLI + CodeRabbit CLI

### 概要

```yaml
ツール:
  - Claude Code（設計・小規模コード）
  - Codex CLI（大規模コード生成）
  - CodeRabbit CLI（自動コードレビュー）

必要な設定:
  - Codex CLI インストール済み
  - CodeRabbit CLI インストール済み
  - OpenAI API キー
  - CodeRabbit 認証

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

### CodeRabbit CLI の使用方法

```bash
# 認証（初回のみ）
coderabbit auth

# コードレビュー実行
coderabbit review

# 特定ファイルのレビュー
coderabbit review --files src/main.ts
```

---

## パターン選択ガイド

```
┌─────────────────────────────────────────────────────────┐
│ Q1: 外部 CLI ツールの設定は問題ありませんか？            │
│                                                         │
│   NO  ──────────────────────────> パターン A             │
│   YES                                                   │
│    ↓                                                    │
│ Q2: 大規模コード生成が必要ですか？                        │
│                                                         │
│   NO  ──────────────────────────> パターン A             │
│   YES                                                   │
│    ↓                                                    │
│ Q3: AI によるコードレビューが欲しいですか？               │
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

2. CLI ツールをインストール（B または C の場合）:
   - Codex CLI: npm install -g @openai/codex
   - CodeRabbit CLI: npm install -g coderabbit

3. 環境変数を設定:
   - OPENAI_API_KEY（Codex 用）
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

## CLI インストール確認

```bash
# Codex CLI
which codex && codex --version

# CodeRabbit CLI
which coderabbit && coderabbit --help
```

---

## トラブルシューティング

### Codex CLI が見つからない

```bash
# npm でインストール
npm install -g @openai/codex

# パスを確認
which codex
```

### CodeRabbit CLI が見つからない

```bash
# npm でインストール
npm install -g coderabbit

# パスを確認
which coderabbit
```

### API キーエラー

```bash
# 環境変数を設定
export OPENAI_API_KEY="your-api-key"

# または .env ファイルに記載
echo 'OPENAI_API_KEY=your-api-key' >> ~/.env
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | CLI ベースに全面書き換え（M057） |
| 2025-12-17 | 初版作成（M053） |
