# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-repository-audit.md
branch: feat/repository-audit
last_archived: plan/archive/playbook-docs-audit-update.md
review_pending: false
```

---

## goal

```yaml
milestone: repository-audit
phase: p_final
done_criteria:
  - phase-status-guard.sh が存在し、Phase status 変更時に全 subtask 完了を検証する
  - subtask-guard.sh が critic 呼び出しを構造的に強制する
  - archive-playbook.sh が全 subtask `[x]` を検証し、`[ ]` が残っていればアーカイブを拒否する
  - RUNBOOK.md に TodoWrite と playbook の関係ルールが記載されている
  - prompt.sh でユーザープロンプト時に subtask 状況リマインダーが表示される
  - pre-tool.sh から phase-status-guard.sh が呼び出される
status: active
note: 報酬詐欺防止の構造的強制を実装
```

---

## session

```yaml
last_start: 2026-01-02 21:06:40
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
