# playbook-pb01-pb08-hook-fixes.md

## meta

```yaml
project: pb01-pb08-hook-fixes
branch: fix/pb01-pb08-hook-fixes
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: PB-01（playbook-guard.sh timeout）と PB-08（post-tool.sh CLOSED）を1つの playbook で処理
done_when:
  - playbook-guard.sh の `INPUT=$(cat)` が `timeout` 付きパターンに変更されている
  - 修正後の playbook-guard.sh が `bash -n` を通過する
  - PB-08 が fix-backlog.md で正式に CLOSED としてマーキングされている
  - PB-01 が fix-backlog.md で FIXED としてマーキングされている
```

---

## context

```yaml
5w1h:
  who: Claude Code 自律運用フレームワーク
  what: PB-01（playbook-guard.sh の cat 無限ハング防止）と PB-08（調査完了確認記録）
  when: 本セッションで完了
  where: .claude/skills/playbook-gate/guards/playbook-guard.sh, docs/fix-backlog.md
  why: PB-01 は無限ハング防止、PB-08 は調査完了・問題なし判定の記録
  how: PB-01 は timeout 5 cat パターン、PB-08 は CLOSED マーキング

analysis_result:
  source: understanding-check（スキップ - ユーザー指示により事前完了）
  timestamp: 2026-01-03T18:30:00Z
  data:
    5w1h:
      what: "PB-01 と PB-08 を1つの playbook で実施"
      why: "PB-01 は無限ハング防止、PB-08 は調査完了記録"
      where: "playbook-guard.sh, fix-backlog.md"
      how: "timeout 5 cat パターン、CLOSED マーキング"
    risks:
      technical:
        - risk: "timeout コマンドがない環境での動作"
          severity: low
          mitigation: "macOS/Linux 両方で timeout は標準装備"
      scope:
        - risk: "PB-01 と PB-08 の関連性が薄い"
          severity: low
          mitigation: "ユーザーが明示的に1つの playbook を要求"
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T18:30:00Z
  summary: "PB-01（timeout追加）と PB-08（CLOSED記録）を1つの playbook で実施"
  approved_items:
    - question_id: q1
      question: "PB-01 と PB-08 を1つの playbook で処理してよいか"
      answer: "はい"
```

---

## phases

### p1: PB-01 playbook-guard.sh timeout 追加

**goal**: playbook-guard.sh の `INPUT=$(cat)` を timeout 付きに変更し、無限ハングを防止

#### subtasks

- [x] **p1.1**: playbook-guard.sh の行 35 が `timeout 5 cat` パターンに変更されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 行35: `if ! INPUT=$(timeout 5 cat 2>/dev/null); then`"
    - consistency: "PASS - 他の hook と同様の timeout パターンを使用"
    - completeness: "PASS - INPUT 変数が正しく設定される"
  - validated: 2026-01-03T18:45:00Z

- [x] **p1.2**: 修正後の playbook-guard.sh が `bash -n` を通過する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n exit code: 0"
    - consistency: "PASS - 既存の動作を壊さない"
    - completeness: "PASS - 全ての構文が正しい"
  - validated: 2026-01-03T18:45:00Z

**status**: done
**max_iterations**: 5

---

### p2: PB-08 fix-backlog.md CLOSED マーキング

**goal**: PB-08 を fix-backlog.md で正式に CLOSED としてマーキング

**depends_on**: []

#### subtasks

- [x] **p2.1**: PB-08 セクションに CLOSED ステータスが追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 'PB-08.*CLOSED' 確認済み"
    - consistency: "PASS - PB-07, PB-09 と同じフォーマット"
    - completeness: "PASS - Status 行と調査結果が記載"
  - validated: 2026-01-03T18:45:00Z

**status**: done
**max_iterations**: 3

---

### p3: PB-01 fix-backlog.md FIXED マーキング

**goal**: PB-01 を fix-backlog.md で FIXED としてマーキング

**depends_on**: [p1]

#### subtasks

- [x] **p3.1**: PB-01 セクションに FIXED ステータスが追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 'PB-01.*FIXED' 確認済み"
    - consistency: "PASS - PB-07, PB-09 と同じフォーマット"
    - completeness: "PASS - Status 行と修正内容が記載"
  - validated: 2026-01-03T18:45:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p_final.1**: playbook-guard.sh の `INPUT=$(cat)` が `timeout` 付きパターンに変更されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 行35: `if ! INPUT=$(timeout 5 cat 2>/dev/null); then`"
    - consistency: "PASS - timeout が INPUT 変数の設定に使用されている"
    - completeness: "PASS - 行 35-38 が修正されている"
  - validated: 2026-01-03T18:45:00Z

- [x] **p_final.2**: 修正後の playbook-guard.sh が `bash -n` を通過する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n exit code: 0"
    - consistency: "PASS - 構文エラーがない"
    - completeness: "PASS - 全ての構文が正しい"
  - validated: 2026-01-03T18:45:00Z

- [x] **p_final.3**: PB-08 が fix-backlog.md で正式に CLOSED としてマーキングされている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 'PB-08.*CLOSED' 確認済み"
    - consistency: "PASS - 他の CLOSED/FIXED と同じフォーマット"
    - completeness: "PASS - 調査結果が記載されている"
  - validated: 2026-01-03T18:45:00Z

- [x] **p_final.4**: PB-01 が fix-backlog.md で FIXED としてマーキングされている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 'PB-01.*FIXED' 確認済み"
    - consistency: "PASS - 他の FIXED と同じフォーマット"
    - completeness: "PASS - 修正内容が記載されている"
  - validated: 2026-01-03T18:45:00Z

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
