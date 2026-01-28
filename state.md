# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: null
current_milestone: m6
status: idle
```

---

## playbook

```yaml
active: null
parent_project: null
current_phase: null
branch: null
last_archived: play/archive/repository-verification
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: null
done_criteria: []
status: idle
```

---

## session

```yaml
last_start: 2026-01-29 01:21:36
last_end: 2026-01-28 23:04:17
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
