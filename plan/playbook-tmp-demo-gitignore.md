# playbook-tmp-demo-gitignore.md

## meta

```yaml
project: tmp-demo-gitignore
branch: feat/multi-language-orchestration-demo
created: 2026-01-02
issue: null
reviewed: true
roles:
  worker: claudecode
```

## goal

```yaml
summary: tmp/ デモファイル（process.py, run.sh, transform.ts）を .gitignore から除外し、git で永続追跡可能にする
done_when:
  - .gitignore に !tmp/process.py, !tmp/run.sh, !tmp/transform.ts が追加されている
  - git status で tmp/ のデモファイルが追跡対象として表示される
```

## context

```yaml
5w1h:
  who: QA、開発者
  what: .gitignore に例外を追加し、デモファイルを永続化
  when: 即時
  where: .gitignore
  why: git 操作のたびにデモファイルが消失し QA が失敗する
  how: .gitignore に negation pattern を追加

analysis_result:
  source: user-provided
  timestamp: 2026-01-02T07:00:00Z
  data:
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: user-request
  approved_at: 2026-01-02T07:00:00Z
  summary: understanding-check 不要と明記されているため、ユーザー要求をそのまま採用
```

## phases

### p1: .gitignore 修正

**goal**: デモファイルを git 追跡対象にする

#### subtasks

- [x] **p1.1**: .gitignore に !tmp/process.py, !tmp/run.sh, !tmp/transform.ts が追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -c '!tmp/' で 4 を確認"
    - consistency: "PASS - tmp/* の後に例外が記載"
    - completeness: "PASS - 3 ファイル全て追加済み"
  - validated: 2026-01-02T07:05:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証
**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: .gitignore に 3 つの例外パターンが存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -c '!tmp/' で 4 を確認"
    - consistency: "PASS - 例外パターンが tmp/* の後に記載"
    - completeness: "PASS - process.py, run.sh, transform.ts 全て含まれている"
  - validated: 2026-01-02T07:05:00Z

- [x] **p_final.2**: git status でデモファイルが追跡対象
  - executor: claudecode
  - validations:
    - technical: "PASS - git status で A tmp/process.py, A tmp/run.sh, A tmp/transform.ts を確認"
    - consistency: "PASS - git add -f 不要（既に staged）"
    - completeness: "PASS - 3 ファイル全てが追跡対象"
  - validated: 2026-01-02T07:05:00Z

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - executed: 2026-01-02T07:06:00Z

- [x] **ft2**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
  - executed: 2026-01-02T07:06:00Z
