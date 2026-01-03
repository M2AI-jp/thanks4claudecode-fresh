# playbook-fix-protected-edit-repo-root.md

> **PB-04: protected-edit.sh の REPO_ROOT パス計算修正**

---

## meta

```yaml
project: fix-protected-edit-repo-root
branch: fix/protected-edit-repo-root
created: 2026-01-03
issue: PB-04
reviewed: true
derives_from: docs/fix-backlog.md P0-02
```

---

## goal

```yaml
summary: protected-edit.sh の REPO_ROOT パス計算を修正し、contract.sh に正しく到達できるようにする
done_when:
  - contract.sh が正しく source される
  - bash -n protected-edit.sh が成功
```

---

## context

```yaml
5w1h:
  who: Claude Code / フック実行時の bash
  what: protected-edit.sh 行22 の REPO_ROOT パス計算を 2階層から4階層に修正
  when: 即時（本セッション）
  where: .claude/skills/access-control/guards/protected-edit.sh
  why: 現在2階層上を参照しており contract.sh に到達できない（.claude/skills/ になる）
  how: "${SCRIPT_DIR}/../.." を "${SCRIPT_DIR}/../../../.." に変更

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-03T15:15:00Z
  data:
    risks:
      technical:
        - severity: low
          description: 1行修正のため影響範囲が限定的
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

translated_requirements:
  source: term-translator
  timestamp: 2026-01-03T15:15:00Z
  data:
    original_terms:
      - original: "2階層→4階層"
        translated: "../.. を ../../../.. に変更"
        rationale: "スクリプトの位置から相対パスでリポジトリルートに到達するため"
    technical_requirements:
      - requirement: "REPO_ROOT が正しくリポジトリルートを指す"
        derived_from: "contract.sh に正しく到達"
        implementation_hint: "realpath でパスを検証可能"

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T15:15:00Z
  summary: "protected-edit.sh 行22の REPO_ROOT を4階層上に修正する"
```

---

## phases

### p1: パス計算修正

**goal**: protected-edit.sh の REPO_ROOT パス計算を修正する

#### subtasks

- [x] **p1.1**: 行22の REPO_ROOT が `"${SCRIPT_DIR}/../../../.."` である
  - executor: claudecode
  - validations:
    - technical: "PASS - 行22: REPO_ROOT=\"${SCRIPT_DIR}/../../../..\""
    - consistency: "PASS - bash-check.sh と同じ4階層計算"
    - completeness: "PASS - 1箇所のみの修正で完了"
  - validated: 2026-01-03T16:30:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証
**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: contract.sh が正しく source される
  - executor: claudecode
  - validations:
    - technical: "PASS - realpath → /Users/amano/Desktop/thanks4claudecode-v2"
    - consistency: "PASS - scripts/contract.sh が存在する"
    - completeness: "PASS - パス計算が正確"
  - validated: 2026-01-03T16:30:00

- [x] **p_final.2**: bash -n protected-edit.sh が成功
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n → exit code 0, Syntax OK"
    - consistency: "PASS - bash-check.sh と同じ構造"
    - completeness: "PASS - 全ての構文が有効"
  - validated: 2026-01-03T16:30:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: skipped (構造変更なし)

- [x] **ft2**: 変更をコミットする
  - command: `git add -A && git commit`
  - status: done

- [x] **ft3**: PR 作成
  - command: `gh pr create`
  - status: done
