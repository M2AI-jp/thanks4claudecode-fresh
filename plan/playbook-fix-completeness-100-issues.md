# playbook-fix-completeness-100-issues.md

> **orchestration-completeness-100 の残課題6件を修正する**

---

## meta

```yaml
project: fix-completeness-100-issues
branch: feat/multi-language-orchestration-demo
created: 2026-01-02
issue: null
reviewed: true
roles:
  worker: claudecode
  reviewer: claudecode
```

---

## goal

```yaml
summary: orchestration-completeness-100 の残課題6件を修正し、品質を完成させる
done_when:
  - playbook-orchestration-completeness-100.md の全 phase/subtask が done になっている
  - qa.sh の skip を FAIL 扱いに変更し、証跡ログを evidence/ に保存する
  - evidence/orchestration-codex-evidence.md の行数が正しく、subagent.log 引用が含まれている
  - tests/tmp-run.bats にエラーケース（空入力、不正JSON）が追加されている
  - ts-node が devDependencies に追加され、README に前提条件が追記されている
  - アーカイブ済み playbook の timestamp が整合している
```

---

## context

```yaml
5w1h:
  who: Claude Code（orchestrator）
  what: アーカイブ済み playbook の残課題修正
  when: 本セッション中
  where: plan/archive/, evidence/, scripts/, tests/, package.json
  why: 品質完全性100の基準を満たすため
  how: 6つの課題を順次修正

analysis_result:
  source: user-provided
  timestamp: 2026-01-02T08:00:00Z
  data:
    issues:
      high:
        - playbook の全 phase/subtask を done に更新
        - qa.sh の skip を FAIL 扱いに変更 + 証跡ログ保存
      medium:
        - evidence の行数修正 (102->101) + subagent.log 引用追加
        - bats にエラーケース追加
        - ts-node を devDependencies に追加 + README 前提条件追記
      low:
        - timestamp 整合性修正
```

---

## phases

### p1: 課題修正

**goal**: 6件の課題を全て修正する

#### subtasks

- [ ] **p1.1**: plan/archive/playbook-orchestration-completeness-100.md の全 subtask が [x] 完了状態である
  - executor: claudecode
  - validations:
    - technical: "grep -c '- \\[ \\]' で未完了が0件であることを確認"
    - consistency: "全 Phase の status が done である"
    - completeness: "p1 から p_final まで全て完了状態"

- [ ] **p1.2**: scripts/qa.sh で skip を FAIL 扱いにし、結果を evidence/ に保存する
  - executor: claudecode
  - validations:
    - technical: "SKIPPED を FAILED にカウントするロジックが存在"
    - consistency: "証跡ログが evidence/qa-results-{timestamp}.log に保存される"
    - completeness: "exit code が skip 時も非ゼロになる"

- [ ] **p1.3**: evidence/orchestration-codex-evidence.md の行数が 101 行で、subagent.log 引用が含まれている
  - executor: claudecode
  - validations:
    - technical: "Lines: 101 lines と記載されている"
    - consistency: "subagent.log からの引用が含まれている"
    - completeness: "agentId, timestamp, session が全て記載"

- [ ] **p1.4**: tests/tmp-run.bats に空入力と不正JSONのエラーケースが追加されている
  - executor: claudecode
  - validations:
    - technical: "test ケース数が増加している"
    - consistency: "bats tests/tmp-run.bats が全 PASS"
    - completeness: "空入力、不正JSON、存在しないフィールドのケースがある"

- [ ] **p1.5**: package.json に ts-node が devDependencies に追加されている
  - executor: claudecode
  - validations:
    - technical: "grep 'ts-node' package.json で存在確認"
    - consistency: "npm install が正常に完了"
    - completeness: "README に Node.js バージョン要件が追記されている"

- [ ] **p1.6**: playbook のタイムスタンプが整合している（validated フィールドの追加）
  - executor: claudecode
  - validations:
    - technical: "validated タイムスタンプが存在"
    - consistency: "全 subtask に validated が設定されている"
    - completeness: "ISO 8601 形式で統一されている"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: 全修正が正しく適用されていることを確認

**depends_on**: [p1]

#### subtasks

- [ ] **p_final.1**: アーカイブ済み playbook に未完了 subtask がない
  - executor: claudecode
  - validations:
    - technical: "grep -c '- \\[ \\]' plan/archive/playbook-orchestration-completeness-100.md が 0"
    - consistency: "全 Phase が done"
    - completeness: "final_tasks も完了状態"

- [ ] **p_final.2**: qa.sh が skip 時に FAIL を返し、証跡を保存する
  - executor: claudecode
  - validations:
    - technical: "コードレビューで SKIPPED が FAILED にカウントされる"
    - consistency: "evidence/ への保存ロジックが存在"
    - completeness: "全チェック結果が記録される"

- [ ] **p_final.3**: bats テストが全 PASS する（エラーケース含む）
  - executor: claudecode
  - validations:
    - technical: "bats tests/tmp-run.bats が exit 0"
    - consistency: "エラーケースが正しくテストされている"
    - completeness: "少なくとも10件以上のテストがある"

- [ ] **p_final.4**: package.json に ts-node があり npm install が成功する
  - executor: claudecode
  - validations:
    - technical: "npm install --dry-run が成功"
    - consistency: "README に前提条件が追記されている"
    - completeness: "依存関係が解決可能"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml が更新されている
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: 変更が全てコミットされている
  - command: `git add -A && git commit -m "fix: resolve completeness-100 issues (6 items)"`
  - status: pending

- [ ] **ft3**: state.md が完了状態に更新されている
  - command: `Edit state.md`
  - status: pending
