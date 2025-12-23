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
active: plan/playbook-4qv-e2e-verification-v4.md
branch: refactor/4qv-architecture-rebuild
last_archived: plan/archive/playbook-4qv-e2e-verification-v3.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p0
done_criteria:
  - Golden Path E2E: 自然言語タスク依頼 → Skill(playbook-init) → playbook 作成が動作
  - Playbook Gate E2E: playbook=null で Edit がブロック → Skill 呼び出し誘導が動作
  - Reward Guard E2E: done_when 未達成で完了ブロック → Skill(crit) 呼び出し誘導が動作
  - Access Control E2E: HARD_BLOCK ファイル保護が動作
  - 全テスト ALL GREEN
note: 4QV+ E2E 動作検証 - Iteration 4
```

---

## session

```yaml
last_start: 2025-12-24 06:07:24
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
