# playbook-emergency-hook-fix.md

## meta
```yaml
id: emergency-hook-fix
title: Emergency Hook Fix
created: 2025-12-24
branch: fix/main-branch-hook
derives_from: null
```

## p1
```yaml
name: Fix check-main-branch.sh
status: in_progress
executor: claudecode
done_criteria:
  - git push と git merge が main ブランチで許可される
```
