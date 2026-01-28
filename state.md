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
active: play/standalone/completion-verification/plan.json
parent_project: null
current_phase: p1
branch: feat/completion-check-script
last_archived: play/archive/repository-verification
review_pending: true
```

---

## goal

```yaml
self_complete: true
milestone: null
phase: p_final
done_criteria:
  - scripts/completion-check.sh が存在し exit 0 で終了
  - 報酬詐欺バイパス試行が全て失敗する
  - docs/reports/completion-verification-final.md が存在する
status: done
```

---

## session

```yaml
last_start: 2026-01-29 01:49:34
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
