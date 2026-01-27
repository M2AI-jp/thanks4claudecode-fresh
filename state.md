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
active: play/standalone/repository-completion/plan.json
parent_project: null
current_phase: p1
branch: feat/repository-completion
last_archived: play/archive/auto-hard-block
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - "docs/completion-criteria.md が存在し、完成状態の定義が記載されている"
  - "全 Skill（13種）が SKILL.md を持ち、配下モジュールが整合している"
  - "全 SubAgent（7種）が .claude/agents/ と skills/*/agents/ で整合している"
  - "報酬詐欺耐性テストスクリプトが exit 0 で終了する"
  - "Bash 保護の誤検出が 0 件である"
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 06:50:59
last_end: 2026-01-28 02:47:07
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
