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
active: plan/playbook-test-strengthening.md
branch: feat/test-strengthening
last_archived: plan/archive/playbook-workflow-e2e-tests.md
```

---

## goal

```yaml
milestone: M082
phase: p1
done_criteria:
  - 既存テストのフォールバック else パターンが全て明示的な fail に置き換えられている
  - exit code を条件としない「処理された」パターンが削除されている
  - 各テストが明確な期待値を持ち、それ以外は FAIL する
  - bash scripts/test-workflows.sh が全テスト PASS で終了する
```

---

## session

```yaml
last_start: 2025-12-23 01:00:41
last_end: 2025-12-22 22:35:47
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
