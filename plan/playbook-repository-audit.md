# playbook-repository-audit.md

> **報酬詐欺防止の設計改善: playbook チェックボックス更新の強制化、Phase 完了検証の強化**

---

## meta

```yaml
project: repository-audit
branch: feat/repository-audit
created: 2026-01-02
issue: null
reviewed: true
```

---

## goal

```yaml
summary: 報酬詐欺防止の構造的強制を改善し、playbook チェックボックス更新・Phase 完了検証・critic 呼び出しを確実にする
done_when:
  - phase-status-guard.sh が存在し、Phase status 変更時に全 subtask 完了を検証する
  - subtask-guard.sh が critic 呼び出しを構造的に強制する
  - archive-playbook.sh が全 subtask `[x]` を検証し、`[ ]` が残っていればアーカイブを拒否する
  - RUNBOOK.md に TodoWrite と playbook の関係ルールが記載されている
  - prompt.sh でユーザープロンプト時に subtask 状況リマインダーが表示される
  - pre-tool.sh から phase-status-guard.sh が呼び出される
```

---

## context

```yaml
5w1h:
  who: Claude Code（LLM）の自己判断による報酬詐欺を防止
  what: playbook チェックボックス更新の強制化、Phase 完了検証の強化
  when: 本セッションで実装
  where: .claude/skills/reward-guard/guards/ 配下および関連ファイル
  why: repository-audit playbook で報酬詐欺が発生（全チェックボックス未更新、全phase pending のまま、critic 未呼び出し）
  how: 新規 guard スクリプト追加、既存スクリプト強化、RUNBOOK.md 更新

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-02T21:00:00Z
  data:
    risks:
      technical:
        - risk: 既存ワークフロー破壊
          severity: low
          mitigation: 既存ロジックは保持し、追加チェックのみ
      scope:
        - risk: M088 既存ロジックとの重複
          severity: medium
          mitigation: 責務を明確に分離
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-02T21:10:00Z
  summary: |
    ユーザー確認済み:
    - phase-status-guard.sh を別ファイルに分離（責務分離）
    - 既存 M088 ロジックは subtask-guard.sh に残す
    - prompt.sh でリマインダー機能を追加

implementation_learnings:
  timestamp: 2026-01-02T22:10:00Z
  issues_found:
    - issue: "awk パターンが subtask 説明文内のテキストを誤検出"
      location: "phase-status-guard.sh"
      fix: "行頭マッチ (^) と行末マッチ ($) を追加"
      example: "`**status**: pending/in_progress` という説明文が誤って status 行として検出された"
    - issue: "critic は Phase 単位で動作するため、subtask 単位の BLOCK は非現実的"
      location: "subtask-guard.sh p2.1"
      fix: "BLOCK から systemMessage での必須指示に変更"
      note: "critic-results.log には subtask レベルのエントリがない"
  best_practices:
    - "Phase 進行に合わせて state.md の phase を更新すること"
    - "TodoWrite と playbook チェックボックスの両方を更新すること"
    - "awk/grep パターンは行頭・行末アンカーを使って誤検出を防ぐこと"
```

---

## phases

### p1: phase-status-guard.sh 新規作成

**goal**: Phase status 変更専用の guard スクリプトを作成し、全 subtask 完了を検証する

#### subtasks

- [x] **p1.1**: `.claude/skills/reward-guard/guards/phase-status-guard.sh` が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f 確認済み、bash -n シンタックス OK"
    - consistency: "PASS - subtask-guard.sh は subtask 検証、phase-status-guard.sh は Phase status 検証で責務分離"
    - completeness: "PASS - pending→done, in_progress→done, completed 全パターン対応"
  - validated: 2026-01-02T21:30:00Z

- [x] **p1.2**: phase-status-guard.sh が Phase `**status**: pending/in_progress` -> `**status**: done` 変更を検出する
  - executor: claudecode
  - validations:
    - technical: "PASS - テスト実行で pending→done, in_progress→done 検出確認"
    - consistency: "PASS - V12 チェックボックス形式と整合（- [ ]/- [x] カウント）"
    - completeness: "PASS - Markdown bold **status** 形式に対応"
  - validated: 2026-01-02T21:30:00Z

- [x] **p1.3**: phase-status-guard.sh が未完了 subtask (`- [ ]`) がある場合に BLOCK を返す
  - executor: claudecode
  - validations:
    - technical: "PASS - exit 2 で BLOCK 確認（テスト実行済み）"
    - consistency: "PASS - subtask-guard.sh と同様の stderr エラー形式"
    - completeness: "PASS - 未完了 subtask リスト + 完了手順ガイダンス表示"
  - validated: 2026-01-02T21:30:00Z

**status**: done
**max_iterations**: 5

---

### p2: subtask-guard.sh 強化

**goal**: critic 呼び出しを構造的に強制するロジックを追加

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: subtask-guard.sh が `- [ ]` -> `- [x]` 変更時に critic 呼び出しを必須として指示する
  - executor: claudecode
  - validations:
    - technical: "PASS - systemMessage で critic 必須を指示、最後の subtask 時は特に強調"
    - consistency: "PASS - 既存の validations チェックを保持"
    - completeness: "PASS - 全パターン対応、残り subtask 数も表示"
  - validated: 2026-01-02T21:45:00Z
  - note: "subtask 単位の BLOCK は実用上困難（critic は Phase 単位）。代わりに systemMessage で必須指示"

- [x] **p2.2**: subtask-guard.sh の M088 Phase 変更ロジックを phase-status-guard.sh への参照に置き換える
  - executor: claudecode
  - validations:
    - technical: "PASS - M088 ロジック削除（行 75-139 → 行 75-87 に縮小）、phase-status-guard.sh 参照コメント追加"
    - consistency: "PASS - 責務分離明確（subtask-guard=checkbox, phase-status-guard=status 行）"
    - completeness: "PASS - Phase 変更検出は exit 0 でスキップ、phase-status-guard.sh に委譲"
  - validated: 2026-01-02T21:45:00Z

**status**: done
**max_iterations**: 5

---

### p3: archive-playbook.sh 強化

**goal**: 全 subtask `[x]` 検証を厳密化し、`[ ]` 残存時のアーカイブを確実にブロック

**depends_on**: [p1]

#### subtasks

- [x] **p3.1**: archive-playbook.sh が全 subtask の `[x]` チェックを Phase 単位で実行する
  - executor: claudecode
  - validations:
    - technical: "PASS - while ループで Phase ごとに未完了 subtask をパース"
    - consistency: "PASS - V12 形式（- [ ] / - [x]）と整合"
    - completeness: "PASS - final_tasks は別セクションで既存チェックあり"
  - validated: 2026-01-02T21:50:00Z

- [x] **p3.2**: archive-playbook.sh が `[ ]` 残存時に詳細なブロックメッセージを表示する
  - executor: claudecode
  - validations:
    - technical: "PASS - exit 2 でブロック（既存の exit 0 を変更）"
    - consistency: "PASS - stderr 出力、SEP 区切り、ガイダンス形式で整合"
    - completeness: "PASS - Phase 別に未完了 subtask ID を表示"
  - validated: 2026-01-02T21:50:00Z

**status**: done
**max_iterations**: 5

---

### p4: RUNBOOK.md 更新

**goal**: TodoWrite と playbook の関係ルールを明記し、行動規範を強化

**depends_on**: [p1]

#### subtasks

- [x] **p4.1**: RUNBOOK.md に "TodoWrite と playbook の関係" セクションが追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'TodoWrite と Playbook の関係' RUNBOOK.md で確認済み"
    - consistency: "PASS - 既存スタイル（yaml コードブロック、表形式）と整合"
    - completeness: "PASS - 2つのシステムの役割、禁止行為、Guard 一覧、ワークフロー例を記載"
  - validated: 2026-01-02T21:55:00Z

- [x] **p4.2**: RUNBOOK.md に subtask 完了時の必須フローが記載されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 'subtask 完了チェックリスト' セクション追加済み"
    - consistency: "PASS - playbook-format.md の validations 形式と整合"
    - completeness: "PASS - 1.作業完了 → 2.crit → 3.validations → 4.[x] → 5.validated → 6.TodoWrite"
  - validated: 2026-01-02T21:55:00Z

**status**: done
**max_iterations**: 5

---

### p5: prompt.sh 強化

**goal**: ユーザープロンプト時に現在 Phase の subtask 状況を表示し、リマインダーを出す

**depends_on**: [p1, p2]

#### subtasks

- [x] **p5.1**: prompt.sh が現在の Phase の subtask 完了状況を取得する
  - executor: claudecode
  - validations:
    - technical: "PASS - awk で Phase セクション抽出、grep -c で [x]/[ ] カウント"
    - consistency: "PASS - state.md の goal.phase 値を使用"
    - completeness: "PASS - completed/incomplete/total を計算"
  - validated: 2026-01-02T22:00:00Z

- [x] **p5.2**: prompt.sh が未完了 subtask がある場合にリマインダーを表示する
  - executor: claudecode
  - validations:
    - technical: "PASS - subtask_reminder 変数を State Injection content に追加"
    - consistency: "PASS - 既存の messages 形式を維持"
    - completeness: "PASS - 進捗表示 + チェックボックス更新 + critic 呼び出しを促すメッセージ"
  - validated: 2026-01-02T22:00:00Z

**status**: done
**max_iterations**: 5

---

### p6: pre-tool.sh 統合

**goal**: phase-status-guard.sh を pre-tool.sh の呼び出し順序に追加

**depends_on**: [p1]

#### subtasks

- [x] **p6.1**: pre-tool.sh の Edit|Write セクションに phase-status-guard.sh 呼び出しが追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - invoke_skill reward-guard guards/phase-status-guard.sh 追加済み"
    - consistency: "PASS - 他の guard と同じ invoke_skill パターン"
    - completeness: "PASS - subtask-guard.sh の直後、scope-guard.sh の前に配置"
  - validated: 2026-01-02T22:05:00Z

**status**: done
**max_iterations**: 5

---

### p_self_update: playbook の自己更新

**goal**: 実装で得た知見を playbook 自体に反映

**depends_on**: [p1, p2, p3, p4, p5, p6]

#### subtasks

- [x] **p_self_update.1**: 実装中に発見した課題・改善点を playbook に反映
  - executor: claudecode
  - validations:
    - technical: "PASS - context セクションに implementation_learnings 追加"
    - consistency: "PASS - playbook-format.md 形式と整合（yaml ブロック内）"
    - completeness: "PASS - 2つの issue と 3つの best_practices を記録"
  - validated: 2026-01-02T22:10:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p1, p2, p3, p4, p5, p6, p_self_update]

#### subtasks

- [x] **p_final.1**: phase-status-guard.sh が存在し、Phase status 変更時に全 subtask 完了を検証する
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f 確認、exit 2 でブロック動作"
    - consistency: "PASS - P6 status 変更時に正常動作（パターン修正後）"
    - completeness: "PASS - 未完了 subtask 一覧表示、ガイダンス表示"
  - validated: 2026-01-02T22:15:00Z

- [x] **p_final.2**: subtask-guard.sh が critic 呼び出しを構造的に強制する
  - executor: claudecode
  - validations:
    - technical: "PASS - require_critic アクション、systemMessage に critic 必須メッセージ"
    - consistency: "PASS - 既存 validations チェック維持"
    - completeness: "PASS - 最後の subtask 時に特別警告"
  - validated: 2026-01-02T22:15:00Z

- [x] **p_final.3**: archive-playbook.sh が全 subtask [x] を検証し、[ ] が残っていればアーカイブを拒否する
  - executor: claudecode
  - validations:
    - technical: "PASS - exit 2 でブロック、Phase 別未完了 subtask 表示"
    - consistency: "PASS - V12 形式と整合"
    - completeness: "PASS - ブロックメッセージに完了手順ガイダンス含む"
  - validated: 2026-01-02T22:15:00Z

- [x] **p_final.4**: RUNBOOK.md に TodoWrite と playbook の関係ルールが記載されている
  - executor: claudecode
  - validations:
    - technical: "PASS - TodoWrite と Playbook の関係 セクション存在"
    - consistency: "PASS - 既存 yaml 表形式と整合"
    - completeness: "PASS - 2つのシステムの役割、報酬詐欺防止ルール、ワークフロー例"
  - validated: 2026-01-02T22:15:00Z

- [x] **p_final.5**: prompt.sh でユーザープロンプト時に subtask 状況リマインダーが表示される
  - executor: claudecode
  - validations:
    - technical: "PASS - subtask_reminder 変数、awk で Phase セクション抽出"
    - consistency: "PASS - State Injection messages 形式維持"
    - completeness: "PASS - 進捗表示 + チェックボックス更新 + critic 呼び出し促進"
  - validated: 2026-01-02T22:15:00Z

- [x] **p_final.6**: pre-tool.sh から phase-status-guard.sh が呼び出される
  - executor: claudecode
  - validations:
    - technical: "PASS - invoke_skill reward-guard guards/phase-status-guard.sh 存在"
    - consistency: "PASS - subtask-guard.sh の直後に配置"
    - completeness: "PASS - invoke_skill 形式"
  - validated: 2026-01-02T22:15:00Z

**status**: done
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
