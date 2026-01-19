# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/framework-quality/project.json
current_milestone: m1
status: in_progress
```

---

## playbook

```yaml
active: play/projects/framework-quality/playbooks/pm-temporal-guidance/plan.json
parent_project: framework-quality
current_phase: p_final
branch: feat/pm-temporal-guidance
last_archived: play/archive/temporal-achievability
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: m1
phase: p_final
done_criteria:
  - pm.md の Step 3.5 に temporal achievability チェックリストが追加されている
  - fail_examples と pass_examples が pm.md に含まれている
  - docs/design/temporal-achievability-spec.md への参照が含まれている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-20 06:32:39
last_end: 2026-01-20 05:45:48
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
