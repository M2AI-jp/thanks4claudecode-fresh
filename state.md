# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-harness-self-awareness.md
branch: feat/harness-self-awareness
last_archived: plan/archive/playbook-repository-audit.md
review_pending: false
```

---

## goal

```yaml
milestone: harness-self-awareness-v2
phase: p_final
done_criteria:
  - 不要ファイルが削除されている（context-estimator、旧 session-start.sh）
  - prompt-analyzer に「複数論点・指示の分解」機能が組み込まれている
  - SessionStart 時に全 Hook/Skill/SubAgent の状態が読み込まれる
  - ARCHITECTURE.md と実装の整合性が自動チェックされる
  - 問題検出時に自動修正（軽微）または提案（重大）される
status: in_progress
note: v2 方向転換。v1 成果物を削除して再設計。
```

---

## session

```yaml
last_start: 2026-01-03 00:16:56
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
