# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: null
current_milestone: m2
status: idle
```

---

## playbook

```yaml
active: play/fix-archive-resume/plan.json
parent_project: null
current_phase: p3
branch: fix/archive-resume
last_archived: play/archive/standalone/fix-projects-cleanup
review_pending: false

```

---

## goal

```yaml
self_complete: true
milestone: null
phase: p2
done_criteria:
  - "--resume オプションが動作する"
  - "チェックポイントから状態が復元される"
  - "失敗ステップから再開される"
status: active

```

---

## session

```yaml
last_start: 2026-01-07 23:45:53
last_end: 2026-01-07 23:44:54
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
