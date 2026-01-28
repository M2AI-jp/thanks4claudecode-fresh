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
active: play/standalone/repository-verification/plan.json
parent_project: null
current_phase: p1_definition
branch: feat/repository-verification
last_archived: play/archive/standalone/architecture-sync
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1_definition
done_criteria:
  - docs/completion-criteria.md にリポジトリ完成状態の定義が存在する
  - 全7つの reward-guard スクリプトが exit 2 でブロック動作することが確認されている
  - Hook -> Event Unit -> Skill チェーンが全て動作することが確認されている
  - 孤立ファイルが0件または正当な理由が文書化されている
status: in_progress
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
