# playbook-verify-prompt-sh-grep-awk.md

> **prompt.sh 内の grep/awk の 0 件時エラー挙動を網羅的に検証**

---

## meta

```yaml
project: verify-prompt-sh-grep-awk
branch: fix/verify-prompt-sh-grep-awk
created: 2026-01-03
issue: PB-07
reviewed: true
```

---

## goal

```yaml
summary: prompt.sh 内の全 grep/awk 使用箇所を精査し、0 件時のエラーハンドリングを検証・必要なら修正する
done_when:
  - prompt.sh 内の全 grep/awk 使用箇所（行 18, 20, 47, 50, 52）のエラーハンドリング状態が文書化されている
  - 0 件/パターン不一致ケースでのテスト実行結果が exit 0 を維持する
  - 問題がある場合は修正済み、問題がない場合は「検証済み・問題なし」が証拠付きで記録されている
```

---

## context

```yaml
5w1h:
  who: Claude Code が実行
  what: prompt.sh 内の grep/awk 使用箇所の 0 件時エラー挙動を検証・修正
  when: このセッションで完了
  where: .claude/hooks/prompt.sh
  why: docs/fix-backlog.md の PB-07 として登録されているが、Section 2 分析では「問題なし」と記載。網羅的検証が必要
  how: 全箇所を列挙 → テストシナリオ作成・実行 → 問題があれば修正

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-03T16:45:00Z
  data:
    5w1h:
      who: Claude Code
      what: prompt.sh の grep/awk 0件時エラー検証
      when: 即時
      where: .claude/hooks/prompt.sh
      why: PB-07 対応、網羅的検証の必要性
      how: 静的分析 + 動的テスト
    risks:
      technical:
        - risk: "set -e 環境下で grep 0件時に exit 1 が発生する可能性"
          severity: medium
          mitigation: "|| echo 'fallback' でフォールバック"
      scope:
        - risk: "テストシナリオが不十分で問題を見逃す"
          severity: low
          mitigation: "複数エッジケースをテスト"
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T16:45:00Z
  summary: "prompt.sh の全 grep/awk 使用箇所を精査し、0 件時エラーを検証・修正する"
  approved_items:
    - question_id: q1
      question: "全箇所を検証しますか？"
      answer: "はい、全箇所を検証"
    - question_id: q2
      question: "この理解で進めてよいですか？"
      answer: "はい、進めてください"
```

---

## phases

### p1: 静的分析

**goal**: prompt.sh 内の全 grep/awk 使用箇所を列挙し、エラーハンドリング状態を文書化する

#### subtasks

- [x] **p1.1**: 全 grep/awk 使用箇所（行 18, 20, 47, 50, 52）のエラーハンドリング状態が一覧化されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -n 'grep\\|awk' prompt.sh で 5 箇所確認（行 18, 20, 47, 50, 52）"
    - consistency: "PASS - 行18: || echo null, 行20: || echo unknown, 行47: awk は exit 0, 行50/52: || echo 0"
    - completeness: "PASS - 5箇所全てが分析されている"
  - validated: 2026-01-03T16:50:00Z
  - critic: PASS
  - codex: PASS

**status**: done
**max_iterations**: 5

---

### p2: テストシナリオ作成・実行

**goal**: 0 件/パターン不一致ケースで prompt.sh が exit 0 を維持することを検証

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: テストシナリオが tmp/test-prompt-sh-grep.sh として作成されている
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f で存在確認済み"
    - consistency: "PASS - 9テストケースで5箇所全てカバー（行18,20,47,52,55）"
    - completeness: "PASS - エッジケース含む（空入力、パターン不一致、全体実行）"
  - validated: 2026-01-03T16:55:00Z
  - critic: PASS
  - codex: PASS

- [x] **p2.2**: テストシナリオが exit 0 で終了する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash tmp/test-prompt-sh-grep.sh → EXIT_CODE: 0"
    - consistency: "PASS - PASSED: 9, FAILED: 0"
    - completeness: "PASS - 全5箇所のテスト実行済み"
  - validated: 2026-01-03T16:55:00Z
  - critic: PASS
  - codex: PASS
  - note: "バグ発見・修正: pipefail環境でgrep -c問題 → || true + ${var:-0}に修正"

**status**: done
**max_iterations**: 5

---

### p3: 修正または検証結果の記録

**goal**: 問題があれば修正、なければ「検証済み・問題なし」を記録

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: 検証結果が docs/fix-backlog.md の PB-07 に記録されている
  - executor: claudecode
  - validations:
    - technical: "PASS - PB-07 に ✅ FIXED ステータス追加、P1-09 も更新"
    - consistency: "PASS - 修正済み(2026-01-03)、修正内容詳細を記載"
    - completeness: "PASS - 9テストケース全PASS への参照あり"
  - validated: 2026-01-03T17:00:00Z
  - critic: PASS (再作成後)
  - codex: PASS

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: 全 grep/awk 使用箇所のエラーハンドリング状態が文書化されている
  - executor: claudecode
  - validations:
    - technical: "PASS - p1.1 で 5 箇所分析済み（行18,20,47,52,55）"
    - consistency: "PASS - 5 箇所全て分析・文書化"
    - completeness: "PASS - 各箇所の保護状態明記"
  - validated: 2026-01-03T17:05:00Z
  - codex: PASS

- [x] **p_final.2**: 0 件/パターン不一致ケースでのテスト実行結果が exit 0 を維持する
  - executor: claudecode
  - validations:
    - technical: "PASS - 9テストケース全PASS"
    - consistency: "PASS - pipefail環境でテスト"
    - completeness: "PASS - エッジケース含む"
  - validated: 2026-01-03T17:05:00Z
  - codex: PASS

- [x] **p_final.3**: 検証結果が証拠付きで記録されている
  - executor: claudecode
  - validations:
    - technical: "PASS - docs/fix-backlog.md PB-07 に ✅ FIXED"
    - consistency: "PASS - 修正内容・テスト結果を記載"
    - completeness: "PASS - 結論（修正済み）明記"
  - validated: 2026-01-03T17:05:00Z
  - codex: PASS

**status**: done
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
