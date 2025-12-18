# RUNBOOK.md

> **Procedures, tools, and examples for working in this repository.**
> This file CAN be updated without Change Control (unlike CLAUDE.md).

---

## Where to Put What

| Content Type | Location | Can Change? |
|--------------|----------|-------------|
| Immutable principles | CLAUDE.md | No (frozen) |
| Procedures, tools, examples | RUNBOOK.md (this file) | Yes |
| Current state | state.md | Yes (auto-updated) |
| Project goals | plan/project.md | Yes |
| Task details | plan/playbook-*.md | Yes |

---

## Session Start Checklist

When starting a new session:

1. **Read state.md** - Understand current focus and active task
2. **Check branch** - `git branch --show-current`
3. **Check status** - `git status -sb`
4. **Read active playbook** - If `playbook.active` is set in state.md

```bash
# Quick start commands
cat state.md
git status -sb
```

---

## Task Lifecycle

### 1. Starting a New Task

```yaml
steps:
  1. Create branch: git checkout -b {type}/{description}
  2. Update state.md focus if needed
  3. Create playbook (optional for small tasks)
  4. Begin work
```

### 2. During Task

```yaml
checkpoints:
  - Commit frequently (atomic commits)
  - Update state.md if focus changes
  - Mark subtasks as done: `- [ ]` → `- [x]`
```

### 3. Completing a Task

```yaml
steps:
  1. Self-verify against acceptance criteria
  2. Commit final changes
  3. Update state.md
  4. Create PR if on feature branch
```

---

## Commit Message Format

```
{type}({scope}): {summary}

{body - optional}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`

---

## Common Operations

### Edit Protected Files

Files in `.claude/protected-files.txt` require extra care:

```bash
# Check if file is protected
grep "filename" .claude/protected-files.txt

# If protected, document reason before editing
```

### Update State

```bash
# state.md fields to update:
# - focus.current: What you're working on
# - playbook.active: Current task file
# - session.last_start: Timestamp
```

### Archive Completed Work

```bash
# Move completed playbooks
mv plan/playbook-{name}.md plan/archive/
```

---

## Tool Reference

### Hooks (automatic checks)

| Hook | Trigger | Purpose |
|------|---------|---------|
| playbook-guard.sh | Edit/Write | Ensures playbook exists |
| check-main-branch.sh | Edit/Write | Prevents main branch edits |
| check-protected-edit.sh | Edit/Write | Protects sensitive files |

### SubAgents (specialized tasks)

| Agent | Use For |
|-------|---------|
| critic | Verify task completion |
| pm | Project/playbook management |
| reviewer | Code/design review |

### Skills (domain knowledge)

| Skill | Purpose |
|-------|---------|
| state | State file management |
| test-runner | Run tests |
| lint-checker | Code quality |

---

## Troubleshooting

### Hook Blocking Edit

```yaml
problem: "playbook 必須" error
solutions:
  1. Create a playbook first
  2. Set admin mode in state.md (security: admin)
  3. Use Bash commands instead of Edit tool
```

### Context Too Long

```yaml
problem: Context approaching limit
solutions:
  1. Run /clear to reset context
  2. Re-read state.md after reset
  3. Trust state files over chat history
```

### Stuck on Main Branch

```yaml
problem: Can't edit on main
solution:
  git checkout -b {type}/{description}
```

---

## Modifying CLAUDE.md

**CLAUDE.md is FROZEN.** To modify it:

1. Document rationale in `governance/PROMPT_CHANGELOG.md`
2. Update version number in CLAUDE.md header
3. Run lint: `python scripts/lint_prompts.py`
4. Get maintainer approval
5. Commit with clear message explaining change

---

## Adding New Procedures

To add new procedures to this RUNBOOK:

1. Identify the appropriate section
2. Follow the existing format (yaml, tables, code blocks)
3. Keep instructions concrete and executable
4. Commit with descriptive message

No approval required - this file is designed to evolve.

---

## Version

Last updated: 2025-12-18
