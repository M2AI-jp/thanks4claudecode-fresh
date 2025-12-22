# playbook-merge-fix.md

## meta

```yaml
id: playbook-merge-fix
name: "Merge conflict resolution"
branch: main
created: 2025-12-22
status: active
```

## phases

### p0: Resolve conflicts and complete merge

```yaml
id: p0
name: "Resolve merge conflicts"
executor: claudecode
status: in_progress
done_criteria:
  - All conflicts resolved
  - Merge committed
  - Pushed to GitHub
```
