# playbook-hook-robustness-phase2.md

## meta

```yaml
project: hook-robustness-phase2
branch: fix/hook-robustness-phase2
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: Phase 2 Hook Robustness 完遂 + Skill/Task ツールブロックによるデッドロック解消
done_when:
  - main-branch.sh で Skill/Task ツールが許可され、playbook 作成がブロックされない
  - subagent-stop.sh の jq 不在時が Fail-closed (exit 2) になっている
  - PB-08/PB-10 の調査が完了し、問題有無が fix-backlog.md に記録されている
  - fix-backlog.md に完了記録が追加されている
```

---

## context

```yaml
5w1h:
  who: Claude Code (executor: claudecode)
  what: 4件の Hook 修正（NEW-01, PB-08, PB-09, PB-10）+ fix-backlog.md 更新
  when: 現セッション
  where: .claude/hooks/, .claude/skills/, docs/
  why: Phase 2 Hook Robustness 完遂 + デッドロック解消
  how: 各ファイルの調査・修正・検証

analysis_result:
  source: pm-manual
  timestamp: 2026-01-03T17:40:00Z
  data:
    risks:
      - risk: main-branch.sh の Skill/Task 許可でセキュリティホール
        probability: low
        impact: high
        mitigation: Edit/Write は引き続きブロック、Skill/Task のみ許可
    findings:
      - NEW-01: 行 48-51 で Skill/Task が許可リストにない（デッドロック原因）
      - PB-09: 行 22-24 で exit 0 (Fail-open) - 明確な問題
      - PB-08: post-tool.sh に明確な問題は見当たらない
      - PB-10: executor-guard.sh 行 48-56 で既に Fail-closed 済み

user_approved_understanding:
  source: user-response
  approved_at: 2026-01-03T17:40:00Z
  summary: |
    - デッドロック問題（NEW-01）が最優先
    - PB-08/PB-10 は調査して問題なければ「調査済み・問題なし」としてマーク
```

---

## phases

### p1: デッドロック解消（最優先）

**goal**: main-branch.sh で Skill/Task ツールを許可し、playbook 作成がブロックされない状態にする

#### subtasks

- [x] **p1.1**: main-branch.sh 行 48-51 に Skill/Task ツールが許可リストに追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果: 行 54-57 に Skill/Task 許可条件と exit 0 を確認"
    - consistency: "PASS - Read/Glob/Grep と同様の形式で追加されている"
    - completeness: "PASS - Skill と Task の両方が許可されている"
  - validated: 2026-01-03T17:50:00Z

**status**: done
**max_iterations**: 3

---

### p2: subagent-stop.sh Fail-closed 化

**goal**: PB-09 の修正 - jq 不在時に Fail-closed (exit 2) にする

#### subtasks

- [x] **p2.1**: subagent-stop.sh 行 22-24 が exit 2 + エラーメッセージに変更されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果: 行 22-24 で exit 2 + エラーメッセージを確認"
    - consistency: "PASS - executor-guard.sh 行 48-56 と同様のパターン"
    - completeness: "PASS - エラーメッセージが stderr に出力される"
  - validated: 2026-01-03T17:50:00Z

**status**: done
**depends_on**: [p1]
**max_iterations**: 3

---

### p3: PB-08/PB-10 調査

**goal**: post-tool.sh と executor-guard.sh の調査を完了し、問題有無を記録

#### subtasks

- [x] **p3.1**: post-tool.sh (PB-08) の調査が完了し、問題有無が判明している
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n で構文エラーなしを確認"
    - consistency: "PASS - fix-backlog.md 行 206-216 に調査結果記録"
    - completeness: "PASS - 調査済み・問題なしとして記録"
  - validated: 2026-01-03T17:50:00Z

- [x] **p3.2**: executor-guard.sh (PB-10) の調査が完了し、問題有無が判明している
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n で構文エラーなしを確認"
    - consistency: "PASS - jq 不在時の Fail-closed が実装済み（行 47-57）"
    - completeness: "PASS - fix-backlog.md 行 229-239 に調査結果記録"
  - validated: 2026-01-03T17:50:00Z

**status**: done
**depends_on**: [p2]
**max_iterations**: 3

---

### p4: fix-backlog.md 更新

**goal**: 完了した修正を fix-backlog.md に記録

#### subtasks

- [x] **p4.1**: PB-26 (NEW-01: main-branch.sh Skill/Task 許可) が追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果: 行 241-251 に PB-26 エントリを確認"
    - consistency: "PASS - 他の PB-XX と同じフォーマットで記載"
    - completeness: "PASS - 概要、Scope、Done when、Validation、Status、修正内容が記載"
  - validated: 2026-01-03T17:50:00Z

- [x] **p4.2**: PB-09 が修正済みとしてマークされている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果: 行 218 に ✅ FIXED を確認"
    - consistency: "PASS - PB-07 と同様の修正済みフォーマット"
    - completeness: "PASS - 修正日、修正内容が記載（行 223-227）"
  - validated: 2026-01-03T17:50:00Z

- [x] **p4.3**: PB-08/PB-10 の調査結果が記録されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果: 行 206, 229 に両項目を確認"
    - consistency: "PASS - INVESTIGATED として記録"
    - completeness: "PASS - 調査日、調査内容が記載"
  - validated: 2026-01-03T17:50:00Z

**status**: done
**depends_on**: [p3]
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証

#### subtasks

- [x] **p_final.1**: main-branch.sh で Skill/Task ツールが許可されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果で Skill/Task 許可条件と exit 0 を確認"
    - consistency: "PASS - Read/Glob/Grep と同じ形式で許可"
    - completeness: "PASS - Skill と Task の両方が許可"
  - validated: 2026-01-03T17:50:00Z

- [x] **p_final.2**: subagent-stop.sh の jq 不在時が Fail-closed (exit 2) になっている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果で exit 2 を確認"
    - consistency: "PASS - executor-guard.sh と同様のパターン"
    - completeness: "PASS - エラーメッセージ + exit 2"
  - validated: 2026-01-03T17:50:00Z

- [x] **p_final.3**: PB-08/PB-10 の調査結果が fix-backlog.md に記録されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果で両項目の記録を確認"
    - consistency: "PASS - 他の調査済み項目と同じフォーマット"
    - completeness: "PASS - 調査日、結果、理由が記載"
  - validated: 2026-01-03T17:50:00Z

- [x] **p_final.4**: fix-backlog.md に完了記録が追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果で PB-26、PB-09 を確認"
    - consistency: "PASS - 他の修正済み項目と同じフォーマット"
    - completeness: "PASS - 全ての修正項目が記録"
  - validated: 2026-01-03T17:50:00Z

**status**: done
**depends_on**: [p4]
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
