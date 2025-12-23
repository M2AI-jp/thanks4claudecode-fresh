# playbook-4qv-e2e-verification-v2.md

> **4QV+ アーキテクチャの E2E 動作検証 - Iteration 2**
>
> Iteration 1 で修正した問題が解消され、クリーンに動作することを検証

---

## meta

```yaml
project: thanks4claudecode
branch: refactor/4qv-architecture-rebuild
created: 2025-12-24
iteration: 2
previous: plan/archive/playbook-4qv-e2e-verification-v1.md
issue: null
derives_from: null
reviewed: false
roles:
  worker: claudecode
quality_gate: |
  各 Phase の最後に reviewer でレビュー必須。
  「目先のテストクリアを目標にしたテスト」を検出したら REJECT。
  ALL GREEN になるまで設計を修正する。
```

---

## goal

```yaml
summary: |
  4QV+ アーキテクチャが「ユーザーの自然言語 → workflow 自動発火 → Skill 連携」
  として正しく動作することを検証し、ALL GREEN を達成する。

done_when:
  - Golden Path E2E: 自然言語タスク依頼 → Skill(playbook-init) → playbook 作成が動作
  - Playbook Gate E2E: playbook=null で Edit がブロック → Skill 呼び出し誘導が動作
  - Reward Guard E2E: done_when 未達成で完了ブロック → Skill(crit) 呼び出し誘導が動作
  - Access Control E2E: HARD_BLOCK ファイル保護が動作
  - 全テスト ALL GREEN（KNOWN_LIMITATION は許されない）

iteration_goal: |
  Iteration 1 で以下の修正を適用:
  - Task() → Skill() への移行
  - stderr 出力への統一
  - contract.sh のセキュリティ強化

  Iteration 2 ではこれらの修正が正しく動作し、
  クリーンに ALL GREEN を達成できることを検証する。
```

---

## phases

### p0: E2E contract test 実行

**goal**: 前回の修正が適用された状態で E2E テストが ALL GREEN になることを確認

#### subtasks

- [x] **p0.1**: E2E contract test 実行
  - command: "bash scripts/e2e-contract-test.sh"
  - expected: "52/52 PASS - ALL TESTS PASSED"
  - result: "52/52 PASS - ALL TESTS PASSED (first try)"
  - validations:
    - technical: "PASS - 52/52 テスト PASS"
    - consistency: "PASS - Iteration 1 の修正が維持されている"
    - completeness: "PASS - 全シナリオ網羅"
  - validated: 2025-12-24T12:00:00

- [x] **p0.review**: reviewer でレビュー
  - result: "PASS - E2E テスト即座に ALL GREEN、修正が正しく適用されている"

**status**: completed
**max_iterations**: 3

---

### p1: Golden Path 再検証

**goal**: playbook=null でのブロックと Skill 誘導が正しく動作することを確認

#### subtasks

- [x] **p1.1**: playbook=null での Edit ブロック確認
  - scenario: "playbook=null 状態で Edit を試行"
  - expected: "ブロックメッセージに Skill(skill='playbook-init') が含まれる"
  - result: "PASS - ブロックメッセージに Skill(skill='playbook-init') と /playbook-init が表示"
  - validations:
    - technical: "PASS - playbook=null で Edit がブロックされた"
    - consistency: "PASS - ブロックメッセージが Skill() 形式を推奨"
    - completeness: "PASS - /playbook-init も代替として表示"
  - validated: 2025-12-24T12:05:00

- [x] **p1.review**: reviewer でレビュー
  - result: "PASS - Golden Path が正しく動作、Skill 誘導メッセージ表示"

**status**: completed
**max_iterations**: 3

---

### p2: Reward Guard 再検証

**goal**: subtask-guard と crit Skill が正しく動作することを確認

#### subtasks

- [x] **p2.1**: null validations での Edit ブロック確認
  - scenario: "validations が null の subtask を完了にしようとする"
  - expected: "ブロックメッセージに Skill(skill='crit') が含まれる"
  - result: "PASS - subtask-guard がブロック、Skill(skill='crit') 推奨メッセージ表示"
  - validations:
    - technical: "PASS - null validations で Edit がブロックされた"
    - consistency: "PASS - ブロックメッセージに Skill(skill='crit') / /crit が含まれる"
    - completeness: "PASS - 3検証 (technical/consistency/completeness) の要求が表示される"
  - validated: 2025-12-24T12:10:00

- [x] **p2.2**: Skill(skill='crit') の動作確認
  - scenario: "Skill ツールで crit を呼び出す"
  - expected: "done_when の検証が実行される"
  - result: "PASS - done_criteria 5項目すべてについて PASS/FAIL 判定と証拠が表示された"
  - validations:
    - technical: "PASS - Skill(skill='crit') が正常に呼び出された"
    - consistency: "PASS - state.md の done_criteria が取得され評価された"
    - completeness: "PASS - 5つの criteria について判定と証拠が表示された"
  - validated: 2025-12-24T12:15:00

- [x] **p2.review**: reviewer でレビュー
  - result: "PASS - Reward Guard が正しく動作、crit Skill で done_criteria 検証完了"

**status**: completed
**max_iterations**: 3

---

### p3: Access Control 再検証

**goal**: HARD_BLOCK ファイル保護が正しく動作することを確認

#### subtasks

- [x] **p3.1**: CLAUDE.md への Edit ブロック確認
  - scenario: "CLAUDE.md を Edit しようとする"
  - expected: "HARD_BLOCK エラーでブロック"
  - result: "PASS - [HARD_BLOCK] 絶対守護ファイル でブロック"
  - validations:
    - technical: "PASS - Edit がブロックされた"
    - consistency: "PASS - M079 Core Contract メッセージが表示"
    - completeness: "PASS - admin モードでもブロック"
  - validated: 2025-12-24T12:20:00

- [x] **p3.2**: CLAUDE.md への Bash ブロック確認
  - scenario: "echo >> CLAUDE.md を実行しようとする"
  - expected: "HARD_BLOCK エラーでブロック"
  - result: "PASS - [HARD_BLOCK] Bash による絶対守護ファイルへの書き込み でブロック"
  - validations:
    - technical: "PASS - Bash がブロックされた"
    - consistency: "PASS - bash-check.sh が HARD_BLOCK ファイルを検出"
    - completeness: "PASS - Edit と Bash 両方でブロック確認"
  - validated: 2025-12-24T12:20:00

- [x] **p3.review**: reviewer でレビュー
  - result: "PASS - Access Control が正しく動作、HARD_BLOCK で Edit/Bash 両方ブロック"

**status**: completed
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: 全 Phase が completed (p0-p3 全て completed)
- [x] **ft2**: 全テスト ALL GREEN (52/52 PASS)
- [x] **ft3**: reviewer の最終 PASS
- [ ] **ft4**: コミット

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-24 | Iteration 2 作成。v1 の修正を検証。 |
