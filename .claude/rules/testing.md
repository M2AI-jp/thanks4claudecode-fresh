# Testing Rules

> **テスト規約と品質基準**

---

## テスト方針

```yaml
philosophy:
  coverage: 意味のあるテストを優先
  speed: 高速なフィードバックループ
  isolation: 独立したテスト

  priority:
    1: ビジネスロジック
    2: エッジケース
    3: 統合ポイント
```

---

## テスト構造

```yaml
structure:
  unit: tests/unit/
  integration: tests/integration/
  e2e: tests/e2e/
  guards: tests/guards/

  naming:
    file: "{target}.test.{ext}"
    describe: "対象の名前"
    it: "期待する動作"
```

---

## TDD フロー

```yaml
tdd:
  1: テストを書く（RED）
  2: 最小限の実装（GREEN）
  3: リファクタリング（REFACTOR）

  commit_timing:
    - RED 後: "test: add failing test for X"
    - GREEN 後: "feat: implement X"
    - REFACTOR 後: "refactor: clean up X"
```

---

## カバレッジ基準

```yaml
coverage:
  minimum: 80%
  target: 90%
  critical_paths: 100%

  exclude:
    - 型定義
    - 設定ファイル
    - 生成コード
```

---

## アサーション

```yaml
assertions:
  prefer:
    - toBe: プリミティブ比較
    - toEqual: オブジェクト比較
    - toThrow: エラー確認
    - toMatchSnapshot: 大きな出力

  avoid:
    - 複数アサーション（1テスト1アサーション）
    - 実装詳細のテスト
    - 時間依存テスト
```

---

## モック

```yaml
mocking:
  when:
    - 外部API
    - ファイルシステム
    - 時間依存処理

  avoid:
    - 過剰なモック
    - 実装詳細のモック
    - テスト対象自体のモック
```
