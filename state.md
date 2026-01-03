# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-password-generator-cli.md
branch: feat/password-generator-cli
last_archived: plan/archive/playbook-pb28-archive-fix-backlog-auto-mark.md
review_pending: false
```

---

## goal

```yaml
milestone: Password Generator CLI
phase: p_final
done_criteria:
  - R1: tmp/password-generator/ ディレクトリが存在する ✓
  - R2: npm run gen が 16 文字のパスワードを出力する ✓
  - R3: npm run gen -- --length 8 が 8 文字のパスワードを出力する ✓
  - R4: npm run gen -- --no-symbols が記号なしパスワードを出力する ✓
  - R5: npm run gen -- --no-numbers が数字なしパスワードを出力する ✓
  - R6: エントロピー（ビット数）が正しく計算・表示される ✓
self_complete: false
status: completed
```

---

## session

```yaml
last_start: 2026-01-03 20:44:51
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
