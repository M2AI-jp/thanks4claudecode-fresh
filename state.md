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
active: plan/playbook-m092-skill-packaging.md
branch: feat/skill-packaging
last_archived: plan/archive/playbook-m091-post-loop-order-fix.md
review_pending: false
```

---

## goal

```yaml
milestone: M092
phase: p_final
done_criteria:
  - playbook-review/ Skill ディレクトリが存在し、reviewer.md と playbook-review-criteria.md を含む ✓
  - subtask-review/ Skill ディレクトリが存在し、subtask-validator.sh を含む ✓
  - phase-critique/ Skill ディレクトリが存在し、critic.md と done-criteria-validation.md を含む ✓
  - completion-review/ Skill ディレクトリが存在し、archive-validator.sh を含む ✓
  - understanding-check/hooks/ が追加され、understanding-enforcer.sh を含む ✓
  - state/hooks/ が追加され、orphan-detector.sh と coherence-checker.sh を含む ✓
  - .claude/settings.json が新しいパスを参照している ✓
  - reviewed: false の playbook で Edit を実行すると exit 2 でブロックされる ✓
  - 孤立 playbook がアーカイブされている ✓
note: M092 全検証 PASS。コミット待ち。
```

---

## session

```yaml
last_start: 2025-12-23 21:33:12
last_end: 2025-12-23 21:33:11
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
