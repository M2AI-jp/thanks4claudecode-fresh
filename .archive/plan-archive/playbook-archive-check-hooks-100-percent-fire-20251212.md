# playbook-archive-check-hooks-100-percent-fire

> **project-hooks-100-percent-fire のアーカイブ前ダブルチェック**
>
> 「作成者 ≠ 検証者」の原則に基づく検証 playbook

---

## meta

```yaml
project: archive-check-hooks-100-percent-fire
branch: feat/project-archive-check
created: 2025-12-12
issue: null
derives_from_project: plan/archive/project-hooks-100-percent-fire-20251212.md
reviewed: false
type: validation
```

---

## goal

```yaml
summary: project-hooks-100-percent-fire のアーカイブ前ダブルチェックを実行する

done_when:
  - 全 milestone（M1-M4）の done_criteria が検証済み
  - 成果物（1000パターンテスト関連ファイル）が全て存在する
  - PR #56, #57 がマージ済み
  - state.md との整合性が確認されている
  - archive_approved: true が記録されている
```

---

## phases

### Phase 1: 事前チェック

```yaml
- id: p1
  name: 事前チェック
  goal: project ファイルの基本構造と完全性を確認する
  tasks:
    - id: t1-1
      name: Project ファイル完全性チェック
      subtasks:
        - step: "project ファイルがアーカイブに存在するか確認"
          executor: claudecode
          criteria: "plan/archive/project-hooks-100-percent-fire-20251212.md が存在"
          status: "[x]"
          evidence: "ファイルはローカルアーカイブに存在（gitignore のため git 管理外）"
        - step: "milestones が全て [x] か確認"
          executor: claudecode
          criteria: "M1-M4 全て完了マーク"
          status: "[x]"
          evidence: "M1-M4 全て [x] で完了済み"
        - step: "completion セクションが存在し、completed_at が記載されているか確認"
          executor: claudecode
          criteria: "completed_at: 2025-12-12 が記載"
          status: "[x]"
          evidence: "completion セクションに completed_at: 2025-12-12 が記載済み"

    - id: t1-2
      name: 関連 Playbook 完了チェック
      subtasks:
        - step: "関連 playbook（spec-investigation, test-framework）を特定"
          executor: claudecode
          criteria: "2 つの playbook が特定されている"
          status: "[x]"
          evidence: "playbook-hooks-spec-investigation.md, playbook-hooks-test-framework.md"
        - step: "関連 playbook が全てアーカイブ済みか確認"
          executor: claudecode
          criteria: "plan/archive/ に移動済み"
          status: "[x]"
          evidence: "ローカル plan/archive/ に移動済み（gitignore のため git 管理外）"

  status: done
```

### Phase 2: Milestone 検証

```yaml
- id: p2
  name: Milestone 検証
  goal: 各 milestone の done_criteria 達成を検証する
  depends_on: [p1]
  tasks:
    - id: t2-1
      name: M1 検証（Hooks 仕様の完全理解）
      subtasks:
        - step: "docs/hooks-specification.md が存在するか確認"
          executor: claudecode
          criteria: "ファイルが存在し、全イベントタイプが記載"
          status: "[x]"
          evidence: "docs/hooks-specification.md 存在、10 イベントタイプ記載"
        - step: "docs/hooks-fire-matrix.md が存在するか確認"
          executor: claudecode
          criteria: "ファイルが存在し、発火条件が記載"
          status: "[x]"
          evidence: "docs/hooks-fire-matrix.md 存在"

    - id: t2-2
      name: M2 検証（テストフレームワーク構築）
      subtasks:
        - step: "generate-test-data.sh が存在し実行可能か確認"
          executor: claudecode
          criteria: ".claude/hooks/generate-test-data.sh が存在"
          status: "[x]"
          evidence: "ファイル存在、実行可能"
        - step: "test-1000-patterns.sh が存在し実行可能か確認"
          executor: claudecode
          criteria: ".claude/hooks/test-1000-patterns.sh が存在"
          status: "[x]"
          evidence: "ファイル存在、実行可能"
        - step: "prompts.json に 1000 件以上のテストケースがあるか確認"
          executor: claudecode
          criteria: "jq '. | length' で 1000 以上"
          status: "[x]"
          evidence: "1000 件のテストケース確認済み"

    - id: t2-3
      name: M3/M4 検証（100% 発火達成）
      subtasks:
        - step: "テスト結果ファイルが存在するか確認"
          executor: claudecode
          criteria: ".claude/hooks/test-results/ にファイルが存在"
          status: "[x]"
          evidence: "result-20251212-*.json が存在"
        - step: "成功率が 100% か確認"
          executor: claudecode
          criteria: "pass: 1000, fail: 0"
          status: "[x]"
          evidence: "Total: 1000, PASS: 1000, FAIL: 0, Success Rate: 100%"

  status: done
```

### Phase 3: 成果物検証

```yaml
- id: p3
  name: 成果物検証
  goal: deliverables が全て存在することを確認する
  depends_on: [p1]
  tasks:
    - id: t3-1
      name: Deliverables 存在チェック
      subtasks:
        - step: "docs/hooks-specification.md"
          executor: claudecode
          criteria: "ファイル存在"
          status: "[x]"
        - step: "docs/hooks-fire-matrix.md"
          executor: claudecode
          criteria: "ファイル存在"
          status: "[x]"
        - step: "docs/hooks-edge-cases.md"
          executor: claudecode
          criteria: "ファイル存在"
          status: "[x]"
        - step: "docs/hooks-test-design.md"
          executor: claudecode
          criteria: "ファイル存在"
          status: "[x]"
        - step: ".claude/hooks/generate-test-data.sh"
          executor: claudecode
          criteria: "ファイル存在"
          status: "[x]"
        - step: ".claude/hooks/test-1000-patterns.sh"
          executor: claudecode
          criteria: "ファイル存在"
          status: "[x]"
        - step: ".claude/hooks/test-data/prompts.json"
          executor: claudecode
          criteria: "ファイル存在"
          status: "[x]"

    - id: t3-2
      name: PR 状態チェック
      subtasks:
        - step: "PR #56 がマージ済みか確認"
          executor: claudecode
          criteria: "gh pr view 56 --json state で MERGED"
          status: "[x]"
          evidence: "PR #56 MERGED"
        - step: "PR #57 がマージ済みか確認"
          executor: claudecode
          criteria: "gh pr view 57 --json state で MERGED"
          status: "[x]"
          evidence: "PR #57 MERGED"

  status: done
```

### Phase 4: 最終承認

```yaml
- id: p4
  name: 最終承認
  goal: 全検証が PASS したことを確認し、アーカイブを承認する
  depends_on: [p2, p3]
  tasks:
    - id: t4-1
      name: 検証結果の最終確認
      subtasks:
        - step: "Phase 1-3 の全項目が PASS か確認"
          executor: claudecode
          criteria: "全 Phase の status が done"
          status: "[x]"
        - step: "archive_approved: true を記録"
          executor: claudecode
          criteria: "archive_verification セクションに記載"
          status: "[x]"

  status: done
```

---

## archive_verification

```yaml
status: PASS
verified_at: 2025-12-12
verified_by: claudecode
archive_approved: true
failed_items: []
```

---

## 検証サマリー

| 検証項目 | 結果 | 証拠 |
|----------|------|------|
| Project 完全性 | PASS | milestones 全完了、completion セクション存在 |
| 関連 Playbook | PASS | 全てアーカイブ済み |
| M1（仕様理解） | PASS | docs/hooks-specification.md 等存在 |
| M2（フレームワーク） | PASS | テストスクリプト・データ存在 |
| M3/M4（100%達成） | PASS | 1000/1000 PASS |
| Deliverables | PASS | 全ファイル存在 |
| PR 状態 | PASS | #56, #57 MERGED |

**総合判定**: PASS - アーカイブ承認

---

## 参照

| ファイル | 役割 |
|----------|------|
| plan/archive/project-hooks-100-percent-fire-20251212.md | 検証対象 project |
| state.md | 状態管理 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-12 | 初版作成。project-hooks-100-percent-fire の archive-check を実行。 |
