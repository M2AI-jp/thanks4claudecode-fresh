# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: null
branch: null
last_archived: plan/archive/playbook-reward-fraud-verification.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - deflection-guard.sh が存在し、「技術的にできない」パターンを WARN + 代替案提示する
  - responsibility-shift-guard.sh が存在し、「ユーザーが判断」パターンを BLOCK する
  - state.md に correction_log セクションが追加され、ユーザー修正を蓄積する仕組みがある
  - critic.md の Plus_批判的思考に「思考プロセス自己診断」4項目が追加されている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-03 01:24:49
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
