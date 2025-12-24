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
active: plan/playbook-feature-verification.md
branch: feat/feature-verification
last_archived: plan/archive/playbook-context-continuity.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - SessionStart で settings.json に登録された全 Hook の存在・実行権限を自動検証する
  - 問題検出時に警告メッセージが表示される
  - 自動修復可能な問題（chmod +x）は自動修復される
note: Self-Healing Layer 3 - Hook 故障の自動検知と修復
```

---

## session

```yaml
last_start: 2025-12-24 16:34:45
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
