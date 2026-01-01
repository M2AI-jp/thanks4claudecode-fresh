# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-tmp-demo-gitignore.md
branch: feat/multi-language-orchestration-demo
last_archived: plan/archive/playbook-fix-empty-input-test.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: null
done_criteria:
  - playbook の全 phase/subtask が done になっている
  - qa.sh の skip を FAIL 扱いに変更し、証跡ログ保存
  - evidence の行数修正 + subagent.log 引用追加
  - bats にエラーケース追加
  - ts-node が devDependencies に追加され、README に前提条件追記
  - timestamp 整合性修正
status: completed
note: |
  orchestration-completeness-100 の残課題6件を修正完了
  commit: 9ff7d2e
  prior_work:
    - playbook: plan/archive/playbook-orchestration-completeness-100.md
    - codex_agentId: a06e567 (transform.ts)
```

---

## session

```yaml
last_start: 2026-01-02 06:57:20
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
