# playbook-plan-restructure.md

> **plan/ 構造のテンポラリー化**

---

## meta

```yaml
project: plan-restructure
branch: feat/plan-restructure
created: 2025-12-11
issue: null
derives_from: null
reviewed: false
```

---

## goal

```yaml
summary: plan/ 構造をテンポラリー方式に変更し、履行率を向上させる
done_when:
  - plan/active/ と plan/archive/ の構造が確立
  - hooks が plan/active/ を参照するように更新
  - state.md が新構造を反映
  - README が新設計を説明
```

---

## phases

### Phase 1: 構造変更

```yaml
- id: p1
  name: 構造変更
  goal: plan/ をテンポラリー構造に変更
  status: done
  tasks:
    - id: t1-1
      name: ディレクトリ作成
      subtasks:
        - step: "plan/active/ と plan/archive/ を作成"
          executor: claudecode
          criteria: "両ディレクトリが存在する"
          status: "[x]"
        - step: "既存ファイルを archive に移動"
          executor: claudecode
          criteria: "plan/ 直下に playbook/project がない"
          status: "[x]"
    - id: t1-2
      name: ドキュメント更新
      subtasks:
        - step: "plan/README.md を更新"
          executor: claudecode
          criteria: "テンポラリー構造の説明が記載"
          status: "[x]"
        - step: "hooks を plan/active/ 参照に更新"
          executor: claudecode
          criteria: "pm.md, state SKILL が plan/active/ を参照"
          status: "[x]"
        - step: "state.md を更新"
          executor: claudecode
          criteria: "playbook.active が plan/active/ を指す"
          status: "[x]"
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-11 | 初版作成 |
