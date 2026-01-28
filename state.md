# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/repository-complete-verification/project.json
current_milestone: m3
status: active
```

---

## playbook

```yaml
active: play/projects/repository-complete-verification/playbooks/pb-m3-subagents/plan.json
parent_project: repository-complete-verification
current_phase: p1
branch: feat/m3-subagent-verification
last_archived: play/archive/projects/repository-complete-verification/pb-m2-guards
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: m3
phase: p1
done_criteria:
  - "7 SubAgent ファイルが .claude/agents/ に存在する"
  - ".claude/agents/ と skills/*/agents/ の SubAgent ファイル数が一致する"
  - "各 SubAgent が必須セクション（Purpose, When to Use, Output）を含む"
  - "Adversarial invocation test が全て失敗している"
  - "docs/reports/m3-subagent-certification.json が生成されている"
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 20:17:24
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
