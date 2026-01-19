# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/toolstack-c-enforcement/project.json
current_milestone: m1
status: active
```

---

## playbook

```yaml
active: play/projects/toolstack-c-enforcement/playbooks/m1-analysis/plan.json
parent_project: toolstack-c-enforcement
current_phase: p1
branch: project/toolstack-c-enforcement
last_archived: play/archive/projects/context-cleanup/m3-cleanup
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: m1
phase: p1
done_criteria:
  - executor 使用統計レポート（tmp/executor-usage-report.md）が存在する
  - executor: reviewer と roles.reviewer: coderabbit の関係が分析されている
  - context-cleanup playbooks がアーカイブされていない原因が特定されている
  - 根本原因仮説が文書化されている
status: active

```

---

## session

```yaml
last_start: 2026-01-20 04:12:43
last_end: 2026-01-20 03:49:19
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
