# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: play/loop-enforcement/plan.json
current_phase: p1
branch: feat/loop-enforcement
last_archived: play/archive/hook-fix-v1
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: loop-enforcement
phase: p1
done_criteria:
  - PostToolUse Hook に progress.json 更新リマインダーが追加されている
  - Stop Hook に未完了 subtask の検出ロジックが追加されている
  - テスト（hello-world 同等のタスク）で progress.json 更新が強制される
status: active

```

---

## session

```yaml
last_start: 2026-01-07 03:40:33
last_end: 2026-01-07 03:25:21
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
