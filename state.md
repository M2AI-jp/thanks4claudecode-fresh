# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-fix-architecture-issues.md
branch: fix/architecture-issues
last_archived: plan/archive/playbook-architecture-visualizer.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - toolstack: B で playbook 作成時、コーディングタスクに executor: worker が割り当てられ、実行時に codex-delegate SubAgent が自動呼び出しされる
  - run_in_background=true で起動したタスクが Phase 完了時・セッション終了時に自動クリーンアップされる
  - 3種類のレビュアー（reviewer, critic, user/coderabbit）全てが4QV+検証を実行する仕組みが存在する
note: アーキテクチャ総合テストで発見した3つの問題を修正
```

---

## session

```yaml
last_start: 2025-12-25 20:27:30
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
