# playbook-hooks-test-framework.md

> **M2: テストフレームワーク構築 - 1000パターンテストの実装**

---

## meta

```yaml
project: hooks-100-percent-fire
branch: feat/hooks-100-percent-fire
created: 2025-12-12
issue: null
derives_from: M2
reviewed: false
```

---

## goal

```yaml
summary: 1000種類以上のテストパターンを生成し、自動検証スクリプトを構築する
done_when:
  - 1000種類以上のテストケースが生成されている
  - 自動検証スクリプトが動作する
  - 全テストが実行され、結果が記録されている
```

---

## phases

### p1: テストデータ生成

```yaml
- id: p1
  name: テストデータ生成
  goal: 1000パターンのテストデータを JSON ファイルとして生成
  tasks:
    - id: t1-1
      name: テストデータ生成スクリプト作成
      subtasks:
        - step: "テストデータ生成スクリプトを作成"
          executor: claudecode
          criteria: ".claude/hooks/generate-test-data.sh が存在する"
          status: "[ ]"
    - id: t1-2
      name: テストデータ生成実行
      subtasks:
        - step: "1000パターンのテストデータを生成"
          executor: claudecode
          criteria: ".claude/hooks/test-data/prompts.json に 1000 件以上のテストケースが存在する"
          status: "[ ]"
  status: pending
```

### p2: テスト実行スクリプト構築

```yaml
- id: p2
  name: テスト実行スクリプト構築
  goal: 1000パターンのテストを自動実行するスクリプトを構築
  depends_on: [p1]
  tasks:
    - id: t2-1
      name: テスト実行スクリプト作成
      subtasks:
        - step: "1000パターンテスト実行スクリプトを作成"
          executor: claudecode
          criteria: ".claude/hooks/test-1000-patterns.sh が存在し、実行可能"
          status: "[ ]"
    - id: t2-2
      name: 結果レポート機能
      subtasks:
        - step: "テスト結果をレポートとして出力する機能を追加"
          executor: claudecode
          criteria: "テスト結果が .claude/hooks/test-results/ に保存される"
          status: "[ ]"
  status: pending
```

### p3: 全テスト実行

```yaml
- id: p3
  name: 全テスト実行
  goal: 1000パターンの全テストを実行し、結果を記録
  depends_on: [p2]
  tasks:
    - id: t3-1
      name: 初回テスト実行
      subtasks:
        - step: "1000パターンの全テストを実行"
          executor: claudecode
          criteria: "全テストが実行され、結果が記録されている"
          status: "[ ]"
    - id: t3-2
      name: 結果分析
      subtasks:
        - step: "テスト結果を分析し、PASS/FAIL 件数を確認"
          executor: claudecode
          criteria: "テスト結果サマリーが出力されている"
          status: "[ ]"
  status: pending
```

### p4: 動作テスト

```yaml
- id: p4
  name: 動作テスト
  goal: テストフレームワーク全体が正しく動作することを検証
  depends_on: [p3]
  tasks:
    - id: t4-1
      name: フレームワーク検証
      subtasks:
        - step: "テストフレームワークが正しく動作することを確認"
          executor: claudecode
          criteria: "テストの再実行で同じ結果が得られる"
          status: "[ ]"
  status: pending
```

---

## notes

- この playbook は M2（テストフレームワーク構築）に対応
- 1000パターンは hooks-test-design.md のカテゴリに基づいて生成
- FAIL があれば M3（不具合修正）で対応
