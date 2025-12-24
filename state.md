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
active: plan/playbook-mandatory-understanding-check.md
branch: feat/mandatory-understanding-check
last_archived: plan/archive/playbook-orphan-file-analysis.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - prompt.sh が理解確認の強制メッセージを注入している
  - pm.md が理解確認なしに playbook 作成を進めない構造的ルールを持つ
  - understanding-check Skill のスキップ条件が「ユーザー明示要求のみ」に更新されている
note: 全ユーザープロンプトに対して理解確認（5W1H分析）を必須化
```

---

## session

```yaml
last_start: 2025-12-24 06:24:22
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
