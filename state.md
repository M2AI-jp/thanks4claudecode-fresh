# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/repository-complete-verification/project.json
current_milestone: m1
status: in_progress
```

---

## playbook

```yaml
active: play/projects/repository-complete-verification/playbooks/pb-m1-event-units/plan.json
parent_project: repository-complete-verification
current_phase: p1
branch: feat/repository-complete-verification
last_archived: play/archive/health-dashboard-cli
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: m1
phase: p1
done_criteria:
  - "DW1: 10 Event Unit chain.sh が存在し実行可能"
  - "DW2: Adversarial Test - Codex gaming_succeeded: false"
  - "DW3: 全 chain.sh が telemetry を呼び出している"
  - "DW4: 検証レポートに 10 PASS が記録されている"
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 19:49:03
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
