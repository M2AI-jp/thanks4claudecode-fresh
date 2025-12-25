# playbook-fix-architecture-issues.md

> **アーキテクチャ総合テストで発見した3つの問題（オーケストレーション不在、バックグラウンドタスク残存、検証形骸化）を修正**

---

## meta

```yaml
project: fix-architecture-issues
branch: fix/architecture-issues
created: 2025-12-25
issue: null
reviewed: true
context:
  source: アーキテクチャ総合テスト実行結果
  problems:
    - 問題2: オーケストレーション不在（toolstack: B でも codex-delegate が呼ばれない）
    - 問題3: バックグラウンドタスク残存（run_in_background: true のプロセスが残る）
    - 問題4: 検証形骸化（3種類のレビュアーが4QV+レビューを実行していない）
  affected_files:
    - .claude/skills/playbook-gate/guards/executor-guard.sh
    - .claude/skills/session-manager/handlers/*.sh
    - .claude/agents/reviewer.md
    - .claude/agents/critic.md
  user_choices:
    problem2: "自動呼び出しも含める"
    problem3: "Phase完了時 + セッション終了時"
    problem4: "全 subtask に適用"
    critical_addition: "3種類のレビュアー全てが4QV+レビューを実施する仕組み"
  reviewers:
    - reviewer: playbook レビュー（事前検証）
    - critic: phase/subtask 完了評価（事後検証）
    - coderabbit/user: コードレビュー（外部検証）
```

---

## goal

```yaml
summary: アーキテクチャ総合テストで発見した3つの問題を修正し、全レビュアーが4QV+レビューを実行する
done_when:
  - toolstack: B で playbook 作成時、コーディングタスクに executor: worker が割り当てられ、実行時に codex-delegate SubAgent が自動呼び出しされる
  - run_in_background=true で起動したタスクが Phase 完了時・セッション終了時に自動クリーンアップされる
  - 3種類のレビュアー（reviewer, critic, user/coderabbit）全てが4QV+検証を実行する仕組みが存在する
```

---

## phases

### p1: 問題分析と設計

**goal**: 3つの問題の根本原因を特定し、修正設計を確定する

#### subtasks

- [ ] **p1.1**: 問題2（オーケストレーション不在）の根本原因が docs/design/problem2-analysis.md に記録されている
  - executor: claudecode
  - validations:
    - technical: "test -f docs/design/problem2-analysis.md で存在確認"
    - consistency: "executor-guard.sh の現状動作と分析結果が一致"
    - completeness: "根本原因、影響範囲、修正方針が全て含まれている"

- [ ] **p1.2**: 問題3（バックグラウンドタスク残存）の根本原因が docs/design/problem3-analysis.md に記録されている
  - executor: claudecode
  - validations:
    - technical: "test -f docs/design/problem3-analysis.md で存在確認"
    - consistency: "session.sh、SubagentStop Hook の現状と分析結果が一致"
    - completeness: "根本原因、影響範囲、修正方針が全て含まれている"

- [ ] **p1.3**: 問題4（検証形骸化）の根本原因が docs/design/problem4-analysis.md に記録されている
  - executor: claudecode
  - validations:
    - technical: "test -f docs/design/problem4-analysis.md で存在確認"
    - consistency: "reviewer.md、critic.md の現状と分析結果が一致"
    - completeness: "3種類のレビュアーの4QV+検証不備が全て列挙されている"

**status**: pending
**max_iterations**: 5

---

### p2: 問題2修正 - オーケストレーション自動化

**goal**: executor: codex 検出時に codex-delegate SubAgent を自動呼び出しする

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: executor-guard.sh が codex 検出時に SubAgent 自動呼び出しコードを含む
  - executor: worker
  - validations:
    - technical: "grep -q 'Task.*codex-delegate' .claude/skills/playbook-gate/guards/executor-guard.sh で確認"
    - consistency: "docs/design/problem2-analysis.md の修正方針と実装が一致"
    - completeness: "ブロック→自動呼び出し への変更が完了"

- [ ] **p2.2**: pm.md がタスク分類パターンに基づいて executor を自動割り当てする記述を含む
  - executor: claudecode
  - validations:
    - technical: "grep -q 'タスク分類パターン' .claude/agents/pm.md で確認"
    - consistency: "M085 タスク分類マトリクスと記述が一致"
    - completeness: "coding_task, review_task, human_task, default の全パターンが記載"

- [ ] **p2.3**: toolstack: B で playbook を作成した際、コーディングタスクに executor: worker が割り当てられている
  - executor: claudecode
  - validations:
    - technical: "テスト playbook を作成し、executor: worker が含まれることを確認"
    - consistency: "toolstack と executor の対応が docs/ai-orchestration.md と一致"
    - completeness: "役割名（worker）が使用され、codex に解決される"

**status**: pending
**max_iterations**: 5

---

### p3: 問題3修正 - バックグラウンドタスク管理

**goal**: バックグラウンドタスクを追跡し、Phase完了時・セッション終了時に自動クリーンアップする

**depends_on**: [p1]

#### subtasks

- [ ] **p3.1**: .claude/session-state/background-tasks.json が作成され、バックグラウンドタスクを追跡する仕組みが存在する
  - executor: claudecode
  - validations:
    - technical: "test -f .claude/session-state/background-tasks.json（初期状態）で構造確認"
    - consistency: "session-manager Skill と連携する設計になっている"
    - completeness: "PID、開始時刻、タスク名を追跡する構造"

- [ ] **p3.2**: session.sh がセッション終了時にバックグラウンドタスクをクリーンアップするロジックを含む
  - executor: worker
  - validations:
    - technical: "grep -q 'background-tasks' .claude/hooks/session.sh で確認"
    - consistency: "docs/design/problem3-analysis.md の修正方針と実装が一致"
    - completeness: "SessionEnd イベントでクリーンアップが発火"

- [ ] **p3.3**: Phase 完了時にバックグラウンドタスクをクリーンアップする仕組みが archive-playbook.sh に含まれている
  - executor: worker
  - validations:
    - technical: "grep -q 'background.*cleanup' .claude/skills/playbook-gate/workflow/archive-playbook.sh で確認"
    - consistency: "Phase 完了の自動処理フローに統合されている"
    - completeness: "Phase 完了時とセッション終了時の両方でクリーンアップ"

**status**: pending
**max_iterations**: 5

---

### p4: 問題4修正 - 検証実質化（3種類のレビュアー）

**goal**: 3種類のレビュアー（reviewer, critic, coderabbit/user）全てが4QV+レビューを実行する

**depends_on**: [p1]

#### subtasks

- [ ] **p4.1**: reviewer.md に 4QV+ レビュー実行ステップが明記されている
  - executor: claudecode
  - validations:
    - technical: "grep -q '4QV' .claude/agents/reviewer.md で確認"
    - consistency: "docs/ARCHITECTURE.md の 4QV+ 導火線モデルと整合"
    - completeness: "形式検証、シミュレーション、批判的検討の3段階が含まれる"

- [ ] **p4.2**: critic.md に 4QV+ 検証実行ステップが明記されている
  - executor: claudecode
  - validations:
    - technical: "grep -q '4QV' .claude/agents/critic.md で確認"
    - consistency: "done-criteria-validation.md の5項目チェックと整合"
    - completeness: "証拠ベース判定、批判的思考、Skills 連携が含まれる"

- [ ] **p4.3**: subtask 単位で reviewer SubAgent が発動する仕組みが subtask-guard.sh に含まれている
  - executor: worker
  - validations:
    - technical: "grep -q 'reviewer' .claude/skills/reward-guard/guards/subtask-guard.sh で確認"
    - consistency: "docs/design/problem4-analysis.md の修正方針と一致"
    - completeness: "全 subtask で reviewer 発動（review: required マーク不要）"

- [ ] **p4.4**: validation_types（automated/manual/hybrid）の分類が plan/template/playbook-format.md に追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -q 'validation_types' plan/template/playbook-format.md で確認"
    - consistency: "manual 項目がある場合は user 確認が強制される設計"
    - completeness: "automated, manual, hybrid の3分類が定義されている"

- [ ] **p4.5**: manual 検証項目がある場合に user 確認を強制する仕組みが critic.md に含まれている
  - executor: claudecode
  - validations:
    - technical: "grep -q 'manual.*user' .claude/agents/critic.md で確認"
    - consistency: "validation_types: manual の場合に DEFERRED ではなく user 確認強制"
    - completeness: "自動検証不可の項目は user 確認なしで PASS にできない"

**status**: pending
**max_iterations**: 5

---

### p5: 統合テスト

**goal**: 3つの問題全てが解決されていることを統合テストで確認する

**depends_on**: [p2, p3, p4]

#### subtasks

- [ ] **p5.1**: 問題2のテスト - toolstack: B で executor: codex のタスクを作成し、codex-delegate が自動呼び出しされることを確認
  - executor: claudecode
  - validations:
    - technical: "テスト playbook を作成し、executor: codex の subtask が codex-delegate 呼び出しを含むことを確認"
    - consistency: "executor-guard.sh の出力が codex-delegate 呼び出し案内を含む"
    - completeness: "ブロックではなく自動呼び出しが発生する"

- [ ] **p5.2**: 問題3のテスト - run_in_background=true で起動したタスクがセッション終了時にクリーンアップされることを確認
  - executor: claudecode
  - validations:
    - technical: "session.sh の SessionEnd ハンドラが background-tasks.json を参照してクリーンアップすることを確認"
    - consistency: "Phase 完了時のクリーンアップも同様に動作"
    - completeness: "残存プロセスがない状態で終了"

- [ ] **p5.3**: 問題4のテスト - 3種類のレビュアー全てが 4QV+ を実行する流れを確認
  - executor: claudecode
  - validations:
    - technical: "reviewer, critic, coderabbit/user のドキュメントに 4QV+ 参照が含まれる"
    - consistency: "全レビュアーが同一の検証フレームワークを使用"
    - completeness: "形骸化の余地がない構造的強制が存在"

**status**: pending
**max_iterations**: 5

---

### p_self_update: フレームワーク自己更新

**goal**: 今回の修正をフレームワーク自体に反映し、再発を防止する

**depends_on**: [p5]

#### subtasks

- [ ] **p_self_update.1**: docs/ARCHITECTURE.md に「レビュアー4QV+必須化」が追記されている
  - executor: claudecode
  - validations:
    - technical: "grep -q 'レビュアー.*4QV' docs/ARCHITECTURE.md で確認"
    - consistency: "Section 7 SubAgent 呼び出しと整合"
    - completeness: "reviewer, critic, coderabbit/user 全てについて記載"

- [ ] **p_self_update.2**: docs/design/ の分析ドキュメントが最終成果物に統合され、中間ファイルが削除されている
  - executor: claudecode
  - validations:
    - technical: "ls docs/design/*.md でファイルが存在しないことを確認"
    - consistency: "内容は ARCHITECTURE.md または該当する SubAgent 定義に統合済み"
    - completeness: "中間成果物が残存していない"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p_self_update]

#### subtasks

- [ ] **p_final.1**: done_when 項目1 - toolstack: B で codex-delegate 自動呼び出しが実際に動作する
  - executor: claudecode
  - validations:
    - technical: "executor-guard.sh を実行し、codex-delegate 呼び出しコードが含まれることを確認"
    - consistency: "playbook の executor: worker が codex に解決され、自動呼び出しが発火"
    - completeness: "ブロックではなく呼び出しが行われる"

- [ ] **p_final.2**: done_when 項目2 - バックグラウンドタスクが自動クリーンアップされる
  - executor: claudecode
  - validations:
    - technical: "session.sh と archive-playbook.sh にクリーンアップロジックが存在することを確認"
    - consistency: "background-tasks.json の追跡と連携している"
    - completeness: "Phase 完了時とセッション終了時の両方で動作"

- [ ] **p_final.3**: done_when 項目3 - 3種類のレビュアー全てが4QV+を実行する
  - executor: claudecode
  - validations:
    - technical: "reviewer.md, critic.md に 4QV+ 参照が含まれることを確認"
    - consistency: "subtask-guard.sh が全 subtask で reviewer 発動を強制"
    - completeness: "manual 検証は user 確認を強制、形骸化の余地なし"

**status**: pending
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
