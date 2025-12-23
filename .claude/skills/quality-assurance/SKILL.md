# quality-assurance Skill

> **品質保証**
>
> レビュー・チェック・監視のワークフロー

---

## 責務

このSkillは以下を担当:
1. コード品質チェック（lint）
2. 参照整合性の検証（integrity）
3. システムヘルスの監視
4. コードレビュー（reviewer SubAgent）

---

## ディレクトリ構造

```
quality-assurance/
├── SKILL.md              ← このファイル
├── checkers/
│   ├── lint.sh               ← 静的解析チェック
│   ├── integrity.sh          ← 参照整合性チェック
│   └── health.sh             ← システムヘルスチェック
└── agents/
    ├── reviewer.md           ← reviewer SubAgent（コードレビュー）
    └── health-checker.md     ← health-checker SubAgent（システム監視）
```

---

## 発火条件

- git commit 前（PreToolUse:Bash）
- ユーザーがレビューを依頼した時
- pre-tool.sh（導火線）から呼び出される

---

## チェッカー一覧

| チェッカー | 役割 | 実行タイミング |
|------------|------|----------------|
| lint.sh | ESLint, TypeScript チェック等 | commit 前 |
| integrity.sh | 参照整合性（デッドリンク、未使用ファイル） | 定期実行 |
| health.sh | システム状態（git status, state.md 整合性） | セッション開始時 |

---

## SubAgent 一覧

### reviewer SubAgent

```yaml
role: コードレビュー、playbook レビュー
location: .claude/skills/quality-assurance/agents/reviewer.md
invocation: Task(subagent_type='reviewer', prompt='PR #123 をレビュー')
output:
  - judgment: PASS/FAIL
  - comments: レビューコメント
  - suggestions: 改善提案
```

### health-checker SubAgent

```yaml
role: システム状態の監視
location: .claude/skills/quality-assurance/agents/health-checker.md
invocation: Task(subagent_type='health-checker', prompt='システム状態を確認')
output:
  - status: healthy/warning/critical
  - issues: 検出された問題
  - recommendations: 推奨アクション
```

---

## チェック項目

### lint.sh

```yaml
checks:
  - eslint（.ts, .tsx, .js, .jsx）
  - typescript（型チェック）
  - bash -n（シェルスクリプト構文）

on_failure:
  action: BLOCK
  message: "Lint エラーを修正してください"
```

### integrity.sh

```yaml
checks:
  - デッドリンク（.md 内の参照）
  - 未使用ファイル
  - 循環参照
  - state.md と playbook の整合性

on_failure:
  action: WARN
  message: "整合性問題が検出されました"
```

### health.sh

```yaml
checks:
  - git status（未コミット変更）
  - state.md の存在と形式
  - playbook の存在と形式
  - 必須ファイルの存在

on_failure:
  action: WARN
  message: "システム状態に問題があります"
```

---

## 使用方法

### Lint チェック
```bash
bash .claude/skills/quality-assurance/checkers/lint.sh
```

### 整合性チェック
```bash
bash .claude/skills/quality-assurance/checkers/integrity.sh
```

### レビュー依頼
```
Task(subagent_type='reviewer', prompt='このPRをレビュー')
```

---

## 関連

| ファイル | 役割 |
|----------|------|
| scripts/e2e-contract-test.sh | E2E テスト |
| .claude/hooks/check-integrity.sh | 元の整合性チェック |
