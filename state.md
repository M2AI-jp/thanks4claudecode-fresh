# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-restore-demo-files.md
branch: fix/restore-demo-files
last_archived: plan/archive/playbook-tmp-demo-gitignore.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - tmp/README.md に前提条件が追記されている（jq, ts-node, bats, shellcheck, ruff, eslint）
  - evidence/ に証跡補足ログが存在する（8→11 tests の経緯を説明）
  - scripts/qa.sh が PASS する
  - 新しい QA 証跡が evidence/ に記録されている
status: in_progress
note: |
  デモファイル復元と証跡整合性修正
  背景: tmp/ ファイル消失 → git checkout で復元済み → 証跡整合性修正
```

---

## session

```yaml
last_start: 2026-01-02 08:36:39
last_end: 2026-01-01 21:10:00
last_clear: 2025-12-24 03:20:00
```

---

## config

```yaml
security: admin
toolstack: C  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: coderabbit      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
