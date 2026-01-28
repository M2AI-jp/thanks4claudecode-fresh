# Project Feature Specification

> **project 機能の「完成」を厳密に定義する仕様書**

---

## Overview

| 項目 | 内容 |
|------|------|
| 機能名 | Project 階層管理（M090） |
| 定義場所 | .claude/skills/golden-path/agents/pm.md |
| 状態ファイル | state.md の project セクション |
| テンプレート | play/projects/template/project.json |

---

## must_have: 必須機能

### 1. Project 作成

```yaml
must_have:
  - id: MH-001
    name: "project.json 作成"
    description: "テンプレートに準拠した project.json が作成される"
    verification:
      command: "test -f play/projects/<id>/project.json"
      expected: "exit 0"

  - id: MH-002
    name: "milestones 定義"
    description: "project.json に milestones 配列が定義されている"
    verification:
      command: "jq -e '.milestones | length' play/projects/<id>/project.json"
      expected: ">= 1"

  - id: MH-003
    name: "playbooks ディレクトリ構造"
    description: "playbooks が play/projects/<id>/playbooks/<pb-id>/ に配置される"
    verification:
      command: "ls -d play/projects/<id>/playbooks/*/plan.json 2>/dev/null | wc -l"
      expected: ">= 1"

  - id: MH-004
    name: "reviewer による検証"
    description: "project.json が reviewed: true である"
    verification:
      command: "jq -r '.meta.reviewed' play/projects/<id>/project.json"
      expected: "true"
```

### 2. state.md 連携

```yaml
must_have:
  - id: MH-005
    name: "project.active 更新"
    description: "state.md の project.active が project.json のパスを指す"
    verification:
      command: "grep -A1 'project:' state.md | grep 'active:'"
      expected: "play/projects/<id>/project.json"

  - id: MH-006
    name: "playbook.parent_project 設定"
    description: "playbook 作成時に parent_project が設定される"
    verification:
      command: "grep 'parent_project:' state.md"
      expected: "<project-id>"

  - id: MH-007
    name: "current_milestone 追跡"
    description: "state.md の current_milestone が更新される"
    verification:
      command: "grep 'current_milestone:' state.md"
      expected: "m1 or m2 etc."
```

### 3. Playbook 階層

```yaml
must_have:
  - id: MH-008
    name: "playbook パス整合性"
    description: "project.json の playbooks[].path と実際のパスが一致"
    verification:
      command: "jq -r '.milestones[].playbooks[].path' project.json | xargs -I{} test -f {}"
      expected: "exit 0"

  - id: MH-009
    name: "playbook 完了時の project 更新"
    description: "playbook 完了時に project.json の status が更新される"
    verification:
      command: "jq -r '.milestones[].playbooks[] | select(.status == \"completed\") | .id' project.json"
      expected: "completed playbook IDs"
```

### 4. Project 完了

```yaml
must_have:
  - id: MH-010
    name: "明示的クローズ"
    description: "ユーザー要求で project が完了状態になる"
    verification:
      command: "jq -r '.meta.status' project.json"
      expected: "completed"

  - id: MH-011
    name: "アーカイブ"
    description: "完了した project が play/archive/projects/<id>/ に移動される"
    verification:
      command: "test -d play/archive/projects/<id>"
      expected: "exit 0"

  - id: MH-012
    name: "state.md リセット"
    description: "project 完了後 state.md の project.active が null になる"
    verification:
      command: "grep -A1 'project:' state.md | grep 'active: null'"
      expected: "exit 0"
```

---

## done_when: 完了条件

```yaml
done_when:
  - criterion: "全 must_have が検証済み（12/12）"
    command: "grep -c 'PASS' tmp/project-spec-validation.md"
    expected: "12"

  - criterion: "既存 project（new-repo-docs-sync）が仕様に準拠"
    command: "grep 'new-repo-docs-sync.*PASS' tmp/project-spec-validation.md | wc -l"
    expected: ">= 1"

  - criterion: "pm.md と template の整合性が確認済み"
    command: "grep 'pm.md.*template.*PASS' tmp/project-spec-validation.md | wc -l"
    expected: ">= 1"
```

---

## validation: 検証方法

### Phase 2 で実行する検証

```yaml
validation_matrix:
  - target: "pm.md の project セクション"
    check: "MH-001 〜 MH-012 の記述が存在するか"
    result_file: "tmp/project-spec-validation.md"

  - target: "state.md の project セクション"
    check: "必要なフィールドが全て存在するか"
    result_file: "tmp/project-spec-validation.md"

  - target: "play/projects/template/project.json"
    check: "テンプレート構造が pm.md の定義と一致するか"
    result_file: "tmp/project-spec-validation.md"
```

### Phase 3 で実行する検証

```yaml
implementation_check:
  - target: "play/projects/new-repo-docs-sync/"
    check:
      - "project.json が存在する"
      - "playbooks ディレクトリが存在する"
      - "playbooks/<pb-id>/plan.json が存在する"
      - "project.json の path と実ファイルが一致する"
    result_file: "tmp/project-spec-validation.md"
```

---

## 現時点での発見（予備調査）

### Issue 1: playbooks ディレクトリ不在

```yaml
location: play/projects/new-repo-docs-sync/
expected: playbooks/pb-001/plan.json
actual: playbooks ディレクトリが存在しない
severity: critical
```

### Issue 2: アーカイブ構造の不整合

```yaml
location: play/archive/projects/new-repo-docs-sync/
expected: playbooks/pb-001/plan.json
actual: pb-001/plan.json (playbooks/ なしで直置き)
note: テンプレートと実装でパス構造が異なる
severity: high
```

### Issue 3: 同名 project の重複

```yaml
issue: new-repo-docs-sync が active と archive 両方に存在
active: play/projects/new-repo-docs-sync/project.json
archive: play/archive/projects/new-repo-docs-sync/
status: 不整合（アクティブなのにアーカイブにも存在）
severity: high
```

---

## issues: 発見された問題

### 統計サマリー

| Phase | PASS | FAIL | Total |
|-------|------|------|-------|
| Phase 2 (仕様検証) | 6 | 1 | 7 |
| Phase 3 (実装検証) | 1 | 4 | 5 |
| **Total** | **7** | **5** | **12** |

### 問題一覧

```yaml
issues:
  - id: C-007
    name: "state.md status 値の不整合"
    location: state.md
    expected: "[null, in_progress, completed]"
    actual: "idle"
    severity: medium
    impact: "pm.md の定義と state.md の実装が不一致"

  - id: P3-001
    name: "Active Project に playbooks がない"
    location: play/projects/new-repo-docs-sync/
    expected: "playbooks/pb-001/plan.json が存在"
    actual: "playbooks ディレクトリ自体が不在"
    severity: critical
    impact: "project.json が参照するファイルが存在せず、機能として破綻"

  - id: P3-002
    name: "Archive の playbook 配置が不正"
    location: play/archive/projects/new-repo-docs-sync/
    expected: "playbooks/pb-001/plan.json"
    actual: "pb-001/plan.json (playbooks/ なしで直置き)"
    severity: high
    impact: "仕様とアーカイブ構造が不一致"

  - id: P3-003
    name: "同名 Project の重複存在"
    location: play/projects/ と play/archive/projects/
    expected: "どちらか一方にのみ存在"
    actual: "両方に存在（active: playbooks なし、archive: pb-001 あり）"
    severity: high
    impact: "データ整合性が破壊されている"
```

### 根本原因分析

```yaml
root_cause:
  summary: "project 機能は設計されたが、実装が完了していない"
  evidence:
    - "pm.md に M090 として定義されているが、実際の運用で使用された形跡がない"
    - "new-repo-docs-sync という project が作成されたが、playbooks ディレクトリが作成されていない"
    - "アーカイブ処理で playbooks/ 階層が無視されている"
    - "standalone playbook は正常動作している（対照群として確認済み）"
  conclusion: "project 機能の実装は未完了であり、一度も正常動作していない"
```

---

## verdict: 廃止判定

```yaml
verdict: deprecate
rationale: |
  Phase 2-3 の検証結果に基づき、project 機能の廃止を判定する。

  判定理由:
  1. 検証結果が 7 PASS / 5 FAIL（58% 成功率）で基準未達
  2. Critical 1件 + High 2件の重大な問題が存在
  3. 既存の project (new-repo-docs-sync) は一度も正常動作していない
  4. standalone playbook は正常に動作しており、十分な機能を提供
  5. 2層管理（project + standalone）は複雑性を増すだけでメリットがない

  廃止後のアクション:
  1. pm.md から M090（project 階層サポート）を削除
  2. state.md の project セクションを削除
  3. play/projects/ ディレクトリを削除（archive 含む）
  4. play/projects/template/project.json を削除
  5. standalone playbook を唯一のモードとして最適化

decision_date: 2026-01-28
decided_by: project-feature-validation playbook
```

---

## Update History

| Date | Change |
|------|--------|
| 2026-01-28 | Initial creation (p1.1) |
| 2026-01-28 | Phase 2-3 validation results added |
| 2026-01-28 | Phase 4: issues documented, verdict=deprecate |
