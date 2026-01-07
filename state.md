# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/design-validation/project.json
current_milestone: m1
status: active
```

---

## playbook

```yaml
active: play/projects/design-validation/playbooks/gap-analysis/plan.json
parent_project: play/projects/design-validation/project.json
current_phase: p1
branch: feat/design-validation
last_archived: play/archive/standalone/fix-playbook-guard-macos
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: m1
phase: p1
done_criteria:
  - docs/ARCHITECTURE.md と実装の乖離が全てリスト化されている
  - docs/core-feature-reclassification.md と実装の乖離が全てリスト化されている
  - 乖離項目に優先度（high/medium/low）が付与されている
  - play/projects/design-validation/reports/gap-report.md が存在する
status: active

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
