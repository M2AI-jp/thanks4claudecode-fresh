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
active: play/standalone/architecture-sync/plan.json
parent_project: null
current_phase: p1
branch: docs/architecture-sync-crit
last_archived: play/archive/standalone/repository-cleanup
review_pending: false
```

---

## goal

```yaml
self_complete: true
milestone: null
phase: p1
done_criteria:
  - docs/ARCHITECTURE.md のセクション 8 に crit/ セクションが存在する
  - crit/ セクションに handlers/verify.sh が記載されている
  - crit/ セクションが understanding-check/ の後、## 8.5 の前に配置されている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-29 00:08:55
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
