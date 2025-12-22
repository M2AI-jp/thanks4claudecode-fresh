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
active: plan/playbook-fix-workflow-inconsistencies.md
branch: chore/fix-workflow-inconsistencies
last_archived: plan/archive/playbook-m082-repository-optimization.md
```

---

## goal

```yaml
milestone: null  # 既存マイルストーンに紐づかない点検作業
phase: p1
done_criteria:
  - session-end.sh が state.md の現在の構造（playbook.active）を正しく参照している
  - consent-guard.sh への参照がドキュメントから削除されている
  - repository-map.yaml の mandatory_outputs から [理解確認] が削除されている
```

---

## session

```yaml
last_start: 2025-12-22 20:46:08
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
toolstack: A  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: claudecode        # 実装担当（A: claudecode, B/C: codex）
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
