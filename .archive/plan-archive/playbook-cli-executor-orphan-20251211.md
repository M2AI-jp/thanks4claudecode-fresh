# playbook-cli-executor.md

> **codex/coderabbit を CLI で呼び出す仕様に統一**

---

## meta

```yaml
project: cli-executor
branch: feat/cli-executor
created: 2025-12-11
issue: null
derives_from: null
reviewed: false
```

---

## goal

```yaml
summary: codex と coderabbit を CLI 経由で SubAgent として呼び出せるようにする
done_when:
  - executor-guard.sh が SubAgent 呼び出しを案内（ブロックしない）
  - codex は CLI（codex exec）で統一
  - coderabbit は CLI（coderabbit review）で統一
  - AGENTS.md に codex/coderabbit が記載
```

---

## phases

- id: p1
  name: executor-guard.sh 修正
  goal: ブロックではなく SubAgent 呼び出しを案内
  tasks:
    - id: t1-1
      name: codex/coderabbit の処理を修正
      executor: claudecode
      done_criteria:
        - [ ] exit 2 を削除（codex/coderabbit の場合）
        - [ ] additionalContext で Task(subagent_type="codex") を案内
        - [ ] additionalContext で Task(subagent_type="coderabbit") を案内
        - [ ] user の場合は引き続きブロック
  status: in_progress

- id: p2
  name: ドキュメント更新
  goal: 関連ドキュメントを新仕様に合わせて更新
  depends_on: [p1]
  tasks:
    - id: t2-1
      name: AGENTS.md 更新
      executor: claudecode
      done_criteria:
        - [ ] codex/coderabbit が SubAgent 一覧に追加
    - id: t2-2
      name: playbook-format.md 確認・更新
      executor: claudecode
      done_criteria:
        - [ ] executor 説明が CLI/SubAgent 方式に統一
  status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-11 | 初版作成 |
