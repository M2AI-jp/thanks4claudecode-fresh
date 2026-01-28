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
active: play/standalone/hook-unit-completion/plan.json
parent_project: null
current_phase: p1
branch: fix/hook-chain-and-missing-components
last_archived: play/archive/standalone/repository-final-cleanup
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - "全 10 Event Unit に telemetry.sh が存在する"
  - "notification Unit が telemetry を実行する（no-op ではない）"
  - "session-start Unit に health/integrity チェーンが配線されている"
  - "testing.sh が git にコミットされている"
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 14:11:38
last_end: 2026-01-28 15:12:57
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
