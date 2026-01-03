# playbook-fix-failure-logger.md

## meta

```yaml
project: fix-failure-logger
branch: fix/remove-failure-logger-ref
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: playbook-guard.sh から存在しない failure-logger.sh への参照を削除する（最小修正）
done_when:
  - playbook-guard.sh に failure-logger.sh への参照が含まれていない
  - bash -n playbook-guard.sh がエラーなく通る
  - rg "failure-logger" .claude の結果に playbook-guard.sh が含まれない
```

---

## context

```yaml
5w1h:
  who: Claude Code フレームワーク開発者/メンテナー
  what: playbook-guard.sh から欠損している failure-logger.sh への参照を削除
  when: 即時対応（P0 Guard Stability の一部）
  where: .claude/skills/playbook-gate/guards/playbook-guard.sh（行 108-110, 139-141, 172-174）
  why: 存在しないファイルへの参照を削除してコードを簡素化するため
  how: 3箇所の if ブロック（failure-logger.sh 呼び出し）を削除

analysis_result:
  source: docs/fix-backlog.md
  timestamp: 2026-01-03
  data:
    reference: PB-02
    problem: |
      failure-logger.sh は存在しないが、playbook-guard.sh の3箇所で参照されている。
      現在は [[ -f ... ]] で存在チェック後に呼び出しているため動作はするが、
      存在しないファイルへの参照はコードのノイズとなる。
    risks:
      technical: []
      scope:
        - risk: failure-logger.sh を将来実装する可能性
          severity: low
          mitigation: 現時点では実装予定なし。必要になれば再実装する
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

translated_requirements:
  source: user-decision
  timestamp: 2026-01-03
  data:
    original_terms:
      - original: "欠損参照を削除"
        translated: "存在しないファイルへの参照コードブロックを削除"
        rationale: 最小修正の方針に従う
        alternatives:
          - "failure-logger.sh を新規実装する"
    technical_requirements:
      - requirement: 行 108-110, 139-141, 172-174 の if ブロックを削除
        derived_from: "欠損参照を削除"
        implementation_hint: 各ブロックは独立しており、削除しても他のロジックに影響なし

user_approved_understanding:
  source: user-prompt
  approved_at: 2026-01-03
  summary: |
    方針: 参照削除（最小修正）
    failure-logger.sh は存在しないため、呼び出しコードを削除してコードを簡素化する。
  approved_items:
    - question_id: approach
      question: "欠損参照への対応方針"
      answer: "参照削除（最小修正）"
  technical_requirements_confirmed:
    - original: "欠損参照を削除"
      confirmed_translation: "3箇所の if ブロック（行 108-110, 139-141, 172-174）を削除"
```

---

## phases

### p1: failure-logger 参照削除

**goal**: playbook-guard.sh から failure-logger.sh への参照を削除する

#### subtasks

- [x] **p1.1**: 行 108-110 の failure-logger.sh 呼び出しブロックが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -c 'failure-logger' playbook-guard.sh → 0"
    - consistency: "PASS - cat >&2 パターンは維持"
    - completeness: "PASS - ブロック全体が削除済み"
  - validated: 2026-01-03T15:30:00

- [x] **p1.2**: 行 139-141 の failure-logger.sh 呼び出しブロックが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で該当コードなし"
    - consistency: "PASS - playbook ファイル存在チェックは維持"
    - completeness: "PASS - if ブロック全体が削除済み"
  - validated: 2026-01-03T15:30:00

- [x] **p1.3**: 行 172-174 の failure-logger.sh 呼び出しブロックが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で該当コードなし"
    - consistency: "PASS - reviewed チェックロジックは維持"
    - completeness: "PASS - if ブロック全体が削除済み"
  - validated: 2026-01-03T15:30:00

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証
**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: playbook-guard.sh に failure-logger.sh への参照が含まれていない
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -c 'failure-logger' → 0"
    - consistency: "PASS - playbook-guard.sh は正常動作"
    - completeness: "PASS - 全3箇所の参照削除済み"
  - validated: 2026-01-03T15:30:00

- [x] **p_final.2**: bash -n playbook-guard.sh がエラーなく通る
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n → exit code 0, Syntax OK"
    - consistency: "PASS - シンタックスエラーなし"
    - completeness: "PASS - ファイル全体がパース可能"
  - validated: 2026-01-03T15:30:00

- [x] **p_final.3**: rg "failure-logger" .claude の結果に playbook-guard.sh が含まれない
  - executor: claudecode
  - validations:
    - technical: "PASS - rg 結果に playbook-guard.sh なし"
    - consistency: "PASS - SKILL_INDEX_v2.md のみ（ドキュメント）"
    - completeness: "PASS - done_when 条件が完全に満たされている"
  - validated: 2026-01-03T15:30:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: skipped (no structural changes)

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: skipped (no temp files)

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git commit`
  - status: done
  - commit: 8670cbf
  - pr: https://github.com/M2AI-jp/thanks4claudecode-fresh/pull/72
