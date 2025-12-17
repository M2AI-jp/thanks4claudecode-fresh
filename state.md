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
active: null
branch: feat/m076-orchestration-e2e-test
last_archived: M076 playbook-m076-orchestration-e2e-test.md (2025-12-18)
```

---

## goal

```yaml
milestone: M076
phase: p0
done_criteria:
  - state.md の toolstack を B に変更した場合、role-resolver.sh が worker -> codex を返す
  - state.md の toolstack を C に変更した場合、role-resolver.sh が reviewer -> coderabbit を返す
  - pm SubAgent が生成する playbook に executor: worker 形式が含まれている
  - テスト完了後、state.md が toolstack: A に復元されている
```

---

## session

```yaml
last_start: 2025-12-18 00:00:18
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
