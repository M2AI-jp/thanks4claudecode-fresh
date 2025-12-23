# Prompt Changelog

> Change log for CLAUDE.md (Frozen Constitution)
> All changes to CLAUDE.md MUST be recorded here.

---

## [Unreleased]

(No unreleased changes)

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
