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
active: plan/playbook-4qv-architecture-rebuild.md
branch: refactor/4qv-architecture-rebuild
last_archived: null
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p2
done_criteria:
  - playbook-gate 関連 Hook が .claude/skills/playbook-gate/guards/ に移動
  - reward-guard 関連 Hook が .claude/skills/reward-guard/guards/ に移動
  - access-control 関連 Hook が .claude/skills/access-control/guards/ に移動
  - session-manager 関連 Hook が .claude/skills/session-manager/handlers/ に移動
  - quality-assurance 関連 Hook が .claude/skills/quality-assurance/checkers/ に移動
  - 共通ライブラリが .claude/lib/ に統合されている
note: 4QV+ 既存 Hook のロジック移動フェーズ
```

---

## session

```yaml
last_start: 2025-12-24 04:56:05
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
