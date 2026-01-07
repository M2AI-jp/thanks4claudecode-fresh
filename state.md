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
active: play/refactor-play-structure/plan.json
parent_project: null
current_phase: p1
branch: refactor/play-structure
last_archived: play/archive/standalone/project-lifecycle
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - play/ 直下に単発 playbook が配置される構造になっている
  - play/template/ にテンプレートが統合されている
  - play/archive/ 直下に単発アーカイブが配置される
  - archive-playbook.sh が新構造に対応している
  - docs 3 ファイルが新構造を反映している
status: active

```

---

## session

```yaml
last_start: 2026-01-08 01:38:34
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
