# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-handoff-ssot.md
branch: docs/ssot-handoff
last_archived: null
review_pending: false
```

---

## goal

```yaml
milestone: ssot-handoff
phase: p1
done_criteria:
  - docs/core-feature-reclassification.md と docs/ARCHITECTURE.md が最新の Hook timing×ファイルマッピングを反映している
  - 欠落コンポーネントの確定リストが SSOT に固定されている
  - Unit 単位のドッグフーディング記録（ログ/状態/コマンド出力）が残っている
  - 漸進統合の配線結果が SSOT と docs/repository-map.yaml に反映されている
  - Decision Log と DRIFT対応の記録が更新されている
self_complete: false
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-05 02:36:20
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
| docs/core-feature-reclassification.md | Hook Unit SSOT |
