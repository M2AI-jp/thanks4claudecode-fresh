---
name: test-runner
description: テスト実行・検証専門スキル。Unit テスト、E2E テスト、型チェック、ビルドテストを自動実行し、結果を解析して報告する。
---

# test-runner

> **テスト実行・検証専門スキル**

---

## 役割

テストを自動実行し、結果を解析して問題を報告する。

---

## 発火条件（確定的パターン）

このスキルは以下の場合に**必ず**実行される：

```yaml
トリガー:
  - テストファイルを作成・編集した後
  - done_criteria の検証時
  - ユーザーが「テスト実行して」「テストして」と言った場合
  - コミット前のテスト確認
```

---

## テスト種類

```yaml
1. Unit Tests:
   - pnpm test（Jest/Vitest）
   - 個別コンポーネントのテスト

2. E2E Tests:
   - pnpm test:e2e（Playwright）
   - 全体フローのテスト

3. Type Checks:
   - pnpm tsc --noEmit
   - 型の整合性確認

4. Build Test:
   - pnpm build
   - ビルドが通るか確認
```

---

## 実行手順

```bash
# 1. Unit テスト
echo "=== Running Unit Tests ===" && pnpm test

# 2. Type チェック
echo "=== Type Checking ===" && pnpm tsc --noEmit

# 3. Build テスト
echo "=== Build Test ===" && pnpm build

# 4. E2E テスト（オプション）
# echo "=== E2E Tests ===" && pnpm test:e2e
```

---

## 出力形式

```
=== Test Runner Results ===

[Unit Tests]
✓ 24 tests passed
✗ 2 tests failed:
  - src/__tests__/auth.test.ts: Login flow returns 401
  - src/__tests__/api.test.ts: API endpoint not found

[Type Check]
✓ No type errors

[Build]
✓ Build successful (2.3s)

=== Summary ===
Status: FAIL
Passed: 24/26
Failed: 2
Build: OK
```

---

## 失敗時の対応

```yaml
テスト失敗時:
  1. エラーメッセージを解析
  2. 失敗原因を特定
  3. 修正方法を提案
  4. 修正実行
  5. 再テスト

例:
  エラー: "API endpoint not found"
  原因: ルーティング設定漏れ
  修正: src/app/api/route.ts を作成
  再テスト: pnpm test
```

---

## 使用例

### CLAUDE.md への統合（確定的発火）

```markdown
## テスト実行の必須事項

- テストファイルを作成・編集した後は、必ず `test-runner` スキルを実行すること
- done_criteria 検証時は、必ず `test-runner` スキルで証拠を示すこと
```

この記載により、LLM はテスト関連の作業を行うたびに自動的にこのスキルを呼び出す。

---

## 設定ファイル

```yaml
必要なファイル:
  - jest.config.js / vitest.config.ts: テスト設定
  - playwright.config.ts: E2E 設定
  - package.json: テストスクリプト

推奨設定:
  - テストカバレッジ: 80% 以上
  - タイムアウト: 30秒
  - 並列実行: 有効
```

---

## playbook との連携

```yaml
done_criteria の検証:
  - playbook の validations（3点検証）を自動実行
  - 結果を done_criteria と照合
  - PASS/FAIL を明確に報告

例:
  done_criteria: "ログイン機能が動作する"
  validations:
    technical: "pnpm test -- auth.test.ts を実行し PASS を確認"
    consistency: "認証ロジックと整合性確認"
    completeness: "全認証フローがテストされている"
  実行結果: validations 全 PASS → done_criteria 満たす
```
