# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-facade-audit.md
branch: feat/facade-audit
last_archived: plan/archive/playbook-architecture-visualizer.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - 全 20 ガードスクリプトが実際に機能することを E2E テストで確認
  - test-runner が実行可能なテストスイートを持つ
  - critic が「証拠なし PASS」を拒否できる
  - 新規 playbook で実際のテスト駆動開発が機能する
  - CodeRabbit レビューで「見かけ実装」ゼロ判定
note: 「見かけだけの実装」を徹底検証し、実用に耐える品質に引き上げる
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
