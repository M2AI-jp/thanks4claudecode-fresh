# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/context-cleanup/project.json
current_milestone: m2
status: active
```

---

## playbook

```yaml
active: play/projects/context-cleanup/playbooks/m2-file-inventory/plan.json
parent_project: context-cleanup
current_phase: p1
branch: project/context-cleanup
last_archived: play/archive/projects/context-cleanup/m1-protected-files
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: m2
phase: p1
done_criteria:
  - tmp/file-inventory-report.md が存在する
  - レポートに全ファイルのカテゴリ別一覧が含まれている
  - レポートに削除候補セクションと各ファイルの削除理由が記載されている
status: active

```

---

## session

```yaml
last_start: 2026-01-08 01:57:35
last_end: 2026-01-08 01:57:34
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
