# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-facade-audit-v2.md
branch: feat/facade-audit-v2
last_archived: plan/playbook-facade-audit.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p_init
done_criteria:
  - playbook テンプレートが「executor 強制」「証拠強制」を構造的に保証している
  - executor-guard が Task/Bash を含む全ツールを監視している
  - Codex MCP が 5 回連続で正常応答する（タイムアウトなし）
  - フォールバック時にユーザー確認プロンプトが発生する
  - p3-p7 の実装が全て Codex によって行われた証拠がある
  - CodeRabbit 最終レビューで critical: 0, major: 0 である
note: executor 強制を構造的に保証し、Codex/CodeRabbit による監査を完遂する
```

---

## session

```yaml
last_start: 2026-01-01 12:40:33
last_end: 2025-12-24 03:27:11
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
