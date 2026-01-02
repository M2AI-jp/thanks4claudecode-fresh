# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-harness-self-awareness-v3.md
branch: feat/harness-self-awareness
last_archived: plan/archive/playbook-harness-self-awareness.md
review_pending: false
```

---

## goal

```yaml
milestone: harness-self-awareness-v3
phase: p1
done_criteria:
  - session-start.sh が coherence-checker を呼び出し、問題があれば詳細（ファイル一覧含む）を表示する
  - severity: low の auto_fix を適用するスクリプト（apply-fixes.sh）が存在する
  - docs/harness-self-awareness-design.md が v3 の内容で更新されている
status: in_progress
note: v3 - SessionStart 連携と auto_fix 適用機能
```

---

## session

```yaml
last_start: 2026-01-03 00:16:56
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
