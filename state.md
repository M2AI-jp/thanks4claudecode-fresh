# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode
project: plan/project.md
```

---

## playbook

```yaml
active: plan/playbook-repository-map-e2e-test.md
branch: feat/repository-map-e2e-test
last_archived: plan/archive/playbook-repository-map-sync.md
```

---

## goal

```yaml
milestone: M082
phase: p1
done_criteria:
  - init_flow の入力→処理→出力が repository-map.yaml の定義通りに動作する
  - work_loop の hooks/subagents/skills 連携が正しく機能する
  - post_loop の playbook 完了後処理が定義通りに実行される
  - critique_process の critic 検証フローが正しく動作する
  - project_complete の milestone 完了後処理が定義通りに動作する
```

---

## session

```yaml
last_start: 2025-12-22 21:39:42
last_end: 2025-12-22 21:29:43
last_clear: 2025-12-13 00:30:00
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
| plan/project.md | プロジェクト計画 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
