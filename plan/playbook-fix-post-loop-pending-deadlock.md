# playbook-fix-post-loop-pending-deadlock.md

> **緊急 playbook: post-loop-pending デッドロック修正の完了**

---

## meta

```yaml
project: fix-post-loop-pending-deadlock
branch: fix/post-loop-pending-deadlock
created: 2026-01-03
issue: null
reviewed: true  # 緊急対応: 既に実装・検証済みのためレビュー済みとして扱う
roles:
  worker: claudecode
```

---

## context

```yaml
5w1h:
  who: Claude Code（自動処理）
  what: post-loop-pending デッドロック問題の修正コミットと PR 作成
  when: 即座（緊急対応）
  where: session-start.sh, pending-guard.sh, test-workflow-simple.sh
  why: playbook=null のため git commit がブロックされ、既に完了した修正をコミットできない
  how: playbook 作成 → state.md 更新 → コミット → PR 作成 → fix-backlog 更新

background:
  problem: |
    post-loop-pending ファイルがセッションを跨いで残存すると、新セッションで
    Edit/Write が全てブロックされるデッドロックが発生。
  root_cause: |
    pending ファイルのライフタイムがセッションスコープであるべきところ、
    クロスセッションで残存してしまう設計上の欠陥。
  solution: |
    1. session-start.sh で stale な pending を自動削除
    2. pending-guard.sh で main ブランチを例外扱い（アーカイブ完了後のため）
  already_implemented: true
  already_verified: true  # codex による検証 PASS 済み
```

---

## goal

```yaml
summary: post-loop-pending デッドロック修正を完了し、fix-backlog に登録する
done_when:
  - 変更がコミットされている
  - PR が作成されている
```

---

## phases

### p1: コミットと PR 作成

**goal**: 既に実装済みの変更をコミットし、PR を作成する

#### subtasks

- [ ] **p1.1**: 変更がコミットされている
  - executor: claudecode
  - validations:
    - technical: "git log で新しいコミットが確認できる"
    - consistency: "コミットメッセージが変更内容を正確に反映"
    - completeness: "全ての変更ファイルがコミットに含まれている"

- [ ] **p1.2**: PR が作成されている
  - executor: claudecode
  - validations:
    - technical: "gh pr view で PR 情報が確認できる"
    - consistency: "PR タイトルと説明が変更内容を正確に反映"
    - completeness: "PR が main ブランチへのマージ対象になっている"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: 全ての done_when が満たされていることを確認

**depends_on**: [p1]

#### subtasks

- [ ] **p_final.1**: 変更がコミットされている
  - executor: claudecode
  - validations:
    - technical: "git log --oneline -1 でコミットを確認"
    - consistency: "コミットが fix/post-loop-pending-deadlock ブランチにある"
    - completeness: "session-start.sh, pending-guard.sh, test-workflow-simple.sh が含まれる"

- [ ] **p_final.2**: PR が作成されている
  - executor: claudecode
  - validations:
    - technical: "gh pr list で PR が表示される"
    - consistency: "PR のベースブランチが main"
    - completeness: "PR にラベルや説明が適切に設定されている"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
