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
phase: p_final
done_criteria:
  # p0: プロンプト解釈基盤
  - prompt-analyzer SubAgent が存在し、5W1H 分析 + リスク分析を実行する
  - term-translator SubAgent が存在し、エンジニア用語への変換を実行する
  - executor-resolver SubAgent が存在し、LLM ベースで executor を判定する
  - pm SubAgent が orchestrator として上記 SubAgent を呼び出す
  # p1-p4: 自動リトライ機構
  - critic-guard.sh が FAIL 時に .claude/session-state/last-fail-reason にエラー内容を保存する
  - executor-guard.sh が保存されたエラーを読み込み、codex プロンプトに注入する仕組みが存在する
  - iteration_count が .claude/session-state/iteration-count に記録される
  - max_iterations 到達時に AskUserQuestion が呼ばれる仕組みが存在する
  - playbook-format.md に max_iterations の自動リトライ動作が明記されている
  - ARCHITECTURE.md に自動リトライフローが追記されている
note: プロンプト解釈基盤を構築し、critic FAIL 時に自動リトライする機構を実装する
```

---

## session

```yaml
last_start: 2026-01-01 18:54:16
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
