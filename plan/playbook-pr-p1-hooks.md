# playbook-pr-p1-hooks.md

> **P1.1/P1.2 の PR 作成とマージ**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/p1.2-stop-py
created: 2025-12-23
issue: null
derives_from: P1.1, P1.2
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: P1.1（session_start.py）と P1.2（stop.py）の変更を main にマージする PR を作成
done_when:
  - "gh pr create で PR が作成されている"
  - "PR のタイトルに P1.1 と P1.2 の内容が含まれている"
  - "PR の本文に変更サマリーが含まれている"
  - "PR が main ブランチにマージされている"
  - "ローカルの main ブランチが最新である"
```

---

## phases

### p1: PR 作成

**goal**: GitHub に PR を作成する

#### subtasks

- [x] **p1.1**: feat/p1.2-stop-py ブランチがリモートにプッシュされている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "PASS - git push -u origin feat/p1.2-stop-py 成功"
    - consistency: "PASS - ローカルとリモートのコミットが一致"
    - completeness: "PASS - 4 コミット全てがプッシュされている"
  - validated: 2025-12-23T04:15:00

- [x] **p1.2**: gh pr create で PR が作成されている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "PASS - PR #23 作成: https://github.com/M2AI-jp/thanks4claudecode-fresh/pull/23"
    - consistency: "PASS - PR のベースブランチが main"
    - completeness: "PASS - タイトルと本文が設定済み"
  - validated: 2025-12-23T04:15:00

**status**: done
**max_iterations**: 5

---

### p2: PR マージ

**goal**: PR を main にマージする

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: gh pr merge で PR がマージされている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "gh pr merge が成功"
    - consistency: "マージ方式が適切（merge commit）"
    - completeness: "PR がクローズされている"

- [ ] **p2.2**: ローカルの main ブランチが最新である
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "git checkout main && git pull が成功"
    - consistency: "main に P1.1/P1.2 のコミットが含まれている"
    - completeness: "feat/p1.2-stop-py ブランチの変更が全て反映"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が満たされていることを検証

**depends_on**: [p2]

#### subtasks

- [ ] **p_final.1**: gh pr create で PR が作成されている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "gh pr view で PR 情報を確認"
    - consistency: "PR が存在し、マージ済みである"
    - completeness: "正しいブランチからの PR である"

- [ ] **p_final.2**: PR のタイトルに P1.1 と P1.2 の内容が含まれている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "gh pr view でタイトルを確認"
    - consistency: "session_start.py と stop.py が言及されている"
    - completeness: "Hook 実装であることが明確"

- [ ] **p_final.3**: PR が main ブランチにマージされている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "gh pr view --json state で MERGED を確認"
    - consistency: "main ブランチに変更が反映"
    - completeness: "全コミットがマージされている"

- [ ] **p_final.4**: ローカルの main ブランチが最新である
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "git log main で P1.1/P1.2 コミットを確認"
    - consistency: "リモートと同期している"
    - completeness: "session_start.py と stop.py が main に存在"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: state.md を更新する（playbook.active = null, branch = null）
  - command: state.md の playbook セクションを更新
  - status: pending

- [ ] **ft2**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## notes

### 含まれる変更

1. **P1.1: session_start.py 実装**
   - `.claude/hooks/session_start.py`: UserPromptSubmit Hook
   - state.md の YAML frontmatter を解析
   - playbook.active の有無を判定

2. **P1.2: stop.py 実装**
   - `.claude/hooks/stop.py`: Stop Hook
   - review_pending フラグを読み取り
   - review_pending: true でセッション終了をブロック

3. **playbook_reviewer spec フレームワーク**
   - `.claude/frameworks/playbook-review-criteria.md`
   - 作成者 != 検証者の原則を強制

### コミット履歴

```
426b913 chore: Archive playbook-p1.2-stop-py
e61ea05 feat(P1.2): Implement stop.py hook with playbook_reviewer spec
d4ddb96 chore: Archive playbook-p1-1-session-start-py
90ca24a feat(P1.1): Implement session_start.py hook
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成 |
