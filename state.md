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
active: play/standalone/project-lifecycle/plan.json
parent_project: null
current_phase: p1
branch: feat/project-lifecycle
last_archived: play/archive/standalone/fix-archive-resume
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - docs/project-lifecycle.md が存在し、archive-project.sh の仕様・テンプレート構成・生成ロジックが明文化されている
  - docs/ の既存ドキュメントと設計書の乖離が解消されている
  - archive-project.sh が play/projects/<id>/ を play/archive/projects/<id>/ へ移動する
  - archive-project.sh が state.md の project.active を null に更新する
  - archive-playbook.sh の最後で project 完了チェック + archive-project.sh 呼び出しが実装されている
  - design-validation project が play/archive/projects/ に移動されている
status: active

```

---

## session

```yaml
last_start: 2026-01-08 01:12:03
last_end: 2026-01-08 00:42:31
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
