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
active: plan/playbook-m085-orchestration-automation.md
branch: feat/orchestration-automation
last_archived: plan/archive/playbook-m084-hook-stdin-fix.md
review_pending: true  # レビュー未完了なら true（stop.py がブロック）
```

---

## goal

```yaml
milestone: M085
phase: p2
done_criteria:
  - pm.md にタスク分類パターンが構造的強制として定義されている
  - executor-guard.sh が SubAgent 呼び出しを案内している
  - docs/ai-orchestration.md にオーケストレーション自動化説明が追加されている
```

---

## session

```yaml
last_start: 2025-12-23 16:20:03
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
