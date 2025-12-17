# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode  # 現在作業中のプロジェクト名
project: plan/project.md
```

---

## playbook

```yaml
active: plan/playbook-m078-codex-mcp.md
branch: research/codex-mcp
last_archived: M076 playbook-m076-orchestration-e2e-test.md (2025-12-18)
```

---

## goal

```yaml
milestone: M078
phase: p1
done_criteria:
  - .claude/mcp.json が存在し、codex mcp-server が登録されている
  - codex-delegate.md が MCP ツール mcp__codex__codex を使用する形式に更新されている
  - docs/ai-orchestration.md に Codex MCP の説明が追加されている
  - toolstack C で簡単なコーディングタスクを Codex MCP 経由で実行し、正常に動作することが確認されている
  - テスト完了後、toolstack: A に復元されている
```

---

## session

```yaml
last_start: 2025-12-18 00:49:26
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
