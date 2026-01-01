# Coding Rules

> **コーディング規約と品質基準**

---

## 基本原則

```yaml
principles:
  simplicity: 必要最小限の実装
  readability: 自己文書化コード
  safety: 型安全性を優先
  testability: テスト可能な設計
```

---

## 命名規則

```yaml
naming:
  files:
    kebab-case: "*.ts, *.tsx, *.md"
    camelCase: 変数・関数
    PascalCase: クラス・型・コンポーネント

  prefixes:
    is/has/can: boolean
    get/set: accessor
    handle/on: イベントハンドラ

  avoid:
    - 略語（一般的なものを除く）
    - 数字で始まる名前
    - アンダースコア開始（private 除く）
```

---

## TypeScript

```yaml
typescript:
  strict: true
  noImplicitAny: true

  prefer:
    - interface over type（拡張性のため）
    - unknown over any
    - const over let

  avoid:
    - any 型
    - 型アサーション（as）
    - // @ts-ignore
```

---

## エラーハンドリング

```yaml
error_handling:
  boundaries: システム境界でのみキャッチ
  internal: エラーを投げる（キャッチしない）
  logging: 構造化ログ（JSON）

  avoid:
    - 空の catch ブロック
    - 過剰な try-catch
    - エラーの握りつぶし
```

---

## コメント

```yaml
comments:
  when:
    - 非自明なロジック
    - ビジネスルール
    - TODO/FIXME（期限付き）

  avoid:
    - 自明なコード説明
    - コメントアウトされたコード
    - 古いコメント
```
