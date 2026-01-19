# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: null
current_milestone: null
status: idle
```

---

## playbook

```yaml
active: play/standalone/m1-post-maintenance/plan.json
parent_project: null
current_phase: p1
branch: fix/m1-post-maintenance
last_archived: play/archive/codex-usage-improvement
review_pending: false
```

---

## goal

```yaml
self_complete: true
milestone: null
phase: p1
done_criteria:
  - state.md の playbook.branch が main に更新されている
  - repository-map.yaml のドリフトが解消されている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-20 05:45:49
last_end: 2026-01-20 05:45:48
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
