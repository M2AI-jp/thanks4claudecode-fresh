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
active: plan/playbook-golden-path-chain-docs.md
branch: fix/golden-path-chain-docs
last_archived: plan/archive/playbook-understanding-check-enforcement.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - CLAUDE.md Section 11 に "Skill(playbook-init)" の記述がある
  - golden-path/SKILL.md に "Task(subagent_type='pm'" の直接呼び出し記述がない
  - 4qv-architecture.md の "Task(subagent_type='pm') は動作しない" という誤記述が修正されている
  - governance/PROMPT_CHANGELOG.md に [1.2.0] エントリが存在する
note: Golden Path ドキュメント修正 - Hook→Skill→SubAgent チェーン強制
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
