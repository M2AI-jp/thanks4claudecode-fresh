# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: null
current_milestone: m1
status: idle
```

---

## playbook

```yaml
active: play/standalone/v2-design-docs/plan.json
parent_project: null
current_phase: p1
branch: feat/new-repo-docs-sync
last_archived: play/archive/projects/new-repo-docs-sync/pb-001
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - new-repo/v2-design/ ディレクトリが存在する
  - 6つの設計ドキュメントが作成されている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-22 13:00:47
last_end: 2026-01-21 22:51:23
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
