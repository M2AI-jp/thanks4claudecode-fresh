# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/repository-complete-verification/project.json
current_milestone: m2
status: in_progress
```

---

## playbook

```yaml
active: play/projects/repository-complete-verification/playbooks/pb-m2-guards/plan.json
parent_project: repository-complete-verification
current_phase: p1
branch: feat/m2-guard-verification
last_archived: play/archive/projects/repository-complete-verification/pb-m1-event-units
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: m2
phase: p1
done_criteria:
  - "15 Guard スクリプトが存在し実行可能である"
  - "各 Guard が BLOCK/ALLOW 動作を記録している"
  - "Adversarial bypass 試行が全て失敗している"
  - "Hook chain 統合テストで Guards が正しく発火する"
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
