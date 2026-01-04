# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-repository-health-master-plan.md
branch: docs/repository-health-master-plan
last_archived: plan/archive/playbook-pb28-archive-fix-backlog-auto-mark.md
review_pending: false
```

---

## goal

```yaml
milestone: repository-health-master-plan
phase: p1
done_criteria:
  - plan/design/repository-health-master-plan.md が作成され、scope/definitions/workflow/evidence を含む
  - docs/repository-health.md に判定基準と抽出結果（必須/壊れている/不要）が記載されている
  - docs/repository-map.yaml と docs/ARCHITECTURE.md が抽出結果に沿って更新されている
self_complete: false
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-04 14:18:20
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
