# project.md

> **プロジェクトの根幹計画。setup 完了相当の状態から生成。**
> **playbook はこのファイルを参照して作成する。**

---

## meta

```yaml
project: thanks4claudecode
created: 2025-12-10
type: automation
location: /Users/amano/Desktop/thanks4claudecode/
```

---

## vision

### ユーザーの意図

> Claude Code の自律性と信頼性を最大化し、ユーザーの手作業に依存しないシステムを構築する。
>
> Claude が無意識に課されているシステムプロンプトや使える機能が、本当にカタログスペック通りに稼働するかを検証し、
> この検証・改善プロセスをユーザーの手から離して自律的に行えるようにする。

### 成功の定義

- ユーザープロンプトなしで 1 playbook を完遂できる
- compact 後も mission（目的）を見失わない
- 次タスクを自動導出して開始できる
- 全 Hook/SubAgent/Skill が動作確認済み
- ドキュメントが自動的に最新に保たれる
- 失敗パターンから学習し、同じミスを繰り返さない

---

## tech_decisions

> **このワークスペースの技術選択**

### 言語

```yaml
language: Bash/Shell
reason: |
  Claude Code の Hook システムは shell スクリプトで実装。
  exit code による制御（0=通過、2=ブロック）が必要なため。
```

### フレームワーク

```yaml
frontend: none
backend: none
automation: Claude Code Hooks
reason: |
  プロダクトは Claude Code ワークスペース自体。
  Hooks + SubAgents + CLAUDE.md の三位一体アーキテクチャで構成。
```

### ライブラリ

```yaml
ui: none
state_management: state.md（YAML ベースの状態管理）
data_fetching: none
form: none
validation: critic SubAgent（done_criteria 検証）
auth: none
database: none
ai: Claude Code（Claude Opus 4.5）
```

### デプロイ

```yaml
platform: local
reason: |
  このワークスペースはローカルで動作。
  git によるバージョン管理、ブランチによる playbook 分離。
```

---

## non_functional_requirements

> **このワークスペースの非機能要件**

### 規模

```yaml
users: 1  # 開発者本人
data_volume: small  # ログ、設定ファイル
```

### パフォーマンス

```yaml
response_time: normal < 3s  # Hook 実行時間
concurrent_users: 1
```

### セキュリティ

```yaml
requires_auth: false
handles_pii: false
handles_payment: false
protected_files: .claude/protected-files.txt で管理
```

### 可用性

```yaml
downtime_tolerance: high  # 個人利用のため
requires_backup: true  # git で管理
```

### 予算

```yaml
monthly_budget: $0  # ローカル実行のみ
initial_investment: none
```

### 期間

```yaml
target_release: flexible
mvp_deadline: flexible
```

### 費用概算

```yaml
estimated_cost:
  monthly_total: $0
  breakdown:
    hosting: $0
    database: $0
    auth: $0
    ai_api: $0  # Claude Code は別途契約
    payment: 0%
    other: $0
  notes: |
    - ローカル実行のため追加費用なし
    - Claude Code API 利用料は別途
```

---

## stack

> **tech_decisions から導出された最終スタック構成**

```yaml
framework: Claude Code Hooks System
language: Bash/Shell
deploy: local (git-based)
database: none (file-based: state.md, playbook)
external_apis: none
```

---

## constraints

- Hook は exit code で制御（0=通過、2=ブロック）
- state.md が Single Source of Truth
- playbook なしで Edit/Write は禁止（アクションベース Guards）
- critic なしで Phase 完了は禁止（報酬詐欺防止）
- main ブランチでの直接作業は禁止

---

## skills

```yaml
# プロジェクトで使用する Claude Skills

lint-checker:
  role: コード品質チェック（ESLint, ShellCheck）
  location: .claude/skills/lint-checker/skill.md

test-runner:
  role: テスト実行・検証
  location: .claude/skills/test-runner/skill.md

deploy-checker:
  role: デプロイ準備・検証
  location: .claude/skills/deploy-checker/skill.md

consent-process:
  role: 合意プロセス（[理解確認]）
  location: .claude/skills/consent-process/skill.md

context-externalization:
  role: コンテキスト外部化
  location: .claude/skills/context-externalization/skill.md

plan-management:
  role: 計画管理
  location: .claude/skills/plan-management/skill.md

learning:
  role: 失敗パターン学習
  location: .claude/skills/learning/skill.md
```

---

## 開発の必須事項

> LLM が確実に Skills を発火させるための記載

- Shell スクリプトを作成・編集した後は、`lint-checker` スキルで ShellCheck を実行すること
- Hook を作成・編集した後は、`test-hooks.sh` でテストすること
- playbook 完了時は、`critic` SubAgent で done_criteria を検証すること
- git push 前は、`deploy-checker` スキルを実行すること

---

## milestones

- [x] 三位一体アーキテクチャ確立（Hooks + SubAgents + CLAUDE.md）
- [x] Self-Healing System 基盤実装
- [x] 全 Hook/SubAgent/Skill の動作検証
- [x] mission 整合性チェック機能
- [ ] PR 作成・マージの自動化
- [ ] 外部リポジトリへの適用検証

---

## notes

### アーキテクチャ

```
三位一体アーキテクチャ:
  Hooks: 構造的強制（exit 2 でブロック、systemMessage で誘導）
  SubAgents: 検証（critic/pm/reviewer/health-checker）
  CLAUDE.md: 思考制御（mission 参照、報酬詐欺防止）
```

### Self-Healing System

```
4つの柱:
  Context_Continuity: compact 後も状態を復元
  Document_Freshness: 陳腐化を検知して自動更新
  Feature_Verification: Hook/SubAgent の動作を自動検証
  Self_Improvement: 失敗から学習して再発防止
```

### 設計ドキュメント参照

- plan/design/mission.md: 最上位概念（vision の詳細）
- plan/design/self-healing-system.md: Self-Healing System 設計
- plan/design/plan-chain-system.md: 計画連鎖システム設計

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | plan/template/project-format.md に従って再構成。リポジトリの実態から導出。 |
