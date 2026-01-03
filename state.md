# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-fix-backlog-batch-19.md
branch: fix/backlog-batch-19-pbs
last_archived: plan/archive/playbook-pb28-archive-fix-backlog-auto-mark.md
review_pending: false
```

---

## goal

```yaml
milestone: fix-backlog-batch-19
phase: p1
done_criteria:
  - fix-backlog.md の PB-02〜06, PB-11〜25 が全て FIXED または CLOSED
  - 各修正に対して bash -n または grep による検証が PASS
  - 関連ドキュメントの参照が実際に存在するファイルを指している
self_complete: false
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-04 03:17:24
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
