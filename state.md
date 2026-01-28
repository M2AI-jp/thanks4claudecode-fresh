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
active: play/standalone/project-feature-validation/plan.json
parent_project: null
current_phase: p1
branch: feat/project-feature-validation
last_archived: play/archive/repository-completion
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - project 機能の「完成」定義が docs/design/project-feature-spec.md に記載されている
  - 仕様検証レポートが tmp/project-spec-validation.md に存在する
  - 最終判定（修正実施 or 廃止）が docs/design/project-feature-spec.md の verdict セクションに記載されている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 12:37:31
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
