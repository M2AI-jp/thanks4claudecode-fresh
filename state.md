# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode
```

---

## playbook

```yaml
active: plan/playbook-e2e-verification-timestamp.md
branch: test/e2e-verification
last_archived: plan/archive/playbook-understanding-check-enforcement.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p_final
done_criteria:
  - docs/BASELINE.md の検証済み状態セクション（セクション5）に E2E 検証完了タイムスタンプが追加されている
  - タイムスタンプは ISO 8601 形式（YYYY-MM-DD）である
note: p1完了、critic検証実行中
```

---

## session

```yaml
last_start: 2025-12-25 00:47:28
last_end: 2025-12-24 03:27:11
last_clear: 2025-12-24 03:20:00
```

---

## config

```yaml
security: admin
toolstack: B  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: claudecode      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
