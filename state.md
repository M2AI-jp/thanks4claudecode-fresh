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
active: play/playbook-completion/plan.json
parent_project: design-validation
current_phase: p1
branch: feat/playbook-completion
last_archived: play/archive/projects/design-validation/playbooks/post-loop-fix
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: m2
phase: p1
done_criteria:
  - 設計図と実装の Critical Gap が全て解消されている
  - project 生成時に reviewer 検証が必須になっている
  - playbook 運用の検証サイクルが 1 回以上完走している
status: active

```

---

## session

```yaml
last_start: 2026-01-07 20:25:50
last_end: 2026-01-07 19:24:36
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
