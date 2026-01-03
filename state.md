# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-skill-audit-v2.md
branch: refactor/skill-audit-v2
last_archived: plan/archive/playbook-skill-audit.md
review_pending: true
```

---

## goal

```yaml
milestone: "外部検証・反証モードによる機能監査"
phase: "p1 (pending) - 機械的データ収集"
done_criteria:
  - "依存グラフが生成され、断絶がリストされている"
  - "各ファイルに外部検証結果（codex）が付与されている"
  - "反証モードで問題点がリストされている"
  - "未確定項目が明示的にリストされている"
status: pending_approval
```

---

## session

```yaml
last_start: 2026-01-03 13:00:32
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
