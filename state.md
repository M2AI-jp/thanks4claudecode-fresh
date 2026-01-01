# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-auto-retry.md
branch: feat/auto-retry
last_archived: plan/archive/playbook-architecture-visualizer.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - critic-guard.sh が FAIL 時に .claude/session-state/last-fail-reason にエラー内容を保存する
  - executor-guard.sh が保存されたエラーを読み込み、codex プロンプトに注入する仕組みが存在する
  - iteration_count が .claude/session-state/iteration-count に記録される
  - max_iterations 到達時に AskUserQuestion が呼ばれる仕組みが存在する
  - playbook-format.md に max_iterations の自動リトライ動作が明記されている
  - ARCHITECTURE.md に自動リトライフローが追記されている
note: critic FAIL 時に自動リトライする機構を実装する（max_iterations まで）
```

---

## session

```yaml
last_start: 2026-01-01 18:09:39
last_end: 2025-12-24 03:27:11
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
