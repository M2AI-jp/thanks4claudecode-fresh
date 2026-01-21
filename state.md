# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/new-repo-docs-sync/project.json
current_milestone: m1
status: in_progress
```

---

## playbook

```yaml
active: play/projects/new-repo-docs-sync/playbooks/pb-001/plan.json
parent_project: new-repo-docs-sync
current_phase: p1
branch: feat/new-repo-docs-sync
last_archived: play/standalone/project-story
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: m1
phase: p1
done_criteria:
  - new-repo/BUILD-FROM-SCRATCH.md がルートの修正を反映
  - new-repo/EXAMPLE-FRAMEWORK-BUILD.md が存在
  - new-repo/EXAMPLE-CHATGPT-CLONE.md に Phase -1 前提条件が追加
  - PROJECT-STORY.md に概念整理を飛ばした失敗セクションが存在
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-21 22:40:37
last_end: 2026-01-21 20:07:53
last_clear: 2026-01-20
```

---

## config

```yaml
security: admin
toolstack: C
roles:
  orchestrator: claudecode
  worker: codex
  reviewer: coderabbit
  human: user
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/core-feature-reclassification.md | Hook Unit SSOT |
