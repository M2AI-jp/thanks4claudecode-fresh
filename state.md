# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-docs-audit-update.md
branch: feat/docs-audit-update
last_archived: plan/archive/playbook-codex-audit-fix.md
review_pending: false
```

---

## goal

```yaml
milestone: docs-audit-update
phase: p1
done_criteria:
  - ARCHITECTURE.md の全参照が有効である
  - repository-map.yaml が現状と整合している
  - 不要ファイルが削除されている
status: in_progress
note: 一次情報リソースの監査・改善
```

---

## session

```yaml
last_start: 2026-01-02 17:55:35
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
