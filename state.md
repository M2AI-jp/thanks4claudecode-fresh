# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: product
```

---

## active_playbooks

```yaml
product: plan/active/playbook-pr-automation.md
setup: null
workspace: null
```

---

## playbook

```yaml
active: plan/active/playbook-pr-automation.md
branch: feat/pr-automation
```

---

## goal

```yaml
phase: p4
name: playbook-pr-automation / マージ自動化スクリプト強化
task: merge-pr.sh 作成と PR マージ処理の実装
assignee: claudecode

done_criteria:
  - merge-pr.sh が .claude/hooks/ に存在する
  - PR のステータスを確認する処理を含む（draft → ready）
  - gh pr merge コマンドで自動マージを実行する処理を含む
  - マージコンフリクト検出とエラー通知を含む
  - マージコミットメッセージが CLAUDE.md に従っている
  - ShellCheck でエラーなしに通る
  - 実際に動作確認済み（test_method 実行）
```

---

## verification

```yaml
self_complete: true
user_verified: false
```

---

## session

```yaml
last_start: 2025-12-10 04:26:57
last_end: 2025-12-09 21:22:42
```

---

## config

```yaml
security: admin          # strict | trusted | developer | admin
learning:
  operator: hybrid       # human | hybrid | llm
  expertise: intermediate  # beginner | intermediate | expert
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | Macro 計画 |
| docs/current-implementation.md | 実装仕様書 |
| .claude/context/history.md | 詳細履歴 |
