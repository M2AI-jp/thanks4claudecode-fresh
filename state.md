# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/repository-complete-verification/project.json
current_milestone: m5
status: active
```

---

## playbook

```yaml
active: play/projects/repository-complete-verification/playbooks/pb-m5-file-integrity/plan.json
parent_project: play/projects/repository-complete-verification/project.json
current_phase: p1
branch: feat/m5-file-integrity-verification
last_archived: play/archive/projects/repository-complete-verification/pb-m4-skills
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: m5
phase: p1
done_criteria:
  - repository-map.yaml の total_files が実際のファイル数と一致する
status: active
```

---

## session

```yaml
last_start: 2026-01-28 20:47:43
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
