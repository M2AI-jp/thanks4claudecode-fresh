# Prompt Changelog

> Change log for CLAUDE.md (Frozen Constitution)
> All changes to CLAUDE.md MUST be recorded here.

---

## [Unreleased]

(No unreleased changes)

---

## [1.2.0] - 2025-12-23

### Removed
- Section 7: `project_state: plan/project.md` 参照を削除
- References テーブル: `plan/project.md` エントリを削除

### Rationale
project.md 機能が廃止されたため、存在しないファイルへの参照を削除。
playbook + state.md を核としたシンプルなオーケストレーションモデルへの移行完了。

### Verification
- `grep "project.md" CLAUDE.md` が 0 件であること

---

## [1.1.0] - 2025-12-18

### Added
- Section 11: Core Contract（golden_path, playbook_gate, reviewer_gate）
- Section 12: Admin Mode Contract（admin 権限の境界定義）

### Rationale
タスク依頼時の pm 呼び出し必須化、playbook=null での Edit/Write ブロック、
reviewer PASS 必須化により、構造的な品質保証を実現。

---

## [1.0.0] - 2025-12-18

### Added
- Initial frozen constitution for Claude (CLAUDE.md)
- 10 sections covering principles, constraints, quality bar, workflow
- Change Control section (Section 10)
- Version history tracking

### Changed
- Reduced from 648 lines to 215 lines
- Extracted all procedures to RUNBOOK.md
- Removed volatile content (specific milestones, tool details)

### Governance Added
- `governance/PROMPT_CHANGELOG.md` (this file)
- `scripts/lint_prompts.py` for automated validation
- `.github/workflows/prompt-lint.yml` for CI enforcement
- `eval/` directory for regression tests

### Rationale
The previous CLAUDE.md was too long (648 lines), contained volatile information that required frequent updates, and had no change control mechanism. This refactor establishes CLAUDE.md as a stable "constitution" that changes rarely, with procedures moved to RUNBOOK.md which can evolve freely.

---

## Template for Future Changes

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New section or rule

### Changed
- Modification to existing content

### Removed
- Deleted content

### Rationale
Why this change was necessary.

### Risk Assessment
Potential impacts of this change.

### Verification
How to verify this change works correctly.
```
