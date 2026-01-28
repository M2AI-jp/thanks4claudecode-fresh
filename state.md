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
active: play/standalone/reward-fraud-prevention-v2/plan.json
parent_project: null
current_phase: p1
branch: feat/reward-fraud-prevention-v2
last_archived: play/standalone/repo-integrity-v1
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - "critic.md に PROXY_VERIFICATION_BLOCKLIST が定義されている"
  - "done-criteria-validation.md に IMMUTABLE_RULES セクションが存在する"
  - "play/template/plan.json に requires_functional_test: true が追加されている"
  - "tests/framework-tests/ に 3 つのテストスクリプトが存在し動作する"
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 23:49:08
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
