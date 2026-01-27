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
active: play/standalone/v2-design-enhancement/plan.json
parent_project: null
current_phase: p1
branch: feat/new-repo-docs-sync
last_archived: play/archive/projects/new-repo-docs-sync/pb-001
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - Phase -1 概念整理が IMPLEMENTATION-PLAN-V2.md に存在
  - Layer 0-5 機能依存レイヤーが IMPLEMENTATION-PLAN-V2.md に存在
  - Evidence 3点検証が REVIEW-PROTOCOL.md に存在
  - 時間的達成可能性が REVIEW-PROTOCOL.md に存在
  - 不足用語が GLOSSARY.md に追加済み
  - 旧ドキュメントが archive に移動済み
  - 参照整合性が確認済み
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-27 21:53:39
last_end: 2026-01-21 22:51:23
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
