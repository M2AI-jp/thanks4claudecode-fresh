# playbook-regression-test.md

> **回帰テスト機能: 変更後の既存機能テストを自動化**

---

## meta

```yaml
project: thanks4claudecode
created: 2025-12-08
issue: "#9"
branch: feat/regression-test
type: meta-improvement
```

---

## goal

```yaml
summary: 変更後の既存機能テストを自動化する
root_cause: MECE 分析で発見した欠落機能（品質管理）

done_when:
  - 既存機能のテストが自動実行される
  - 変更がテストを破壊した場合、警告が出る
  - 回帰テスト結果が記録される
```

---

## phases

### p1: 回帰テスト対象の特定

```yaml
id: p1
name: 回帰テスト対象の特定
goal: テストすべき既存機能を洗い出す
executor: claude
max_iterations: 10

正しい動きの定義:
  - 全ての Hook が正常に動作する
  - 全ての SubAgent が呼び出せる
  - state.md / playbook の整合性チェックが機能する

done_criteria:
  - 回帰テスト対象リストが作成されている
  - 各テスト項目に検証方法が定義されている

evidence:
  - .claude/tests/regression-targets.md 作成済み
  - Hooks 14件、Agents 7件、Commands 5件をリスト化
  - 各項目にテスト方法（直接実行/stdin/Task呼び出し）を定義
  - 優先度（高/中/低）を設定
  - critic: PASS
status: done
```

---

### p2: テストスクリプト作成

```yaml
id: p2
name: テストスクリプト作成
goal: 回帰テスト用のスクリプトを作成する
executor: claude
max_iterations: 10
depends_on: [p1]

正しい動きの定義:
  - 単一コマンドで全テストが実行される
  - 各テストが PASS/FAIL を返す
  - テスト結果がログに記録される

done_criteria:
  - .claude/tests/regression-test.sh が存在する
  - テストスクリプトが正常に実行される
  - 全テストが PASS する

evidence:
  - .claude/tests/regression-test.sh 作成済み
  - 実行結果: PASS=22, FAIL=0
  - Hooks 14件、Agents 7件、Frameworks 1件をテスト
  - critic: PASS
status: done
```

---

### p3: 自動実行トリガー

```yaml
id: p3
name: 自動実行トリガー
goal: 変更時にテストが自動実行される仕組みを作る
executor: claude
max_iterations: 10
depends_on: [p2]

正しい動きの定義:
  - git commit 前にテストが実行される
  - テスト失敗時はコミットがブロックされる
  - Hook として統合される

done_criteria:
  - pre-bash-check.sh にテスト実行ロジックがある
  - テスト失敗時にコミットがブロックされる

evidence:
  - pre-bash-check.sh 125-144行にテスト実行ロジック追加
  - git commit 時に .claude/tests/regression-test.sh を自動実行
  - テスト失敗時 exit 1 でコミットブロック確認
  - critic: PASS
status: done
```

---

### p4: 統合テスト

```yaml
id: p4
name: 統合テスト
goal: 回帰テスト機能が正常に動作することを確認
executor: claude
max_iterations: 10
depends_on: [p3]

正しい動きの定義:
  - 正常系: 変更なしでテストが PASS
  - 異常系: Hook を壊してテストが FAIL
  - 異常系: テスト FAIL でコミットがブロック

done_criteria:
  - 正常系テスト PASS
  - 異常系テスト PASS
  - critic PASS

evidence:
  正常系テスト:
    - テスト1: regression-test.sh 単体実行 → PASS=22, FAIL=0
    - テスト2: git commit シミュレーション → 回帰テスト部分 PASS（その後 check-state-update が発動）
  異常系テスト:
    - テスト3: 構文エラーファイル検出 → FAIL=1, Exit Code=1
    - テスト4: テスト失敗時のコミットブロック → Exit Code=1 でブロック確認
  統合動作:
    - pre-bash-check.sh 125-144行で regression-test.sh を呼び出し
    - テスト失敗時は exit 1 でコミットをブロック
    - テスト成功時は次の check-coherence.sh / check-state-update.sh へ進行
  critic: PASS
status: done
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。Issue #9。 |
| 2025-12-08 | p1-p4 全 Phase 完了。Issue #9 クローズ。 |
| 2025-12-08 | バグ修正: pre-bash-check.sh の git commit 誤検出。 |
