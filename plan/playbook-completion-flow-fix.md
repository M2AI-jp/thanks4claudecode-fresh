# playbook-completion-flow-fix

> **playbook 完了フローの3つのバグ修正**

---

## meta

```yaml
project: completion-flow-fix
branch: fix/playbook-completion-flow
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: playbook 完了時に main ブランチに戻り、state.md が neutral 状態になるよう修正
done_when:
  - archive-playbook.sh の Step 9 で git checkout main が実行される
  - archive-playbook.sh の Step 5 で goal セクション（milestone, phase, done_criteria, status）がリセットされる
  - merge-pr.sh が --auto なしで即座にマージを試行する
```

---

## context

```yaml
5w1h:
  who: "playbook 完了フローを使用する全ユーザー"
  what: "archive-playbook.sh と merge-pr.sh の3つのバグ修正"
  when: "今回の修正で解決"
  where: ".claude/skills/playbook-gate/workflow/archive-playbook.sh, .claude/skills/git-workflow/handlers/merge-pr.sh"
  why: "playbook 完了後に feature ブランチに留まり、state.md が不整合状態になる問題"
  how: "3つの具体的な修正（checkout main, goal リセット, --auto 削除）"

analysis_result:
  source: user-diagnosis
  timestamp: 2026-01-03T12:00:00Z
  data:
    problem_1: "archive-playbook.sh Step 9 に git checkout main がない"
    problem_2: "archive-playbook.sh Step 5 で goal セクションをリセットしていない"
    problem_3: "merge-pr.sh の --auto オプションが即座にマージしない"

user_approved_understanding:
  source: user-request
  approved_at: 2026-01-03T12:00:00Z
  summary: "ユーザーが診断済みの3つの問題点を修正依頼"
```

---

## phases

### p1: archive-playbook.sh の修正

**goal**: archive-playbook.sh の Step 5 と Step 9 を修正

#### subtasks

- [x] **p1.1**: archive-playbook.sh の Step 5 で goal セクション（milestone, phase, done_criteria, status）がリセットされる
  - executor: claudecode
  - validations:
    - technical: "PASS - Lines 364-377 に sed/awk でリセット処理が存在"
    - consistency: "PASS - merge-pr.sh の同等処理と整合"
    - completeness: "PASS - 4項目全てがリセットされる"
  - validated: 2026-01-03T12:30:00Z

- [x] **p1.2**: archive-playbook.sh の Step 9 で git checkout main が実行される
  - executor: claudecode
  - validations:
    - technical: "PASS - Line 442 に git checkout main が存在"
    - consistency: "PASS - Step 8 のマージ後に実行される"
    - completeness: "PASS - checkout 後に pull も実行される（Lines 450-456）"
  - validated: 2026-01-03T12:30:00Z

**status**: done
**max_iterations**: 5

---

### p2: merge-pr.sh の修正

**goal**: merge-pr.sh から --auto オプションを削除

#### subtasks

- [x] **p2.1**: merge-pr.sh の gh pr merge コマンドから --auto オプションが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - Lines 231-234 に --auto なし"
    - consistency: "PASS - 即座にマージを試行する動作"
    - completeness: "PASS - Line 230 にコメントで削除理由を記載"
  - validated: 2026-01-03T12:30:00Z

**status**: done
**depends_on**: [p1]
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: 3つの修正が全て適用されていることを検証

#### subtasks

- [x] **p_final.1**: archive-playbook.sh の Step 5 で goal セクションリセット処理が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - Lines 364-377 に4項目のリセット処理"
    - consistency: "PASS - Step 5 コメント内に含まれている"
    - completeness: "PASS - 4項目全てがリセットされる"
  - validated: 2026-01-03T12:30:00Z

- [x] **p_final.2**: archive-playbook.sh の Step 9 で git checkout main が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - Line 442 に git checkout main"
    - consistency: "PASS - Step 9 のセクション内に配置"
    - completeness: "PASS - checkout 後に pull 処理がある"
  - validated: 2026-01-03T12:30:00Z

- [x] **p_final.3**: merge-pr.sh に --auto オプションが存在しない
  - executor: claudecode
  - validations:
    - technical: "PASS - コード内に --auto なし（コメントのみ）"
    - consistency: "PASS - 即座にマージを試行する動作"
    - completeness: "PASS - Line 230 で削除理由を説明"
  - validated: 2026-01-03T12:30:00Z

**status**: done
**depends_on**: [p1, p2]
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
