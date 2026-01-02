# playbook-critic-codex-test.md

> **テスト用 playbook: critic + codex 検証の挙動テスト**

---

## meta

```yaml
project: critic-codex-test
branch: test/critic-codex-verification
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: tmp/hello.py を作成して critic + codex 検証の挙動をテストする
done_when:
  - tmp/hello.py が存在し、python tmp/hello.py で "Hello, World!" が出力される
```

---

## context

```yaml
5w1h:
  who: 開発者（テスト実行者）
  what: tmp/hello.py（簡単な Python スクリプト）を作成
  when: 即時
  where: tmp フォルダ
  why: critic + codex 検証の挙動テスト
  how: codex で実装、critic で検証

analysis_result:
  source: prompt-analyzer（簡略化）
  timestamp: 2026-01-03T01:30:00Z
  data:
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check（簡略化）
  approved_at: 2026-01-03T01:30:00Z
  summary: テスト目的の簡単な playbook。hello.py を作成して検証挙動をテスト。
```

---

## phases

### p1: hello.py の実装

**goal**: tmp/hello.py を作成し、実行可能にする

#### subtasks

- [ ] **p1.1**: tmp/hello.py が存在し、python tmp/hello.py で "Hello, World!" が出力される
  - executor: codex
  - validations:
    - technical: "python tmp/hello.py を実行し 'Hello, World!' が出力されることを確認"
    - consistency: "Python 3 の標準的な書き方に準拠"
    - completeness: "ファイルが存在し、実行権限または python コマンドで実行可能"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証
**depends_on**: [p1]

#### subtasks

- [ ] **p_final.1**: tmp/hello.py が存在し、python tmp/hello.py で "Hello, World!" が出力される
  - executor: claudecode
  - validations:
    - technical: "python tmp/hello.py を実行し出力を確認"
    - consistency: "出力が 'Hello, World!' と完全一致"
    - completeness: "ファイルの存在と実行結果の両方を確認"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する（hello.py を除く）
  - command: `find tmp/ -type f ! -name 'README.md' ! -name 'hello.py' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
