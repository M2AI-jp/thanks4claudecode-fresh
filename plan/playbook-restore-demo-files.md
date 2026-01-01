# playbook-restore-demo-files.md

## meta

```yaml
project: デモファイル復元と証跡整合性修正
branch: fix/restore-demo-files
created: 2026-01-02
issue: null
reviewed: true
```

---

## goal

```yaml
summary: デモファイルの復元完了と証跡の整合性を修正する
done_when:
  - tmp/README.md に前提条件が追記されている（jq, ts-node, bats, shellcheck, ruff, eslint）
  - evidence/ に証跡補足ログが存在する（8→11 tests の経緯を説明）
  - scripts/qa.sh が PASS する
  - 新しい QA 証跡が evidence/ に記録されている
```

---

## context

```yaml
5w1h:
  who: Claude（pm SubAgent）
  what: デモファイル復元後の整合性修正
  when: 即時
  where: tmp/, evidence/
  why: 消失したデモファイルを復元し、証跡の不整合を解消する
  how: README 更新、証跡補足ログ作成、QA 実行

analysis_result:
  source: user-provided
  timestamp: 2026-01-02T08:36:00Z
  data:
    background: |
      - tmp/run.sh, tmp/process.py, tmp/transform.ts が消失していた
      - git checkout 4fb161b で復元済み
      - playbook-orchestration-completeness-100 の証跡が「8 tests」だが実際は 11 tests
      - QA ログが FAIL を記録している
    risks:
      technical: []
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: user-message
  approved_at: 2026-01-02T08:36:00Z
  summary: ユーザーが「understanding-check: 不要」と明示的にスキップを指示
```

---

## phases

### p1: 前提条件の追記

**goal**: tmp/README.md に必要な前提条件（jq, ts-node, bats, shellcheck, ruff, eslint）を追記する

#### subtasks

- [x] **p1.1**: tmp/README.md の Prerequisites セクションに jq が追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'jq' tmp/README.md で存在確認済み"
    - consistency: "PASS - 既存 Prerequisites と同形式"
    - completeness: "PASS - 用途説明（テストで使用）を含む"
  - validated: 2026-01-02T08:52:00Z

- [x] **p1.2**: tmp/README.md の Prerequisites セクションに ts-node が追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'ts-node' tmp/README.md で存在確認済み"
    - consistency: "PASS - 既存 Prerequisites と同形式"
    - completeness: "PASS - TypeScript 実行環境と説明"
  - validated: 2026-01-02T08:52:00Z

- [x] **p1.3**: tmp/README.md の Prerequisites セクションに eslint が追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'eslint' tmp/README.md で存在確認済み"
    - consistency: "PASS - 既存 Prerequisites と同形式"
    - completeness: "PASS - TypeScript linter と説明"
  - validated: 2026-01-02T08:52:00Z

**status**: done
**max_iterations**: 5

---

### p2: 証跡補足ログの作成

**goal**: 8 tests → 11 tests の経緯を説明する証跡補足ログを作成する

**depends_on**: []

#### subtasks

- [x] **p2.1**: evidence/test-count-clarification.md が存在し、8→11 tests の経緯が説明されている
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f evidence/test-count-clarification.md 確認済み"
    - consistency: "PASS - マークダウン形式で他証跡と整合"
    - completeness: "PASS - 経緯表、時系列、結論を含む"
  - validated: 2026-01-02T08:52:00Z

**status**: done
**max_iterations**: 5

---

### p3: QA 実行と証跡記録

**goal**: scripts/qa.sh を実行して PASS を確認し、証跡を記録する

**depends_on**: [p1]

#### subtasks

- [x] **p3.1**: scripts/qa.sh が exit 0 で終了する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash scripts/qa.sh で exit 0 確認済み"
    - consistency: "PASS - 5/5 PASS 表示"
    - completeness: "PASS - bats/shellcheck/ruff/eslint/npm audit 全 PASS"
  - validated: 2026-01-02T08:52:00Z

- [x] **p3.2**: 新しい QA 証跡が evidence/ に記録されている
  - executor: claudecode
  - validations:
    - technical: "PASS - evidence/qa-results-2026-01-01T23-52-36Z.log 存在確認"
    - consistency: "PASS - 命名規則 qa-results-{timestamp}.log と一致"
    - completeness: "PASS - Result: QA PASSED を含む"
  - validated: 2026-01-02T08:52:00Z

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全条件が満たされているか最終検証

**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p_final.1**: tmp/README.md に前提条件が追記されている（jq, ts-node, bats, shellcheck, ruff, eslint）
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で全6項目確認済み"
    - consistency: "PASS - Prerequisites セクションに整理"
    - completeness: "PASS - インストールコマンド付き"
  - validated: 2026-01-02T08:52:00Z

- [x] **p_final.2**: evidence/ に証跡補足ログが存在する（8→11 tests の経緯を説明）
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f evidence/test-count-clarification.md 確認済み"
    - consistency: "PASS - 時系列で論理的に説明"
    - completeness: "PASS - Summary 表、経緯、結論を含む"
  - validated: 2026-01-02T08:52:00Z

- [x] **p_final.3**: scripts/qa.sh が PASS する
  - executor: claudecode
  - validations:
    - technical: "PASS - exit 0 確認済み"
    - consistency: "PASS - 11 tests 全 PASS"
    - completeness: "PASS - skip 項目なし"
  - validated: 2026-01-02T08:52:00Z

- [x] **p_final.4**: 新しい QA 証跡が evidence/ に記録されている
  - executor: claudecode
  - validations:
    - technical: "PASS - qa-results-2026-01-01T23-52-36Z.log 存在"
    - consistency: "PASS - Result: QA PASSED を含む"
    - completeness: "PASS - 全テスト結果記載"
  - validated: 2026-01-02T08:52:00Z

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - executed: 2026-01-02T08:53:00Z

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: 不要（対象ファイルなし）
  - status: done
  - executed: 2026-01-02T08:53:00Z

- [x] **ft3**: 変更を全てコミットする
  - command: `git commit -m "fix: restore demo files and add prerequisites"`
  - commit: 2f5e452
  - status: done
  - executed: 2026-01-02T08:53:00Z
