# playbook-cli-executor-integration.md

> **codex/coderabbit を CLI 経由で呼び出す仕様に変更**

---

## meta

```yaml
project: cli-executor-integration
branch: feat/cli-executor-integration
created: 2025-12-11
issue: null
derives_from: null
reviewed: false
```

---

## goal

```yaml
summary: codex と coderabbit を SubAgent として CLI 呼び出しできるようにする
done_when:
  - codex SubAgent が CLI 経由で実行可能
  - coderabbit SubAgent が CLI 経由で実行可能
  - executor-guard.sh が SubAgent 呼び出しを案内
  - 関連ドキュメントが更新済み
```

---

## phases

- id: p1
  name: SubAgent 定義作成
  goal: codex と coderabbit の SubAgent 定義ファイルを作成
  tasks:
    - id: t1-1
      name: codex.md 作成
      executor: claudecode
      done_criteria:
        - [ ] .claude/agents/codex.md が存在する
        - [ ] codex exec コマンドを実行する定義
    - id: t1-2
      name: coderabbit.md 作成
      executor: claudecode
      done_criteria:
        - [ ] .claude/agents/coderabbit.md が存在する
        - [ ] coderabbit review コマンドを実行する定義
  status: pending

- id: p2
  name: executor-guard.sh 修正
  goal: ブロックではなく SubAgent 呼び出しを案内
  depends_on: [p1]
  tasks:
    - id: t2-1
      name: executor-guard.sh 更新
      executor: claudecode
      done_criteria:
        - [ ] exit 2 を削除（ブロックしない）
        - [ ] additionalContext で SubAgent 呼び出しを案内
  status: pending

- id: p3
  name: ドキュメント更新
  goal: 関連ドキュメントを新仕様に合わせて更新
  depends_on: [p2]
  tasks:
    - id: t3-1
      name: AGENTS.md 更新
      executor: claudecode
      done_criteria:
        - [ ] codex/coderabbit が SubAgent 一覧に追加
    - id: t3-2
      name: playbook-format.md 更新
      executor: claudecode
      done_criteria:
        - [ ] executor 説明が SubAgent 呼び出し方式に更新
    - id: t3-3
      name: settings.json 確認
      executor: claudecode
      done_criteria:
        - [ ] 必要に応じて settings.json を更新
  status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-11 | 初版作成 |
