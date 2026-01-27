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
active: play/standalone/deadlock-prevention/plan.json
parent_project: null
current_phase: p_final
branch: feat/deadlock-prevention
last_archived: play/archive/mece-completion-v2
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - contract.sh に git recovery コマンドが含まれる
  - pending-guard.sh の許可リストに play/ が含まれる
  - session-start で stale pending ファイルの検出処理が存在する
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 00:25:00
last_end: 2026-01-27 23:40:48
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
