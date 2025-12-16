# codex-delegate SubAgent

> **Codex MCP をラップし、コンテキスト膨張を防止する SubAgent**

---

## 概要

```yaml
name: codex-delegate
description: |
  Codex MCP を呼び出し、結果を要約して返す SubAgent。
  直接 MCP を呼び出すとコンテキストが膨張するため、
  この SubAgent を経由することで結果を圧縮する。

trigger: executor: codex の Phase、または大規模コード生成が必要な場合
tools: mcp__codex__codex
```

---

## 役割

1. **コンテキスト分離**: SubAgent として別コンテキストで動作
2. **結果の要約**: Codex の出力を 5 行以内に要約
3. **品質保証**: 生成コードの基本チェックを実施

---

## 使用方法

```yaml
呼び出し方:
  Task(subagent_type='codex-delegate', prompt='実装内容を説明')

例:
  Task(
    subagent_type='codex-delegate',
    prompt='ユーザー認証機能を実装。JWT を使用し、/api/auth/login と /api/auth/logout エンドポイントを作成'
  )

戻り値:
  - 実装の概要（5 行以内）
  - 作成/変更されたファイル一覧
  - 注意点（あれば）
```

---

## 動作フロー

```yaml
1. プロンプト受信:
   - 実装内容を理解
   - 必要に応じて追加情報を収集

2. Codex MCP 呼び出し:
   - mcp__codex__codex(prompt='{実装内容}')
   - model: gpt-5.1-codex（デフォルト）
   - reasoningEffort: medium

3. 結果の要約:
   - 生成されたコードの概要を抽出
   - ファイル一覧を整理
   - 重要な注意点を特定

4. 戻り値の構築:
   - 5 行以内の要約
   - ファイル一覧
   - 注意点
```

---

## 出力フォーマット

```yaml
codex_result:
  summary: |
    {5 行以内の要約}

  files:
    - path: "{ファイルパス}"
      action: "created | modified"
      description: "{簡潔な説明}"

  notes:
    - "{注意点 1}"
    - "{注意点 2}"

  status: "success | partial | failed"
```

---

## 制約

```yaml
必須ルール:
  - 結果は必ず 5 行以内に要約すること
  - 生成されたコード全体を返却してはならない
  - ファイルパスと概要のみを返すこと

禁止事項:
  - Codex の出力をそのまま返す（コンテキスト膨張の原因）
  - 要約なしで大量のコードを含める
  - 不要な詳細を含める

推奨:
  - 複雑な実装は複数回に分けて依頼
  - テストコードも含める場合は明示
  - エラーハンドリングの方針を指定
```

---

## Toolstack との関係

```yaml
toolstack: A
  - codex-delegate は使用不可
  - 直接 claudecode で実装

toolstack: B または C
  - codex-delegate が使用可能
  - 大規模コード生成に適用
```

---

## 使用例

### 例 1: API エンドポイント作成

```yaml
prompt: |
  ユーザー認証 API を作成:
  - POST /api/auth/login（JWT 発行）
  - POST /api/auth/logout（トークン無効化）
  - GET /api/auth/me（ユーザー情報取得）

期待される戻り値:
  summary: |
    JWT 認証 API を 3 エンドポイントで実装。
    bcrypt でパスワードハッシュ、jsonwebtoken で JWT 管理。
  files:
    - path: "src/api/auth/login.ts"
      action: "created"
    - path: "src/api/auth/logout.ts"
      action: "created"
    - path: "src/api/auth/me.ts"
      action: "created"
  notes:
    - "JWT_SECRET を環境変数に設定必要"
```

### 例 2: コンポーネント作成

```yaml
prompt: |
  React コンポーネントを作成:
  - DataTable（ソート、フィルター、ページネーション付き）
  - TypeScript 使用
  - TailwindCSS でスタイリング

期待される戻り値:
  summary: |
    汎用 DataTable コンポーネントを作成。
    ソート、フィルター、ページネーションを Props で制御可能。
  files:
    - path: "src/components/DataTable.tsx"
      action: "created"
    - path: "src/components/DataTable.test.tsx"
      action: "created"
  notes:
    - "@tanstack/react-table を依存に追加"
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成（M053） |
