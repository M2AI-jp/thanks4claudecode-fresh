# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: null
current_milestone: null
status: idle
```

---

## playbook

```yaml
active: play/standalone/fix-archive-project-merge/plan.json
parent_project: null
current_phase: p1
branch: fix/archive-project-merge
last_archived: play/archive/projects/toolstack-c-enforcement/m1-analysis
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - archive-project.sh の 117-119行目が rm -rf ではなくマージロジックに変更されている
  - 既存アーカイブディレクトリが存在する場合、その中の playbooks/ 配下のファイルが保持される
  - project.json は新規で上書きされる
status: in_progress

```

---

## session

```yaml
last_start: 2026-01-20 04:12:43
last_end: 2026-01-20 03:49:19
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
