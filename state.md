# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/design-validation/project.json
current_milestone: m2
status: in_progress
```

---

## playbook

```yaml
active: play/projects/design-validation/playbooks/audit-verification/plan.json
parent_project: design-validation
current_phase: p1
branch: feat/audit-verification
last_archived: play/archive/projects/play/projects/design-validation/project.json/playbooks/gap-analysis
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: m2
phase: p1
done_criteria:
  - "reports/audit-mechanisms.md にチェック・レビュー機能の完全なリストが存在する"
  - "reports/project-audit-gap.md に project 生成時のチェックフロー Gap が記載されている"
  - "project.json に meta.reviewed フィールドが追加されている"
  - "pm.md に project 用 reviewer チェックが実装されている"
status: in_progress

```

---

## session

```yaml
last_start: 2026-01-07 16:41:20
last_end: 2026-01-07 13:23:10
last_clear: 2025-12-24 03:20:00
```

---

## config

```yaml
security: admin
toolstack: C  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: coderabbit      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/core-feature-reclassification.md | Hook Unit SSOT |
