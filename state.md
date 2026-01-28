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
active: play/standalone/health-dashboard-cli/plan.json
parent_project: null
current_phase: p4
branch: feat/health-dashboard-cli
last_archived: play/archive/standalone/hook-unit-completion
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - tools/health-dashboard/cli.sh が存在する
  - CLI が全 10 Event Unit の telemetry ログを読み取れる
  - CLI が健全性サマリを標準出力に表示できる
  - CLI が JSON 形式でレポートを出力できる
  - CLI が YAML 形式でレポートを出力できる
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 19:05:43
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
