# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-prompt-analyzer-lite.md
branch: refactor/prompt-analyzer-lite
last_archived: plan/archive/playbook-repository-health-master-plan.md
review_pending: false
```

---

## goal

```yaml
milestone: prompt-analyzer-lite
phase: p1
done_criteria:
  - prompt-analyzer.md が 200 行以下である
  - SKILL.md が 100 行以下である
  - 5W1H 分析機能が保持されている
  - リスク分析機能（technical/scope/dependency）が保持されている
  - 曖昧さ検出機能が保持されている
  - 論点分解機能（multi_topic_detection）が保持されている
  - 拡張分析項目が保持されている
  - 出力フォーマット（YAML 形式）が保持されている
self_complete: false
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-04 17:39:57
last_end: 2026-01-01 21:10:00
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
| docs/folder-management.md | フォルダ管理ルール |
