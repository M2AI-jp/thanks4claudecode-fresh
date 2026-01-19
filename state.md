# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/validation-enforcement-system/project.json
current_milestone: m2_command_execution
status: in_progress
```

---

## playbook

```yaml
active: null
parent_project: validation-enforcement-system
current_phase: null
branch: null
last_archived: play/projects/validation-enforcement-system/playbooks/pb-m1-schema
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: m2_command_execution
phase: null
done_criteria:
  - "scripts/validate-commands.sh が存在し、実行可能である"
  - "playbook 内の全 command が構文エラーなしでパース可能"
status: pending
```

---

## session

```yaml
last_start: 2026-01-20 07:23:44
last_end: 2026-01-20 06:45:28
last_clear: 2025-12-24 03:20:00
```

---

## config

```yaml
security: admin
toolstack: C  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: coderabbit      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/core-feature-reclassification.md | Hook Unit SSOT |
