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
phase: p2
name: playbook-pr-automation / PR 作成スクリプト実装
task: create-pr.sh スクリプトの実装
assignee: claudecode

done_criteria:
  - create-pr.sh が .claude/hooks/ に存在する
  - スクリプトが gh CLI で PR を作成する処理を含む
  - PR の説明文に done_criteria を含める仕様が実装されている
  - PR タイトルに playbook 名と phase 名を含める仕様が実装されている
  - エラーハンドリング（PR 既存の場合の対応）が実装されている
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
last_start: 2025-12-10 04:00:44
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
